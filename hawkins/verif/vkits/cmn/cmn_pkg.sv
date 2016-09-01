
// ***********************************************************************
// File:   cmn_pkg.sv
// Author: bhunter
/* About:  Common package
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
   *************************************************************************/

`include "uvm_macros.svh"
`include "cmn_macros.sv"

// package: cmn_pkg
package cmn_pkg;

   //----------------------------------------------------------------------------------------
   // Imports
   import uvm_pkg::*;
   localparam UVM_COMPONENT = UVM_NOPACK | UVM_NOCOMPARE | UVM_NOCOPY;

   //----------------------------------------------------------------------------------------
   // Includes

`include "cmn_clk_drv.sv"
`include "cmn_cseq.sv"
`include "cmn_csqr.sv"
`include "cmn_msgs.sv"
`include "cmn_objection.sv"
`include "cmn_rand_delays.sv"
`include "cmn_report_server.sv"
`include "cmn_rst_drv.sv"
`include "cmn_uid.sv"

endpackage : cmn_pkg

