"""Builds an evaluation photo set from Wikipedia: for every catalog dish, the photos of its
English and Russian Wikipedia articles (free licenses, Wikimedia Commons).

    python3 tools/fetch_eval.py [--per-dish 4]

Writes tools/testimg/wiki/<dish id>/<n>.jpg (git-ignored) and tools/testimg/wiki/sources.tsv.
Article photos also include non-food pictures (portraits, maps); tools/eval_set.mjs filters
those out with the model before measuring.
"""
import argparse
import concurrent.futures
import csv
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'tools', 'testimg', 'wiki')
UA = 'CalorieCam-eval/0.1 (https://github.com/justmvv/calorie-cam; just.mvv@gmail.com)'
SKIP = re.compile(r'(map|flag|logo|icon|portrait|coat_of_arms|signature|stamp|locator|diagram|chart|\.svg|\.gif|\.png)', re.I)


def get_json(url):
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)
        except Exception as e:  # rate limit or transient error: back off
            if attempt == 2:
                print(f'  ! {url[:90]}: {e}', file=sys.stderr)
                return None
            time.sleep(2 * (attempt + 1))


def article(lang, query):
    q = urllib.parse.urlencode({'action': 'query', 'list': 'search', 'srsearch': query, 'srlimit': 1, 'format': 'json'})
    d = get_json(f'https://{lang}.wikipedia.org/w/api.php?{q}')
    hits = (d or {}).get('query', {}).get('search', [])
    return hits[0]['title'] if hits else None


def images(lang, title):
    d = get_json(f'https://{lang}.wikipedia.org/api/rest_v1/page/media-list/{urllib.parse.quote(title.replace(" ", "_"))}')
    out = []
    for item in (d or {}).get('items', []):
        if item.get('type') != 'image' or SKIP.search(item.get('title', '')):
            continue
        srcset = item.get('srcset') or []
        if srcset:
            out.append(('https:' + srcset[0]['src'], item['title']))
    return out


def read_dishes():
    rows = [l for l in open(os.path.join(ROOT, 'assets', 'dishes.tsv'), encoding='utf-8') if l.strip() and not l.startswith('#')]
    return list(csv.DictReader(rows, delimiter='\t'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--per-dish', type=int, default=4)
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)

    def fetch(d):
        sources = []
        folder = os.path.join(OUT, d['id'])
        if os.path.isdir(folder) and len(os.listdir(folder)) >= args.per_dish:
            return sources
        os.makedirs(folder, exist_ok=True)
        en_query = re.sub(r'\s*\(.*?\)', '', d['name_en'])
        seen, n = set(), len(os.listdir(folder))
        for lang, query in (('en', en_query), ('ru', d['name_ru'])):
            title = article(lang, query)
            if not title:
                continue
            for url, file_title in images(lang, title):
                if n >= args.per_dish:
                    break
                if file_title in seen:
                    continue
                seen.add(file_title)
                try:
                    req = urllib.request.Request(url, headers={'User-Agent': UA})
                    with urllib.request.urlopen(req, timeout=30) as r:
                        data = r.read()
                except Exception as e:
                    print(f'  ! {url[:90]}: {e}', file=sys.stderr)
                    continue
                n += 1
                with open(os.path.join(folder, f'{n}.jpg'), 'wb') as f:
                    f.write(data)
                sources.append((d['id'], f'{n}.jpg', lang, title, file_title))
        print(f'{d["id"]:24} {n} photos', flush=True)
        return sources

    # A few dishes at a time: polite to Wikimedia, but not an hour-long run.
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        sources = [row for rows in pool.map(fetch, read_dishes()) for row in rows]
    with open(os.path.join(OUT, 'sources.tsv'), 'a', encoding='utf-8') as f:
        for row in sources:
            f.write('\t'.join(row) + '\n')


if __name__ == '__main__':
    main()
