#!/usr/bin/env python

from tabulate import tabulate
from pathlib import Path
import re
import pandas as pd
import argparse

parser = argparse.ArgumentParser(description='Write README.md')
parser.add_argument('test_rpt', type=Path, help='Unit test report')
args = parser.parse_args()

test_rpt_path = args.test_rpt

readme_template = """
# copperv
RISCV core

## Usage
- https://github.com/riscv/riscv-gnu-toolchain
  -  Clone to $ROOT/util/riscv-gnu-toolchain  
  -  Set install prefix $ROOT/util/toolchain
- https://github.com/riscv/riscv-tests
  -  Clone to $ROOT/util/riscv-tests
- https://www.accellera.org/downloads/standards/ovl
  -  Download to $ROOT/util/std_ovl
- http://iverilog.icarus.com/
- ZSH
- Python 3:
  - Recommended to use pyenv to install last python
  - pip install -r requirements.txt
- Basic simulation:
  - mkdir work
  - ln -s ../scripts/Makefile work/Makefile
  - cd work
  - make
- Unit tests:
  - cd work
  - ../scripts/unit_test.zsh

## Unit test results:

{test_report}

""".strip()

def parse(test_rpt):
    header = []
    data = []
    spaces = re.compile('\s+')
    def split(line):
        return spaces.split(line.strip())
    with test_rpt.open('r') as f:
        for i,line in enumerate(f):
            if len(line.strip()) == 0:
                break
            if i == 0:
                header.extend(split(line))
            else:
                data.append(split(line))
    return pd.DataFrame(data, columns = header)

def generate_report(df):
    def add_res_col(df, res):
        Res = res.capitalize()
        df[Res] = [Res if i == res else '' for i in df.result]
        return df
    df = add_res_col(df, 'passed')
    df = add_res_col(df, 'failed')
    df = add_res_col(df, 'error')
    df = df.rename({'test_name':'Test'}, axis = 'columns')
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

df = parse(test_rpt_path)
test_report = generate_report(df)
test_report = test_report[['Test','Passed','Failed','Error']]
print("\nSummary:")
print(test_report.iloc[-2:,:].T.reindex(['Passed','Failed','Error','Test']).rename({'Test':'Total'},axis='index').to_string(header = False))

readme = readme_template.format(
    test_report = tabulate(display(test_report), tablefmt = 'github', showindex = False, headers="keys")
)

Path('../README.md').write_text(readme + '\n\n')
print('\nGenerated README.md')

