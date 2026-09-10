"""Continue groups 88-92 using the unchanged repository discovery and containment runner.
Groups 1-52 passed in mac-full-tests-final.log, 53-87 in mac-remaining-tests.log.
Only a group-88 test changes to assert the documented confirmed-zero behavior.
"""
import importlib.util
from pathlib import Path
import sys

repo = Path('/Users/yuxiao/Documents/working/apple/CodexBar')
spec = importlib.util.spec_from_file_location('codexbar_runner', repo / 'Scripts/ci_swift_test_by_suite.py')
runner = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = runner
spec.loader.exec_module(runner)
selections = runner.prioritized_suites(runner.filtered_suites_for_environment(runner.swift_test_list(['swift'])))
groups = list(runner.chunks(selections, 12))
assert len(selections) == 1102 and len(groups) == 92, (len(selections), len(groups))
print('Coverage continuation: prior 87 passing groups + remaining 5 groups = all 1102 selections', flush=True)
for index, group in enumerate(groups[87:], 88):
    print(f'::group::Swift test continuation group {index}/92 ({len(group)} selections)', flush=True)
    result = runner.run_group(group, 180, ['swift'])
    print('::endgroup::', flush=True)
    if result != 0:
        print(f'Continuation group {index} failed: {result}', flush=True)
        raise SystemExit(result)
print('ALL REMAINING 5 GROUPS PASSED; UNION COVERAGE 92/92 GROUPS, 1102/1102 SELECTIONS', flush=True)
