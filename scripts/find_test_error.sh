#!/bin/bash

instruction_id=${1:?}
test_id=${2:?}

grep "INSTRUCTION_ID $instruction_id" -P sim/tests/isa -r -l | xargs grep "( $test_id," -H
