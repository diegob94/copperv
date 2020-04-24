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


def generate_report(df):
    def add_res_col(df, res):
        Res = res.strip().capitalize()
        df[Res] = [Res if i == res else '' for i in df.result]
        return df
    df = add_res_col(df, 'passed')
    df = add_res_col(df, 'failed')
    df = add_res_col(df, 'error')
    df = df.rename({'test':'Test'}, axis = 'columns')
    N = len(df)
    totals = dict(
        Test = str(N), 
        log = '',
        result = '',
        Passed = str(sum(df.result == 'passed')), 
        Failed = str(sum(df.result == 'failed')), 
        Error = str(sum(df.result == 'error'))
    )
    temp = {k:f'---' if k != 'Test' else 'Summary' for k in totals.keys()} 
    df = df.append(temp, ignore_index = True)
    df = df.append(totals, ignore_index = True)
    temp = {k:f'{100*float(v)/N:.1f}%' if v != '' else '' for k,v in totals.items()} 
    df = df.append(temp, ignore_index = True)
    #index = list(df.index)
    #index.insert(0, index[-1])
    #index.insert(0, index[-2])
    #index = index[:-2]
    #df = df.reindex(index)
    return df[['Test', 'result', 'Passed', 'Failed', 'Error', 'log']]

def display(test_report):
    return test_report.rename({'Passed':'','Failed':'Result','Error':''}, axis = 'columns')

df = pd.DataFrame(results)
test_report = generate_report(df)
test_report = test_report[['Test','Passed','Failed','Error']]
print("\nSummary:")
print(test_report.iloc[-2:,:].T.reindex(['Passed','Failed','Error','Test']).rename({'Test':'Total'},axis='index').to_string(header = False))

readme = str(tabulate.tabulate(display(test_report), tablefmt = 'github', showindex = False, headers="keys"))

readme_path = Path('../README.md')
header = "## Unit test results:"
text = []
for line in readme_path.read_text().splitlines():
    text.append(line)
    if line.strip() == header:
        break
readme_path.write_text('\n'.join(text) + '\n\n' + readme + '\n\n')
print('\nUpdated README.md')
