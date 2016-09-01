// ***********************************************************************
// File:   global_pkg.sv
// Author: bhunter
/* About:  Global Package
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
   *************************************************************************/


`include "uvm_macros.svh"
`include "cmn_macros.sv"
`include "global_macros.sv"

package global_pkg;

   //--------------------------------------------------------------------------
   // Group: Imports
   import uvm_pkg::*;

   //--------------------------------------------------------------------------
   // Group: Includes
`include "global_heartbeat_mon.sv"
`include "global_watchdog.sv"
`include "global_env.sv"

endpackage : global_pkg


