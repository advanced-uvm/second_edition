// ***********************************************************************
// File:   mon.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
 *************************************************************************/


`ifndef __MON_SV__
   `define __MON_SV__

// class: mon_c
class mon_c extends uvm_monitor;
   `uvm_component_utils_begin(my_pkg::mon_c)
      `uvm_field_string(intf_name, UVM_COMPONENT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: intf_name
   // Interface name
   string intf_name = "<UNASSIGNED>";

   //----------------------------------------------------------------------------------------
   // Group: TLM Ports

   // var: item_port
   // All monitored items go out here
   uvm_analysis_port#(item_c) item_port;

   // var: upstream_analysis_imp
   // Receives the next expected item
   uvm_analysis_imp_upstream #(item_c, mon_c) upstream_imp;

   // var: downstream_port
   // Pushes out the next expected item to listeners
   uvm_analysis_port #(item_c) downstream_port;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: vi
   // Virtual interface to monitor
   virtual my_intf.mon_mp vi;

   // var: exp_items
   // The expected items from upstream
   item_c exp_items[$];

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="mon",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      `cmn_get_intf(virtual my_intf.mon_mp, "my_pkg::intf", intf_name, vi)
      item_port = new("item_port", this);
      upstream_imp = new("upstream_imp", this);
      downstream_port = new("downstream_port", this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: end_of_elaboration_phase
   virtual function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      `global_add_to_heartbeat_mon();
   endfunction : end_of_elaboration_phase

   ////////////////////////////////////////////
   // func: run_phase
   // Launch the monitor and handle reset gracefully
   virtual task run_phase(uvm_phase phase);
      forever begin
         @(posedge vi.rst_n);

         fork
            monitor();
         join_none

         @(negedge vi.rst_n);
         disable fork;

         exp_items.delete();
      end
   endtask : run_phase

   ////////////////////////////////////////////
   // func: shutdown_phase
   // Ensure that shutdown phase doesn't end until we've seen all expected items
   virtual task shutdown_phase(uvm_phase phase);
      forever begin
         if(exp_items.size()) begin
            phase.raise_objection(this, $sformatf("Expecting %0d items.", exp_items.size()));
            `cmn_info(("Waiting for %0d items.", exp_items.size()))
            wait(exp_items.size() == 0);
            phase.drop_objection(this, "inactive");
         end
         wait(exp_items.size() > 0);
      end
   endtask : shutdown_phase

   ////////////////////////////////////////////
   // func: monitor
   // Monitor the bus interface and reconstruct packets
   task monitor();
      byte unsigned cycles[$];

      forever begin
         @(posedge vi.mon_cb.valid);
         `global_heartbeat("activity seen")

         while(vi.mon_cb.valid) begin
            cycles.push_back(vi.mon_cb.data);
            @(vi.mon_cb);
         end

         item_rcvd(cycles);
         cycles.delete();
      end
   endtask : monitor

   ////////////////////////////////////////////
   // func: item_rcvd
   // Called when a complete item has been seen
   virtual function void item_rcvd(byte unsigned _cycles[$]);
      byte unsigned stream[];
      item_c item = item_c::type_id::create("item");
      item_c exp_item = exp_items.pop_front();

      if(exp_item)
         item.uid = exp_item.uid;

      stream = new[_cycles.size()](_cycles);
      item.data = new[_cycles.size()];
      item.unpack_bytes(stream);

      `cmn_dbg(200, ("Monitored: %s", item.convert2string()))
      item_port.write(item);
   endfunction : item_rcvd

   ////////////////////////////////////////////
   // func: write_upstream
   // The implementation for the upstream_imp, to gather the expected items
   // (used only for UID mapping, but could be used for more)
   virtual function void write_upstream(item_c _item);
      exp_items.push_back(_item);
      downstream_port.write(_item);
   endfunction : write_upstream
endclass : mon_c

`endif // __MON_SV__
