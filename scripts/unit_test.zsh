#!/usr/bin/zsh

run_test(){
    test_name=${1:r:t}
    if [[ "$single_test" != "" && "$single_test" != "$test_name" ]]; then
        return
    fi
    sim_run_log=sim_run_${test_name}.log
    printf "${test_name} "
#    make clean_run TEST_SOURCES=$1 TEST_NAME=$test_name |& tee run_test_${test_name}.log > /dev/null
    make TEST_SOURCES=$1 TEST_NAME=$test_name |& tee run_test_${test_name}.log > /dev/null
    if test -f $sim_run_log; then
        if grep -q "TEST PASSED" $sim_run_log; then
            printf "passed "
        elif grep -q "TEST FAILED" $sim_run_log; then
            printf "failed "
        else
            printf "error "
        fi
    else
        printf "error "
    fi
    echo "run_test_${test_name}.log "
}

run_all_tests(){
    echo "test_name result log"
    for TEST in $TESTS; do
        run_test $TEST
    done
}

summary(){
    echo Summary:
    echo Passed $(grep passed unit_tests.rpt | wc -l)
    echo Failed $(grep failed unit_tests.rpt | wc -l)
    echo Error  $(grep error unit_tests.rpt | wc -l)
    echo Total  $(($(cat unit_tests.rpt | wc -l) - 2))
}

TESTS=("../sim/tests/test_0.S")
TESTS+=($(ls ../util/riscv-tests/isa/rv32ui/*.S | xargs))
single_test=${1}

run_all_tests | column -t | tee unit_tests.rpt
echo                      | tee -a unit_tests.rpt
summary       | column -t | tee -a unit_tests.rpt
