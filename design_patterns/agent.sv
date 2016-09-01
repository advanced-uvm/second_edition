// ***********************************************************************
// File:   agent.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
 *************************************************************************/

`ifndef __AGENT_SV__
   `define __AGENT_SV__

// class: agent_c
class agent_c extends uvm_agent;
   `uvm_component_utils_begin(my_pkg::agent_c)
      `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_COMPONENT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   //----------------------------------------------------------------------------------------
   // Group: TLM Ports

   // var: item_port
   // All monitored items go out here
   uvm_analysis_port#(item_c) item_port;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // vars: drv, mon, sqr
   // Driver, monitor, and sequencer
   drv_c drv;
   mon_c mon;
   sqr_c sqr;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="agent",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      mon = mon_c::type_id::create("mon", this);

      if(is_active) begin
         drv = drv_c::type_id::create("drv", this);
         sqr = sqr_c::type_id::create("sqr", this);
      end

      item_port = new("item_port", this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: connect_phase
   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if(is_active) begin
         drv.seq_item_port.connect(sqr.seq_item_export);
         drv.downstream_port.connect(mon.upstream_imp);
      end

      // connect monitor’s item port to the agent’s
      mon.item_port.connect(item_port);
   endfunction : connect_phase

   ////////////////////////////////////////////
   // func: pre_reset_phase
   virtual task pre_reset_phase(uvm_phase phase);
      super.pre_reset_phase(phase);
      if(is_active) begin
         sqr.stop_sequences();
         ->drv.reset_driver;
      end
   endtask: pre_reset_phase
endclass : agent_c

`endif // __AGENT_SV__
