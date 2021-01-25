#!/usr/bin/env python

from scripts.copperv_tools import build, tests

test = tests['simple']
test_dir = 'test_' + test.name
test_objs = []
for test_source in test.source:
    test_objs.extend(build.test_object(
        target = lambda target_dir, input_file: target_dir/test_dir/input_file.with_suffix('.o').name,
        source = test_source,
        inc_dir = test.inc_dir,
    ))
    build.test_preprocess(
        target = lambda target_dir, input_file: target_dir/test_dir/input_file.with_suffix('.E').name,
        source = test_source,
        inc_dir = test.inc_dir,
    )
test_elf = build.test_link(
    target = lambda target_dir, _: target_dir/test_dir/f'{test.name}.elf',
    source = test_objs,
)
build.test_verilog_hex(
    target = lambda target_dir, _: target_dir/test_dir/f'{test.name}.hex',
    source = test_elf,
)
build.test_dissassemble(
    target = lambda target_dir, _: target_dir/test_dir/f'{test.name}.D',
    source = test_elf,
)

build.run()
