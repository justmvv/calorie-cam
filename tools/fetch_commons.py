"""Adds photos from a Wikimedia Commons search to the evaluation set, for dishes whose Wikipedia
article photos are too few or too clean (e.g. a single studio apple):

    python3 tools/fetch_commons.py apple "red apple on table" "green apple" "sliced apple" --per-query 4

Writes tools/testimg/wiki/<dish id>/c<n>.jpg; tools/eval_set.mjs picks them up with the rest.
"""
import argparse
import os
import sys
import time
import urllib.parse
import urllib.request

from fetch_eval import OUT, SKIP, UA, get_json


def search(query, limit):
    q = urllib.parse.urlencode({
        'action': 'query', 'format': 'json', 'generator': 'search', 'gsrnamespace': 6,
        'gsrsearch': f'{query} filetype:bitmap', 'gsrlimit': limit * 3,
        'prop': 'imageinfo', 'iiprop': 'url|mime', 'iiurlwidth': 640,
    })
    d = get_json(f'https://commons.wikimedia.org/w/api.php?{q}')
    pages = sorted((d or {}).get('query', {}).get('pages', {}).values(), key=lambda p: p.get('index', 0))
    for p in pages:
        info = (p.get('imageinfo') or [{}])[0]
        if info.get('mime') == 'image/jpeg' and not SKIP.search(p['title']):
            yield p['title'], info['thumburl']


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('dish')
    ap.add_argument('queries', nargs='+')
    ap.add_argument('--per-query', type=int, default=4)
    args = ap.parse_args()
    folder = os.path.join(OUT, args.dish)
    os.makedirs(folder, exist_ok=True)
    taken = {f for f in os.listdir(folder)}
    n = 0
    seen = set()
    for query in args.queries:
        got = 0
        for title, url in search(query, args.per_query):
            if got >= args.per_query or title in seen:
                continue
            seen.add(title)
            try:
                with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=30) as r:
                    data = r.read()
            except Exception as e:
                print(f'  ! {url[:90]}: {e}', file=sys.stderr)
                continue
            n += 1
            while f'c{n}.jpg' in taken:
                n += 1
            taken.add(f'c{n}.jpg')
            got += 1
            with open(os.path.join(folder, f'c{n}.jpg'), 'wb') as f:
                f.write(data)
            time.sleep(0.3)
    print(f'{args.dish}: {sum(1 for f in taken if f.startswith("c"))} commons photos')


if __name__ == '__main__':
    main()
