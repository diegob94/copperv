#!/usr/bin/zsh

report(){
    direction=${1:?}
    inst_data=${2:?}
    sed '/module copperv/,/);/ p' -n ../rtl/copperv.v | grep $direction | sed 's/^.*? (\w+),?$/\1/' -r | grep "^${inst_data}" | sort | sed 's/^/* /'
}
echo '# Instruction bus:'
echo '## inputs:'
report input i
echo '## outputs:'
report output i
echo '# Data bus:'
echo '## inputs:'
report input d
echo '## outputs:'
report output d
