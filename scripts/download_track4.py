"""Extract Pew's published chart table; do not manufacture respondent records."""
import csv
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import sys
import urllib.request
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / 'data/raw/track4'
URL = 'https://www.pewresearch.org/politics/2026/10/08/economy-ranks-as-top-issue-in-midterms-for-all-voters-but-partisans-differ-over-the-importance-of-other-issues/'
TITLE = 'Republican and Democratic voters rate economy as top voting issue in midterms'

class ChartParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.charts = []
        self.tables = []
        self.table = None
        self.row = None
        self.cell = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        context = attrs.get('data-wp-context')
        if context:
            parsed = json.loads(context)
            if parsed.get('title') == TITLE and 'tableData' in parsed:
                self.charts.append(parsed)
        if tag == 'table': self.table = []
        if tag == 'tr' and self.table is not None: self.row = []
        if tag in ('td', 'th') and self.row is not None: self.cell = []

    def handle_data(self, data):
        if self.cell is not None: self.cell.append(data)

    def handle_endtag(self, tag):
        if tag in ('td', 'th') and self.cell is not None:
            self.row.append(''.join(self.cell).strip())
            self.cell = None
        if tag == 'tr' and self.row is not None:
            self.table.append(self.row)
            self.row = None
        if tag == 'table' and self.table is not None:
            self.tables.append(self.table)
            self.table = None

# Optional saved HTML supports an exact offline extraction without copying the
# full article into the public repository. Otherwise fetch the public source.
if len(sys.argv) == 2:
    page = Path(sys.argv[1]).read_bytes()
else:
    with urllib.request.urlopen(URL, timeout=60) as response:
        page = response.read()
parser = ChartParser()
parser.feed(page.decode('utf-8'))
assert len(parser.charts) == 1, 'Expected exactly one matching issue-priority chart'
chart = parser.charts[0]
table = chart['tableData']
expected_header = ['Topic', 'All RVs', 'Republican candidate supporters', 'Democratic candidate supporters']
assert table['header'] == expected_header
assert len(table['rows']) == 16
assert [table['header']] + table['rows'] in parser.tables, 'Chart JSON and rendered HTML table disagree'
assert len({row[0] for row in table['rows']}) == 16
assert all(len(row) == 4 and all(0 <= int(x) <= 100 for x in row[1:]) for row in table['rows'])
RAW.mkdir(parents=True, exist_ok=True)
with (RAW / 'pew_issue_priorities.csv').open('w', newline='') as stream:
    writer = csv.writer(stream)
    writer.writerow(table['header'])
    writer.writerows(table['rows'])
metadata = {
    'publisher': 'Pew Research Center', 'source_url': URL,
    'chart_url': chart['chartPostUrl'], 'chart_title': chart['title'],
    'chart_subtitle': chart['subtitle'], 'chart_note': chart['note'],
    'chart_source': chart['source'], 'publication_date': chart['postPubDate'],
    'fieldwork_start': '2026-09-28', 'fieldwork_end': '2026-10-04',
    'methodology_url': 'https://www.pewresearch.org/politics/2026/10/08/midterms-2026-methodology/',
    'population': 'Registered voters',
    'measure': 'Percent saying an issue is very important to their 2026 congressional vote',
    'unit': 'percent (0-100)', 'observation_grain': 'Published issue-by-voter-group aggregate',
    'source_page_sha256': hashlib.sha256(page).hexdigest(),
    'retrieved_utc': datetime.now(timezone.utc).isoformat(),
    'extraction': 'Parsed publisher chart tableData JSON and checked equality against its HTML table',
    'issues': 16, 'groups': 3, 'numeric_cells': 48,
    'source_csv_sha256': hashlib.sha256((RAW / 'pew_issue_priorities.csv').read_bytes()).hexdigest()
}
(RAW / 'provenance.json').write_text(json.dumps(metadata, indent=2))
print('PASS: 16 issues, 3 groups, 48 percentages; chart JSON equals the source HTML table.')
