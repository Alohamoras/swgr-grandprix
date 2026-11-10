# Read-only: pull UI textures out of the game's IoStore paks (utoc/ucas) and save them as PNG.
# usage: python3 -I iotex.py OUTDIR pattern [pattern...]   (patterns match the asset path, case-insensitive)
import sys, struct, glob, os, ctypes, re
from PIL import Image

PAKS = os.path.expanduser('~/.steam/steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Content/Paks')
ooz = ctypes.CDLL(os.environ.get('OOZ', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ooz/libooz.so')))

def fstr(b, o):
    n = struct.unpack_from('<i', b, o)[0]; o += 4
    if n < 0: return b[o:o - 2 * n].decode('utf-16-le').rstrip('\0'), o - 2 * n
    return b[o:o + n].decode('latin1').rstrip('\0'), o + n

class Toc:
    def __init__(self, path):
        self.path = path; b = open(path, 'rb').read(); self.b = b
        h = struct.unpack_from('<16sBBHIIIIIIIIIQ16sBBHIQI', b, 0)
        (_, ver, _, _, hsize, n, nblk, blksz, nmeth, methlen, self.bsize, dirsize, parts, _, _, flags, _, _,
         nseeds, self.psize, nnoph) = h
        o = hsize
        self.ids = [b[o + 12 * i:o + 12 * i + 12] for i in range(n)]; o += 12 * n
        self.ol = [b[o + 10 * i:o + 10 * i + 10] for i in range(n)]; o += 10 * n
        o += 4 * nseeds + 4 * nnoph
        self.blocks = []
        for i in range(nblk):
            d = b[o + 12 * i:o + 12 * i + 12]
            off = int.from_bytes(d[0:5], 'little'); cs = int.from_bytes(d[5:8], 'little')
            us = int.from_bytes(d[8:11], 'little'); m = d[11]
            self.blocks.append((off, cs, us, m))
        o += nblk * blksz
        self.meths = [b[o + methlen * i:o + methlen * (i + 1)].rstrip(b'\0').decode() for i in range(nmeth)]; o += nmeth * methlen
        self.dir = (o, dirsize)
        self.ucas = [path[:-5] + '.ucas'] + [path[:-5] + '_s%d.ucas' % i for i in range(1, parts)]
        self.byid = {}
        for i, cid in enumerate(self.ids): self.byid.setdefault(cid[:8], []).append(i)

    def files(self):
        b = self.b; o, size = self.dir
        if size == 0: return {}
        mount, o = fstr(b, o)
        nd = struct.unpack_from('<i', b, o)[0]; o += 4
        dirs = [struct.unpack_from('<IIII', b, o + 16 * i) for i in range(nd)]; o += 16 * nd
        nf = struct.unpack_from('<i', b, o)[0]; o += 4
        fl = [struct.unpack_from('<III', b, o + 12 * i) for i in range(nf)]; o += 12 * nf
        ns = struct.unpack_from('<i', b, o)[0]; o += 4
        strs = []
        for i in range(ns):
            s, o = fstr(b, o); strs.append(s)
        out = {}; NONE = 0xffffffff
        stack = [(0, '')]
        while stack:
            d, p = stack.pop(); name, child, sib, ff = dirs[d]
            p2 = p + (strs[name] + '/' if name != NONE else '')
            f = ff
            while f != NONE:
                fn, nxt, ud = fl[f]; out[mount + p2 + strs[fn]] = ud; f = nxt
            c = child
            while c != NONE: stack.append((c, p2)); c = dirs[c][2]
        return out

    def read(self, idx):
        d = self.ol[idx]
        off = int.from_bytes(d[0:5], 'big'); ln = int.from_bytes(d[5:10], 'big')
        first = off // self.bsize; last = (off + ln - 1) // self.bsize
        out = bytearray()
        for bi in range(first, last + 1):
            boff, cs, us, m = self.blocks[bi]
            part = boff // self.psize if self.psize else 0
            with open(self.ucas[part], 'rb') as f:
                f.seek(boff - part * self.psize if self.psize else boff); raw = f.read(cs)
            if m == 0: out += raw[:us]
            else:
                dst = ctypes.create_string_buffer(us)
                r = ooz.ooz_decompress(raw, cs, dst, us)
                if r != us: raise RuntimeError('oodle failed %d/%d' % (r, us))
                out += dst.raw
        s = off - first * self.bsize
        return bytes(out[s:s + ln])

BCN = {'PF_DXT1': (1, 8), 'PF_DXT3': (2, 16), 'PF_DXT5': (3, 16), 'PF_BC4': (4, 8), 'PF_BC5': (5, 16), 'PF_BC7': (7, 16)}

def mipsize(pf, w, h):
    if pf in BCN: return max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * BCN[pf][1]
    if pf in ('PF_B8G8R8A8', 'PF_R8G8B8A8'): return w * h * 4
    if pf == 'PF_G8': return w * h
    return None

def decode(pf, w, h, data):
    if pf in BCN:
        n = BCN[pf][0]
        bw, bh = max(4, (w + 3) // 4 * 4), max(4, (h + 3) // 4 * 4)
        im = Image.frombytes('RGBA', (bw, bh), data, 'bcn', n)
        return im.crop((0, 0, w, h))
    if pf == 'PF_B8G8R8A8': return Image.frombytes('RGBA', (w, h), data, 'raw', 'BGRA')
    if pf == 'PF_R8G8B8A8': return Image.frombytes('RGBA', (w, h), data)
    if pf == 'PF_G8': return Image.frombytes('L', (w, h), data)
    raise ValueError(pf)

def texture(toc, idx):
    exp = toc.read(idx)
    for m in re.finditer(rb'PF_[A-Za-z0-9_]+\x00', exp):
        p = m.start() - 4
        if p >= 12 and struct.unpack_from('<i', exp, p)[0] == m.end() - m.start():
            break
    else:
        return None, 'no pixel format'
    pf = m.group(0)[:-1].decode()
    sx, sy = struct.unpack_from('<ii', exp, p - 12)
    first, nmips = struct.unpack_from('<ii', exp, m.end())
    sizes = []
    for L in range(nmips):
        n = mipsize(pf, max(1, sx >> L), max(1, sy >> L))
        if n is None: return None, 'format ' + pf
        sizes.append(n)
    total = sum(sizes)
    if total > len(exp) - m.end():
        # only the smaller mips are inline: take the largest one that fits at the end
        for L in range(nmips):
            if sum(sizes[L:]) <= len(exp) - m.end():
                sizes = sizes[L:]; total = sum(sizes); sx, sy = max(1, sx >> L), max(1, sy >> L); break
    best = None
    cands = set(range(m.end(), m.end() + 96, 4)) | {len(exp) - total - k for k in range(0, 96, 4)}
    for st in sorted(cands):
        if st < m.end() or st + sizes[0] > len(exp): continue
        try: im = decode(pf, sx, sy, exp[st:st + sizes[0]])
        except Exception: continue
        sm = im.convert('RGB').resize((256, 256))
        px = sm.tobytes(); sc = 0
        for y in range(0, 256, 8):
            row = px[y * 768:(y + 1) * 768]
            sc += sum(abs(row[i] - row[i + 3]) for i in range(0, 765, 3))
        if best is None or sc < best[0]: best = (sc, st, im)
    if best is None: return None, 'no fit'
    return best[2], '%s %dx%d mips %d start+%d' % (pf, sx, sy, nmips, best[1] - m.end())

tocs = [Toc(p) for p in sorted(glob.glob(PAKS + '/pakchunk*.utoc'))]

if __name__ == '__main__':
    outdir = sys.argv[1]; pats = [p.lower() for p in sys.argv[2:]]
    os.makedirs(outdir, exist_ok=True)
    for t in tocs:
        for path, idx in t.files().items():
            if not path.endswith('.uasset'): continue
            if not any(p in path.lower() for p in pats): continue
            name = path.rsplit('/', 1)[1][:-7]
            try:
                im, info = texture(t, idx)
            except Exception as e:
                im, info = None, 'error ' + repr(e)
            if im:
                im.save(os.path.join(outdir, name + '.png'))
            print(name, info, flush=True)
