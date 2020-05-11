from pathlib import Path
import re

run_log = Path('sim_run.log')

cache = dict()
def read_source(path):
    if not path in cache:
        cache[path] = path.read_text().split('\n')
    return cache[path]

def get_line(path, n):
    return read_source(Path(path))[int(n)-1]

regex = re.compile('^([\w./]+):(\d+): (.*?)')
with run_log.open('r') as f:
    for line in f:
        m = regex.search(line.strip())
        if m:
            source = m[1]
            n = m[2]
            line = line.strip('\n')
            print(f"{line:<100} {get_line(source, n).strip()}")
        else:
            print(line.strip('\n'))

