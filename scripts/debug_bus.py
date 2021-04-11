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
tran_id_bus_map = dict(ir=1,iw=2,dr=3,dw=4)
df.insert(3,'tid',df.apply(lambda row: int(f"{tran_id_bus_map[row.bus]}{row.id}"),axis='columns'))
df = df.drop(columns='id')
print(df)

def get_inst(tran_idx):
    idx = df.loc[:tran_idx][::-1].bus.eq('ir').idxmax()
    return df.loc[idx]
def bus_query(q):
    df_sub = df.query(q)
    tids = df_sub.tid.to_list()
    for idx in df_sub.index:
        tids.append(get_inst(idx).tid)
    r = df.query('tid in @tids')
    to_hex = lambda v: f'0x{v:X}' if not pd.isna(v) else '-'
    hex_cols = ['addr','data','resp','strobe']
    with pd.option_context('chained_assignment',None):
        for col in hex_cols:
            r[col] = r[col].apply(to_hex)
    return r

#print(bus_query('data == 0x309c or addr == 16777028'))
