// ***********************************************************************
// File:   7.heartbeat_macros.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
 *************************************************************************/

`ifndef __7_HEARTBEAT_MACROS_SV__
   `define __7_HEARTBEAT_MACROS_SV__

////////////////////////////////////////////
// macro: global_heartbeat
// Called by registered monitors to indicate that the DUT is still alive
`define global_heartbeat(str) begin global_env.heartbeat_mon.raise(this); end

////////////////////////////////////////////
// macro: global_add_to_heartbeat_mon
// Called by components to register themselves with the heartbeat monitor
// t : A time field that indicates what the drain time is for this component
`define global_add_to_heartbeat_mon(t) begin global_env.heartbeat_mon.register(this, t); end

`endif // __7_HEARTBEAT_MACROS_SV__
