"""Portable Godot regression runner. Isolates user:// and keeps full evidence."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent.parent
DOMAIN = ['foundation_test', 'construction_test', 'simulation_test', 'save_test',
          'management_test', 'lodging_value_test', 'reviews_test', 'progression_test',
          'content_test', 'analytics_test', 'checkin_diagnostics_test']
STRESS = ['save_multiseed_test', 'stress_test', 'admission_equivalence_test']
STUDIES = ['long_run_test', 'departure_observer_test', 'tariff_scenarios']


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--godot', default=os.environ.get('GDA_GODOT'))
    parser.add_argument('--group', choices=['domain', 'stress', 'studies', 'mobile', 'all'], default='domain')
    parser.add_argument('--suite', action='append', help='Run only these script stems')
    parser.add_argument('--timeout', type=int, default=600)
    parser.add_argument('--label', default='regression')
    args = parser.parse_args()
    gda = shutil.which('gda')
    if not gda:
        parser.error('gda is required; set PATH to its executable')
    groups = {'domain': DOMAIN, 'stress': STRESS, 'studies': STUDIES,
              'mobile': sorted(p.stem for p in (ROOT / 'tests/mobile').glob('*.gd'))}
    suites = args.suite or ([s for group in groups.values() for s in group] if args.group == 'all' else groups[args.group])
    if not suites:
        parser.error('No suites selected')
    stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    run_root = ROOT / '.runtime' / 'tests' / f'{stamp}-{args.label}'
    run_root.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ, PYTHONIOENCODING='utf-8')
    if args.godot:
        env['GDA_GODOT'] = args.godot
    def git(*words):
        return subprocess.check_output(['git', '-C', str(ROOT), *words], text=True).strip()
    report = {'revision': git('rev-parse', 'HEAD'), 'dirty': bool(git('status', '--porcelain')),
              'group': args.group, 'started_utc': stamp, 'status': 'running', 'steps': []}
    provenance = subprocess.run([gda, '--version', '--json'], env=env, capture_output=True, text=True, encoding='utf-8')
    (run_root / 'gda-version.json').write_text(provenance.stdout, encoding='utf-8')
    for suite in suites:
        path = ROOT / 'tests' / f'{suite}.gd'
        if not path.is_file():
            path = ROOT / 'tests/mobile' / f'{suite}.gd'
        if not path.is_file():
            parser.error(f'Unknown suite: {suite}')
        command = [gda, '--user-data-root', str(run_root / suite / 'user-data'),
                   'script', 'run', 'res://' + path.relative_to(ROOT).as_posix(),
                   '--project', str(ROOT), '--timeout', str(args.timeout), '--strict', '--json']
        started = time.monotonic()
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8')
        evidence = run_root / f'{suite}.json'
        evidence.write_text(result.stdout, encoding='utf-8')
        (run_root / f'{suite}.stderr.log').write_text(result.stderr, encoding='utf-8')
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError:
            payload = {'error': {'message': 'Invalid gda result'}}
        summaries = []
        for line in payload.get('stdout', '').splitlines():
            try:
                item = json.loads(line)
                if isinstance(item, dict) and 'suite' in item:
                    summaries.append(item)
            except json.JSONDecodeError:
                pass
        errors = payload.get('diagnostics', [])
        passed = result.returncode == 0 and payload.get('exit_status') == 0 and not errors and bool(summaries) and all(s.get('failures', 1) == 0 for s in summaries)
        step = {'suite': suite, 'passed': passed, 'duration_seconds': round(time.monotonic() - started, 3),
                'summaries': summaries, 'evidence': str(evidence.relative_to(ROOT)),
                'sha256': hashlib.sha256(evidence.read_bytes()).hexdigest()}
        report['steps'].append(step)
        report['status'] = 'running'
        (run_root / 'report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        print(json.dumps(step), flush=True)
    report['status'] = 'passed' if all(s['passed'] for s in report['steps']) else 'failed'
    report['completed_utc'] = dt.datetime.now(dt.timezone.utc).isoformat()
    (run_root / 'report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'status': report['status'], 'report': str(run_root / 'report.json')}), flush=True)
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    sys.exit(main())
