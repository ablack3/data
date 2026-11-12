"""Freeze NORC's public CSV and codebook without redundant SAV/Stata copies.
Pass a previously downloaded publisher ZIP as argv[1] for offline preparation.
"""
import hashlib, io, json, sys, zipfile, urllib.request
from datetime import datetime, timezone
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / 'data/raw/track4'
RAW.mkdir(parents=True, exist_ok=True)
BASE = 'https://civichealth.norc.org/downloads/'
if len(sys.argv) > 1:
    source = Path(sys.argv[1]).read_bytes()
    codebook = Path(sys.argv[2]).read_bytes()
else:
    source = urllib.request.urlopen(BASE+'civichealth_datafile.zip',timeout=120).read()
    codebook = urllib.request.urlopen(BASE+'civichealth_codebook.zip',timeout=60).read()
with zipfile.ZipFile(io.BytesIO(source)) as z:
    csv = z.read('civichealth_datafile.csv')
with zipfile.ZipFile(RAW/'civichealth_csv.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    info = zipfile.ZipInfo('civichealth_datafile.csv', date_time=(2026,11,12,0,0,0))
    info.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(info,csv,compresslevel=9)
(RAW/'civichealth_codebook.zip').write_bytes(codebook)
meta = {'publisher':'NORC at the University of Chicago',
 'source_url':'https://civichealth.norc.org/download-data.html',
 'source_data_url':BASE+'civichealth_datafile.zip',
 'source_codebook_url':BASE+'civichealth_codebook.zip',
 'retrieved_utc':datetime.now(timezone.utc).isoformat(),
 'publisher_zip_sha256':hashlib.sha256(source).hexdigest(),
 'original_csv_sha256':hashlib.sha256(csv).hexdigest(),
 'original_csv_bytes':len(csv),
 'storage':'Original CSV bytes repacked in ZIP; redundant SAV and Stata copies omitted.',
 'snapshot_note':'Weights may change as NORC calibrates to final vote counts. Frozen November 12, 2026.'}
(RAW/'provenance.json').write_text(json.dumps(meta,indent=2)+'\n')
print('PASS: original CSV and publisher codebook archived.')

manifest_path = ROOT / 'download_manifest.json'
manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else []
manifest = [item for item in manifest if not item['file'].startswith('data/raw/track4/')]
for name, key in [('civichealth_csv.zip','source_data_url'),('civichealth_codebook.zip','source_codebook_url')]:
    path = RAW / name
    manifest.append({'file':str(path.relative_to(ROOT)), 'url':meta[key],
      'retrieved_utc':meta['retrieved_utc'], 'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
      'bytes':path.stat().st_size})
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
