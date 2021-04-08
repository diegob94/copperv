from pprint import pprint
import yaml
import sys
from pathlib import Path

pprint(yaml.safe_load(Path(sys.argv[1]).read_text()))
