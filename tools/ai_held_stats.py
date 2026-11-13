import re, statistics as st, sys, collections
L = open(sys.argv[1]).read().split('\n')
def secs(t):
    m, s = t.split(':'); return int(m) * 60 + float(s)
rounds = collections.OrderedDict(); per = collections.defaultdict(lambda: collections.defaultdict(list))
for l in L:
    m = re.search(r'\[exp\] result "([^"]+)" [^:]+: (.*)$', l)
    if not m or not l.startswith('2026-11-12 1'): continue
    if l[11:16] < '17:30': continue
    lab = m.group(1); ts = []
    for part in m.group(2).split(', '):
        n, t = part.rsplit(' ', 1)
        if n == 'YOU' or t == 'DNF': continue
        ts.append(secs(t)); per[lab][n].append(secs(t))
    rounds.setdefault(lab, []).append(sorted(ts))
for lab, races in rounds.items():
    best = [r[0] for r in races]; med = [st.median(r) for r in races]; last = [r[-1] for r in races]
    print(f'{lab:10s} n={len(races)} best {st.mean(best):6.1f} (each {", ".join(f"{b:.1f}" for b in best)})  median {st.mean(med):6.1f}  last {st.mean(last):6.1f}  spread {st.mean([l-b for l,b in zip(last,best)]):5.1f}')
print()
names = sorted({n for d in per.values() for n in d})
print('racer'.ljust(16) + ''.join(l.rjust(11) for l in rounds))
for n in names:
    print(n.ljust(16) + ''.join((f'{st.mean(per[l][n]):.1f}' if per[l][n] else '-').rjust(11) for l in rounds))
