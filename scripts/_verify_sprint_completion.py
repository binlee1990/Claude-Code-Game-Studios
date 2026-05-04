"""One-shot verification: cross-check story Status per sprint.

Sprint files use relative markdown links like ../epics/<epic>/story-XXX.md.
We resolve them relative to production/sprints/, then read each story's
Status field.
"""
import os
import re

SPRINTS_DIR = 'production/sprints'

totals = {}
for sprint_n in range(1, 11):
    sprint_md = os.path.join(SPRINTS_DIR, f'sprint-{sprint_n}.md')
    if not os.path.exists(sprint_md):
        continue
    with open(sprint_md, encoding='utf-8') as fp:
        content = fp.read()

    # Match relative link like ../epics/<slug>/story-XXX.md inside markdown link
    rel_refs = re.findall(r'\.\./epics/[^/\s)]+/story-[^\s)]+?\.md', content)
    refs = []
    for rel in rel_refs:
        # resolve relative to sprint file
        resolved = os.path.normpath(os.path.join(SPRINTS_DIR, rel)).replace('\\', '/')
        refs.append(resolved)
    refs = sorted(set(refs))

    done = pending = missing = 0
    pending_examples = []
    status_counter = {}
    for ref in refs:
        if not os.path.exists(ref):
            missing += 1
            pending_examples.append((ref, 'MISSING'))
            continue
        with open(ref, encoding='utf-8') as fp:
            c = fp.read()
        m = re.search(r'(?im)^\s*>?\s*\*{0,2}Status\*{0,2}\s*[:\-]\s*([A-Za-z\- ]+)', c)
        s = (m.group(1).strip().lower() if m else 'unknown')
        status_counter[s] = status_counter.get(s, 0) + 1
        if s in ('done', 'complete', 'completed', 'closed'):
            done += 1
        else:
            pending += 1
            if len(pending_examples) < 5:
                pending_examples.append((ref, s))
    totals[sprint_n] = (len(refs), done, pending, missing, status_counter, pending_examples)

print('sprint | refs | done | other | missing | verdict | status histogram')
for n, v in sorted(totals.items()):
    total, done, pend, miss, hist, exs = v
    flag = 'PASS' if (total > 0 and done == total and miss == 0) else 'FAIL'
    hist_str = ', '.join(f'{k}={vv}' for k, vv in sorted(hist.items()))
    print(f'  {n:>4} | {total:>4} | {done:>4} | {pend:>5} | {miss:>7} | {flag:<4}    | {hist_str}')
    if flag == 'FAIL' and exs:
        for ref, s in exs[:3]:
            print(f'    -> {ref} :: Status={s}')

print()
total_stories = sum(v[0] for v in totals.values())
total_done = sum(v[1] for v in totals.values())
print(f'AGGREGATE: {total_done}/{total_stories} stories marked done across 10 sprints')
