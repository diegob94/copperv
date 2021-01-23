#!/usr/bin/env python

from scripts.copperv_tools import build, tests

test = tests['simple']
test_objs = build.test_object(
    target = lambda target_dir, input_file: target_dir/'test'/input_file.with_suffix('.o').name,
    source = test.source,
    inc_dir = test.inc_dir,
)
build.test_link(
    target = lambda target_dir, _: target_dir/'test'/test.target,
    source = test_objs,
)

build.run()
