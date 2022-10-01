#include <verilated.h>
#include "Vtb.h"
#include <iostream>

vluint64_t main_time = 0;       // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  This is in units of the timeprecision
// used in Verilog (or from --timescale-override)

double sc_time_stamp() {        // Called by $time in Verilog
    return main_time;           // converts to double, to match
                                // what SystemC does
}

int main(int argc, char** argv, char** env) {
  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  Vtb* top = new Vtb{contextp};
  top->clk = 0;
  top->rst = 0;
  int reset_counter = 0;
  int last_clk = 0;
  while (!contextp->gotFinish()) { 
    if (main_time % (10000 / 2) == 0) {
      if ((!last_clk && (int)top->clk) && reset_counter++ == 10) top->rst = 1;
      //std::cout << "main_time: " << main_time << " top->clk: " << (int)top->clk << " top->rst: " << (int)top->rst << std::endl;
      top->eval();
      last_clk = (int)top->clk;
      top->clk = !top->clk;
    }
		main_time++;
  }
  delete top;
  delete contextp;
  return 0;
}
