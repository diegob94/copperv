#!/usr/bin/zsh

run_test(){
    test_name=${1:r:t}
    if [[ "$single_test" != "" ]]; then
        if [[ "$single_test" != "$test_name" ]]; then
            return
        else
            echo "make TEST_SOURCES=$1 TEST_NAME=$test_name" 1>&2
        fi
    fi
    sim_run_log=sim_run_${test_name}.log
    make TEST_SOURCES=$1 TEST_NAME=$test_name |& tee run_test_${test_name}.log > /dev/null
    if test -f $sim_run_log; then
        if grep -q "TEST PASSED" $sim_run_log; then
            res="passed"
        elif grep -q "TEST FAILED" $sim_run_log; then
            res="failed"
        else
            res="error"
        fi
    else
        res="error"
    fi
    printf "%10s %10s %20s\n" $test_name $res run_test_${test_name}.log
    printf "%4d %10s %10s %20s\n" $2 $test_name $res run_test_${test_name}.log 1>&2
}

run_all_tests(){
    echo "test_name result log"
    i=0
    make clean |& tee clean.log > /dev/null
    for TEST in $TESTS; do
        run_test $TEST $i
        i=$((i + 1))
    done
}

TESTS=("../sim/tests/test_0.S")
TESTS+=($(ls ../util/riscv-tests/isa/rv32ui/*.S | xargs))

single_test=${1}
if [[ "$single_test" == "" ]]; then
    update_readme=-update_readme
fi

run_all_tests | column -t > unit_tests.rpt

../scripts/write_readme.py unit_tests.rpt $update_readme

