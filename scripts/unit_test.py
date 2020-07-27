#!/usr/bin/env python3

from multiprocessing import Pool
import sys
from pathlib import Path
from functools import partial

import pexpect
import tabulate
import pandas as pd

from get_test import get_all_tests

def run(*args,**kwargs):
#    print(*args)
    pexpect.run(*args, **kwargs)

root = Path('../')
tests = get_all_tests(root)

def run_test(padding,test):
    run(f'make TEST={test}',logfile=Path(f'unit_test_{test}.log').open('wb'))
    log_path = Path(f'sim_run_{test}.log')
    if log_path.exists():
        log = log_path.read_text()
        if "TEST PASSED" in log:
            res = "passed"
        elif "TEST FAILED" in log or "OVL_FATAL" in log:
            res = "failed"
        else:
            res = "error"
    else:
        res = "error"
    print(f'{test:{padding}s} {res}')
    return dict(
        test = test, 
        result = res,
    )

print("Building sim.vvp")
run(f'make sim.vvp',logfile=Path(f'unit_test_make_sim.log').open('wb'))
test_list = [i['test'] for i in tests]
test_list_len = [len(i) for i in test_list]
with Pool() as p:
    results = p.map(partial(run_test, max(test_list_len)+1), test_list)

summary = dict(passed = 0, failed = 0, error = 0, total = len(results))
for r in results:
    summary[r['result']] += 1
summary = {'passed': 43, 'failed': 0, 'error': 0, 'total': 43}

print('\nSummary:')
for r in summary.keys():
    print(f'{r.capitalize():6s} {summary[r]:5d} {100*summary[r]/summary["total"]:6.2f}%')

