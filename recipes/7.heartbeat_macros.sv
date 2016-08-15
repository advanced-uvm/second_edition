////////////////////////////////////////////
// macro: global_heartbeat
// Called by registered monitors to indicate that the DUT is still alive
`define global_heartbeat(str) begin global_env.heartbeat_mon.raise(this); end

////////////////////////////////////////////
// macro: global_add_to_heartbeat_mon
// Called by components to register themselves with the heartbeat monitor
// t : A time field that indicates what the drain time is for this component
`define global_add_to_heartbeat_mon(t) begin global_env.heartbeat_mon.register(this, t); end
