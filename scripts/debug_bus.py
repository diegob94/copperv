from pprint import pprint
import yaml
import sys
from pathlib import Path
import pandas as pd

bus_dump = yaml.safe_load(Path(sys.argv[1]).read_text())

df = pd.DataFrame(bus_dump,dtype='object')
df = df.astype({
    'sim_time':pd.Int64Dtype(),
    'addr':pd.Int64Dtype(),
    'data':pd.Int64Dtype(),
    'strobe':pd.Int64Dtype(),
    'resp':pd.Int64Dtype()
})
print(df)

breakpoint()
