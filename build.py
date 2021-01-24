#!/usr/bin/env python

from scripts.copperv_tools import build, tests

test = tests['simple']
test_objs = [test_obj for test_source in test.source for test_obj in build.test_object(
    target = lambda target_dir, input_file: target_dir/test.name/input_file.with_suffix('.o').name,
    source = test_source,
    inc_dir = test.inc_dir,
)]
build.test_link(
    target = lambda target_dir, _: target_dir/test.name/test.target,
    source = test_objs,
)

build.run()
