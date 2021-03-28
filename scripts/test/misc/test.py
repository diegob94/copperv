import sys
sys.path.append('./')
from pathlib import Path
from scripts.build_tools import as_list, flatten, stringify

print(as_list('hola'))
print(as_list(lambda x: 'hola'))
print(as_list(['hola','hola1']))
print(flatten([['hola'],['hola1',[['aaa'],['bbb']]]]))

print(stringify([[Path('/home/diegob/miniconda3/envs/copperv/lib/python3.8/work/test_simple/simple.hex')], [Path('/home/diegob/miniconda3/envs/copperv/lib/python3.8/work/test_simple/simple.D')]]))
print(stringify([["hola"],None]))
print(stringify({'wd': [PosixPath('/home/diegob/projects/copperv/work/sim')], 'vvpflags': ['-M. -mcopperv_tools'], 'plusargs': ["+HEX_FILE=[PosixPath('/home/diegob/projects/copperv/work/test_simple/simple.hex')] +DISS_FILE=[PosixPath('/home/diegob/projects/copperv/work/test_simple/simple.D')]"], 'logs_dir': ['log'], 'test_name': ['simple']}))
