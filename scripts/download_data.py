"""Download pinned public sources and a dated IMF snapshot; never scrape job sites."""
import concurrent.futures
import csv
import hashlib
import io
import json
from pathlib import Path
import time
import urllib.parse
import urllib.request
import subprocess
import sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / 'data/raw'
RAW.mkdir(parents=True, exist_ok=True)
manifest = []

def fetch(url):
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=90) as response:
                return response.read()
        except Exception:
            if attempt == 3:
                raise
            time.sleep(2 ** attempt)

def save(url, path):
    content = fetch(url)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)
    manifest.append(dict(file=str(path.relative_to(ROOT)), url=url,
                         retrieved_utc=datetime.now(timezone.utc).isoformat(),
                         sha256=hashlib.sha256(content).hexdigest(), bytes=len(content)))

job_commit = '9f53734cdea0e890f228394c2a8ea186550ef863'
socviz_commit = 'f285a44959705860f8d042fbda1c2d054c9c8eb4'
for name in ['tasks.csv', 'task_tags.csv', 'platforms.csv', 'readme.md']:
    save(f'https://raw.githubusercontent.com/ablack3/trends-in-agent-hiring/{job_commit}/tidytuesday/{name}', RAW / 'track1' / name)
save(f'https://raw.githubusercontent.com/ablack3/trends-in-agent-hiring/{job_commit}/README.md', RAW / 'track1/repository_README.md')
for name in ['data/gss_lon.rda', 'man/gss_lon.Rd', 'DESCRIPTION', 'R/data.r']:
    save(f'https://raw.githubusercontent.com/kjhealy/socviz/{socviz_commit}/{name}', RAW / 'track2' / Path(name).name)
print('Downloaded Track 1 and socviz::gss_lon.', flush=True)

base = 'https://services9.arcgis.com/weJ1QsnbMYJlCHdG/arcgis/rest/services/Daily_Chokepoints_Data/FeatureServer/0'
save(base + '?f=pjson', RAW / 'portwatch_metadata.json')
ids = [1, 2, 3, 4, 5, 6, 7, 8, 11, 14, 15, 19]
where = 'portid IN (' + ','.join(f"'chokepoint{i}'" for i in ids) + ") AND date <= DATE '2026-11-12'"

def query(**kwargs):
    url = base + '/query?' + urllib.parse.urlencode(dict(where=where, f='json', **kwargs))
    payload = json.loads(fetch(url))
    if 'error' in payload:
        raise RuntimeError(payload['error'])
    return payload, url

count, count_url = query(returnCountOnly='true')
expected = count['count']
print(f'IMF API reports {expected} rows for the selected 12 chokepoints.', flush=True)

def page(offset):
    payload, url = query(outFields='*', returnGeometry='false', orderByFields='ObjectId ASC',
                         resultOffset=offset, resultRecordCount=1000)
    return offset, payload, url

pages = []
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    for offset, payload, url in pool.map(page, range(0, expected, 1000)):
        path = RAW / 'track3' / f'page_{offset:06d}.json'
        path.parent.mkdir(exist_ok=True)
        content = json.dumps(payload).encode()
        path.write_bytes(content)
        manifest.append(dict(file=str(path.relative_to(ROOT)), url=url,
                             retrieved_utc=datetime.now(timezone.utc).isoformat(),
                             sha256=hashlib.sha256(content).hexdigest(), bytes=len(content)))
        pages.extend(f['attributes'] for f in payload['features'])

assert len(pages) == expected, (len(pages), expected)
assert len({r['ObjectId'] for r in pages}) == expected, 'Duplicate API object IDs'
after, _ = query(returnCountOnly='true')
assert after['count'] == expected, 'Source count changed during download; rerun'
metadata_after = json.loads(fetch(base + '?f=pjson'))
metadata_before = json.loads((RAW / 'portwatch_metadata.json').read_text())
assert metadata_after['editingInfo'] == metadata_before['editingInfo'], 'Source changed during download; rerun'
(RAW / 'track3/query_summary.json').write_text(json.dumps(dict(expected_rows=expected, where=where, count_url=count_url), indent=2))
with (RAW / 'track3/portwatch.csv').open('w', newline='') as stream:
    writer = csv.DictWriter(stream, fieldnames=pages[0].keys())
    writer.writeheader()
    writer.writerows(pages)
(ROOT / 'download_manifest.json').write_text(json.dumps(manifest, indent=2))
print(f'Download complete: {len(pages)} IMF rows, no pagination truncation.', flush=True)
subprocess.run([sys.executable, str(ROOT / 'scripts/download_track4.py')], check=True)
