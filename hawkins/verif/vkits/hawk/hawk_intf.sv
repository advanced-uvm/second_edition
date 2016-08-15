
// ***********************************************************************
// File:   hawk_intf.sv
// Author: bhunter
/* About:  A single HAWK interface. There should be one for RX and one for TX.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_INTF_SV__
   `define __HAWK_INTF_SV__

// class: hawk_intf
interface hawk_intf(input logic clk, input logic rst_n);
   import uvm_pkg::*;

   //----------------------------------------------------------------------------------------
   // Group: Signals

   // var: data
   // The byte-wide data signal
   logic [7:0] data;

   // var: valid
   // Valid wire
   logic valid;

   //----------------------------------------------------------------------------------------
   // Group: Clocking blocks
   clocking drv_cb @(posedge clk);
      output data;
      output valid;
      input rst_n;
   endclocking : drv_cb

   clocking mon_cb @(posedge clk);
      input data;
      input valid;
      input rst_n;
   endclocking : mon_cb

   //----------------------------------------------------------------------------------------
   // Group: Modports
   modport drv_mp(clocking drv_cb);
   modport mon_mp(clocking mon_cb);
endinterface : hawk_intf

`endif // __HAWK_INTF_SV__

