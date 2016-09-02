
// ***********************************************************************
// File:   cmn_clk_intf.sv
// Author: bhunter
/* About:  Common Clock Interface
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
   *************************************************************************/


`ifndef __CMN_CLK_INTF_SV__
   `define __CMN_CLK_INTF_SV__

// class: cmn_clk_intf
// A simple interface holding the clock wire, and it's ideal clock
interface cmn_clk_intf();

   //----------------------------------------------------------------------------------------
   // Group: Signals
   logic clk;

endinterface : cmn_clk_intf

`endif // __CMN_CLK_INTF_SV__
