from pathlib import Path

import toml
import pytest
from cocotb_test.simulator import run

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
chisel_dir = root_dir/'work/rtl'
rtl_v1_dir = root_dir/'src/main/resources/rtl_v1'

toml_path = sim_dir/"tests/unit_tests.toml"
unit_tests = toml.loads(toml_path.read_text())

rv_asm_paths = list(sim_dir.glob('tests/isa/rv32ui/*.S'))

common_run_opts = dict(
    verilog_sources=[
        chisel_dir/"copperv2.v",
        rtl_v1_dir/"idecoder.v",
    ],
    includes=[rtl_v1_dir/'include'],
    toplevel="Copperv2",
    module="cocotb_tests",
    waves = True,
)

@pytest.mark.parametrize(
    "parameters", [pytest.param({"TEST_NAME":name},id=name) for name in unit_tests]
)
def test_unit(parameters):
    run(
        **common_run_opts,
        extra_env=parameters,
        sim_build=f"work/sim/test_unit_{parameters['TEST_NAME']}",
        testcase = "unit_test",
    )

@pytest.mark.parametrize(
    "parameters", [pytest.param({"TEST_NAME":path.stem,"ASM_PATH":str(path.resolve())},id=path.stem)
        for path in rv_asm_paths]
)
def test_riscv(parameters):
    run(
        **common_run_opts,
        extra_env=parameters,
        sim_build=f"work/sim/test_riscv_{parameters['TEST_NAME']}",
        testcase = "riscv_test",
    )
