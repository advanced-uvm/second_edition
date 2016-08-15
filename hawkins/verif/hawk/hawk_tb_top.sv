
// ***********************************************************************
// File:   hawk_tb_top.sv
// Author: bhunter
/* About:  Hawkins interface testbench.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

import uvm_pkg::*;

// package: tb_top
// Top-level hawk testbench
module tb_top;
   //----------------------------------------------------------------------------------------
   // Group: Interfaces

   // obj: tb_clk_i
   // Testbench clock interface
   cmn_clk_intf tb_clk_i();
   wire tb_clk = tb_clk_i.clk;

   // obj: tb_rst_i
   // Testbench reset interface
   cmn_rst_intf tb_rst_i(.clk(tb_clk));
   wire tb_rst_n = tb_rst_i.rst_n;

   // obj: hawk_tx_i
   // The hawk_intf instance.
   hawk_intf hawk_tx_i(.clk(tb_clk),
                     .rst_n(tb_rst_n));
   // obj: hawk_rx_i
   // The hawk_intf instance.
   hawk_intf hawk_rx_i(.clk(tb_clk),
                     .rst_n(tb_rst_n));

   //----------------------------------------------------------------------------------------
   // Group: Procedural Blocks

   ////////////////////////////////////////////
   // func: pre_run_test
   // Set interface names before run_test is called
   function void pre_run_test();
      `cmn_set_intf(virtual cmn_clk_intf,  "cmn_pkg::clk_intf", "tb_clk_vi",  tb_clk_i)
      `cmn_set_intf(virtual cmn_rst_intf,  "cmn_pkg::rst_intf", "tb_rst_vi",  tb_rst_i)
      `cmn_set_intf(virtual hawk_intf.drv_mp, "hawk_pkg::hawk_intf", "hawk_tx_vi", hawk_tx_i)
      `cmn_set_intf(virtual hawk_intf.mon_mp, "hawk_pkg::hawk_intf", "hawk_tx_vi", hawk_tx_i)
      `cmn_set_intf(virtual hawk_intf.drv_mp, "hawk_pkg::hawk_intf", "hawk_rx_vi", hawk_rx_i)
      `cmn_set_intf(virtual hawk_intf.mon_mp, "hawk_pkg::hawk_intf", "hawk_rx_vi", hawk_rx_i)
   endfunction : pre_run_test

   `include "cmn_tb_top.sv"
endmodule : tb_top
