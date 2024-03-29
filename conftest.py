import subprocess as sp
import os
import textwrap
import shutil
import functools
from pathlib import Path
import shlex

import pytest

def pytest_addoption(parser):
    parser.addoption(
        '--keep_files',
        action='store_true',
        help='Preserve SymbiYosys .sby file, log file and output directory for tests using sby_run fixture',)

def run(cmd):
    if not isinstance(cmd,str):
        cmd = " ".join([str(i) for i in cmd])
    r = ""
    try:
        print("subprocess>",cmd)
        r = sp.run(cmd,shell=True,capture_output=True,text=True,check=True).stdout
    except sp.CalledProcessError as e:
        print(e.stdout)
        print(e.stderr)
        raise ChildProcessError from None
    return r

def get_line(opt):
    opt_str = opt
    if isinstance(opt,Path):
        opt_str = str(opt)
    elif not isinstance(opt,str):
        opt_str = shlex.join([str(i) for i in opt])
    return opt_str

def get_lines(name,opts):
    lines = [f"[{name}]"]
    if isinstance(opts,str):
        opts = [opts]
    if name == "files":
        temp_opts = []
        for file in opts:
            if isinstance(file,str) or isinstance(file,Path) or len(file) == 1:
                file = Path(file)
                file = [file.name,file]
            temp_opts.append(file)
        opts = temp_opts
    for opt in opts:
        lines.append(get_line(opt))
    return lines

def get_config_file(options,engines,script,files):
    lines = []
    lines.extend(get_lines("options",options))
    lines.extend(get_lines("engines",engines))
    lines.extend(get_lines("script",script))
    lines.extend(get_lines("files",files))
    return '\n'.join(lines) + '\n'

def _sby_run(sby_path,log_path,options,engines,script,files):
    indent = 4
    print()
    sby_file = get_config_file(options,engines,script,files)
    print("SBY file:")
    print(textwrap.indent(sby_file," "*indent))
    sby_path.write_text(sby_file)
    sby_log = run(["sby","-f",sby_path,"2>&1","|","tee",log_path])
    print("SBY log:")
    print(textwrap.indent(sby_log," "*indent))
    for line in sby_log.splitlines():
        if "DONE" in line:
            assert("PASS" in line)

def remove(path):
    path = Path(path)
    print("Removing",path.resolve())
    if path.is_dir():
        shutil.rmtree(path)
    else:
        path.unlink()

@pytest.fixture
def sby_run(request):
    test_dir = Path(request.module.__file__).parent.resolve()
    keep_files = request.config.getoption('--keep_files')
    test_name = request.node.name
    sby_path = (test_dir/test_name).with_suffix(".sby")
    log_path = (test_dir/test_name).with_suffix(".log")
    yield functools.partial(_sby_run,sby_path,log_path)
    print()
    if not keep_files:
        remove(sby_path)
        remove(log_path)
        remove(test_dir/test_name)

