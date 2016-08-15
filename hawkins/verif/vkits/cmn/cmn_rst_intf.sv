
// ***********************************************************************
// File:   cmn_rst_intf.sv
// Author: bhunter
/* About:  Common Reset Interface
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/


`ifndef __CMN_RST_INTF_SV__
   `define __CMN_RST_INTF_SV__

// class: cmn_rst_intf
interface cmn_rst_intf(input logic clk);

   //----------------------------------------------------------------------------------------
   // Group: Signals

   logic rst_n;

   //----------------------------------------------------------------------------------------
   // Group: Clocking blocks
   clocking cb @(posedge clk);
      output     rst_n;
   endclocking : cb

endinterface : cmn_rst_intf

`endif // __CMN_RST_INTF_SV__
