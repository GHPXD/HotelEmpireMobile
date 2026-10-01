"""Inventory original PNGs, import limits, references and RGBA estimates (not measured VRAM)."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parent.parent


def inventory():
    references = {}
    for folder in ['core', 'data', 'debug', 'entities', 'hotel', 'progression', 'simulation', 'ui', 'assets/art']:
        for path in (ROOT / folder).rglob('*.gd'):
            for asset in re.findall(r'res://(assets/[^"\)]+\.png)', path.read_text(encoding='utf-8-sig')):
                references.setdefault(asset, []).append(path.relative_to(ROOT).as_posix())
    assets = []
    for path in sorted((ROOT / 'assets/art').rglob('*.png')):
        data = path.read_bytes()
        if data[:8] != b'\x89PNG\r\n\x1a\n':
            raise ValueError(f'Invalid PNG: {path}')
        width, height = struct.unpack('>II', data[16:24])
        receipt = Path(str(path) + '.import')
        text = receipt.read_text(encoding='utf-8-sig') if receipt.exists() else ''
        limit = re.search(r'process/size_limit=(\d+)', text)
        size_limit = int(limit[1]) if limit else 0
        factor = min(1, size_limit / max(width, height)) if size_limit else 1
        relative = path.relative_to(ROOT).as_posix()
        assets.append({'path': relative, 'width': width, 'height': height, 'bytes': len(data),
                       'sha256': hashlib.sha256(data).hexdigest(), 'size_limit': size_limit,
                       'estimated_rgba_bytes': int(width * factor) * int(height * factor) * 4,
                       'mipmaps': 'mipmaps/generate=true' in text,
                       'referenced_by': sorted(set(references.get(relative, [])))})
    return {'scope': 'Source/import inventory; RGBA estimates exclude mipmaps and are not measured device memory',
            'count': len(assets), 'unlimited': sum(a['size_limit'] == 0 for a in assets),
            'source_bytes': sum(a['bytes'] for a in assets),
            'estimated_rgba_bytes': sum(a['estimated_rgba_bytes'] for a in assets), 'assets': assets}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / '.runtime/mobile-assets.json')
    args = parser.parse_args()
    report = inventory()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if k != 'assets'}))
