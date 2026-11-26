#!/usr/bin/env python3
"""boostan.py <boostrecon.csv> - per race section: each time YOU go into ramjet (boost state 4), the racer ahead of you
at that moment (within 250 m): did it ramjet too within 3 s, its speed change and the gap change over the next 5 s."""
import sys

def num(x):
    try:
        return float(x)
    except ValueError:
        return None

sections, cur = [], None
for line in open(sys.argv[1]):
    line = line.rstrip('\n')
    if line.startswith('#'):
        cur = {'label': line.split('|')[1].strip() if '|' in line else line, 'rows': []}
        sections.append(cur)
        continue
    if line.startswith('!'):  # a forced-ramjet marker (boostrecon.lua test 2)
        if cur is not None:
            cur.setdefault('forced', []).append(line)
        continue
    if line.startswith('t_s') or cur is None:
        continue
    f = line.split(',')
    if len(f) < 12:
        continue
    cur['rows'].append({'t': num(f[0]), 'you_kph': num(f[1]), 'you_b': f[2], 'ahead': f[4], 'ahead_kph': num(f[5]),
                        'ahead_b': f[6], 'ahead_m': num(f[7])})

for s in sections:
    rows = s['rows']
    if not rows:
        continue
    events = []
    for i in range(1, len(rows)):
        if rows[i]['you_b'].startswith('4') and not rows[i - 1]['you_b'].startswith('4'):
            r0 = rows[i]
            if not r0['ahead'] or r0['ahead_m'] is None or r0['ahead_m'] > 250:
                continue
            name, t0 = r0['ahead'], r0['t']
            already = r0['ahead_b'].startswith('4')
            replied, spd5, gap5, you5 = False, None, None, None
            for r in rows[i:]:
                if r['t'] - t0 > 5.01:
                    break
                if r['ahead'] != name:
                    continue
                if r['t'] - t0 <= 3.01 and r['ahead_b'].startswith('4') and not already:
                    replied = True
                spd5, gap5, you5 = r['ahead_kph'], r['ahead_m'], r['you_kph']
            events.append((t0, name, r0['ahead_m'], gap5, r0['ahead_kph'], spd5, r0['you_kph'], you5, already, replied))
    # the base rate (docs/boost-fix-test-plan.md test 1): non-overlapping 3 s windows where you are NOT in ramjet the
    # whole time and the racer ahead (within 250 m, not in ramjet at the start) stays the same racer - how often does it
    # go into ramjet anyway? Near the reply rate = the reply is the track; well below = it's a reply to you.
    base_n = base_hit = 0
    i = 0
    while i < len(rows):
        r0 = rows[i]
        ok = r0['ahead'] and r0['ahead_m'] is not None and r0['ahead_m'] <= 250 and not r0['ahead_b'].startswith('4') \
            and not r0['you_b'].startswith('4')
        if not ok:
            i += 1
            continue
        j, hit, clean = i, False, True
        while j < len(rows) and rows[j]['t'] - r0['t'] <= 3.01:
            r = rows[j]
            if r['you_b'].startswith('4') or r['ahead'] != r0['ahead']:
                clean = False
                break
            if r['ahead_b'].startswith('4'):
                hit = True
            j += 1
        if clean:
            base_n += 1
            base_hit += 1 if hit else 0
        i = max(j, i + 1)
    n = len(events)
    rep = sum(1 for e in events if e[9])
    alr = sum(1 for e in events if e[8])
    closed = [e[2] - e[3] for e in events if e[3] is not None]
    dspd = [e[5] - e[4] for e in events if e[5] is not None and e[4] is not None]
    print(f"== {s['label']}: {len(rows)} rows, {n} ramjets of yours with a racer ahead within 250 m"
          + (f", {len(s.get('forced', []))} forced" if s.get('forced') else ''))
    if base_n:
        print(f"   base rate: the racer ahead went into ramjet in {base_hit} of {base_n} 3 s windows WITHOUT you ramjetting"
              f" ({100 * base_hit / base_n:.0f}%)")
    if n:
        print(f"   the racer ahead: already in ramjet {alr}, ramjetted within 3 s {rep} of {n - alr}")
        print(f"   over 5 s: gap closed by {sum(closed)/len(closed):+.1f} m on average; its speed {sum(dspd)/len(dspd):+.0f} kph on average")
        for e in events:
            print(f"   t={e[0]:6.1f} {e[1]:<16} gap {e[2]:5.1f} -> {e[3] if e[3] is None else round(e[3],1)} m, "
                  f"its kph {e[4]:.0f} -> {e[5]}, yours {e[6]:.0f} -> {e[7]}{'  (already ramjet)' if e[8] else ('  REPLIED' if e[9] else '')}")
