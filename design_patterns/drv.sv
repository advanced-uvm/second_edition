// ***********************************************************************
// File:   drv.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
 *************************************************************************/

`ifndef __DRV_SV__
   `define __DRV_SV__

// class: drv_c
class drv_c extends uvm_driver#(item_c);
   `uvm_component_utils_begin(my_pkg::drv_c)
      `uvm_field_string(intf_name, UVM_COMPONENT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: intf_name
   // Interface name
   string intf_name = "<UNASSIGNED>";

   //----------------------------------------------------------------------------------------
   // Group: TLM Ports

   // var: downstream_imp
   // Mark monitored transactions with most recent
   uvm_analysis_imp#(item_c, drv_c) downstream_imp;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: vi
   // Interface for driving bus
   virtual my_intf.drv_mp vi;

   // var: start_driver, reset_driver
   // Used for reset testing
   event start_driver, reset_driver;

   // var: driving
   // Set to 1 while driving
   bit driving;

   // var: most_recent
   // Holds the most recently driven item
   item_c most_recent;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="drv",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   // Get the virtual interface and create the downstream_imp
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `cmn_get_intf(virtual my_intf.drv_mp, "my_pkg::intf", intf_name, vi)
      downstream_imp = new("downstream_imp", this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: run_phase
   // Launch the driver when out of reset
   virtual task run_phase(uvm_phase phase);
      forever begin
         reset();
         @(start_driver);

         fork
            driver();
         join_none

         @(reset_driver);
         disable fork;
      end
   endtask : run_phase

   ////////////////////////////////////////////
   // func: post_reset_phase
   virtual task post_reset_phase(uvm_phase phase);
      ->start_driver;
   endtask : post_reset_phase

   ////////////////////////////////////////////
   // func: shutdown_phase
   // Ensure that the shutdown phase doesn't finish until we are finished driving
   virtual task shutdown_phase(uvm_phase phase);
      forever begin
         if(driving) begin
            phase.raise_objection(this, "currently driving");
            @(driving);
            phase.drop_objection(this, "inactive");
         end
         @(driving);
      end
   endtask : shutdown_phase

   ////////////////////////////////////////////
   // func: reset
   // Reset the interface signals and any class fields
   task reset();
      vi.reset();
      driving = 0;
   endtask // tx_reset

   ////////////////////////////////////////////
   // func: driver
   // Get requests, pack them, and drive them
   virtual task driver();
      byte unsigned cycles[];

      forever begin
         seq_item_port.try_next_item(req);
         if(!req) begin
            vi.reset();
            seq_item_port.get_next_item(req);
            @(vi.drv_cb);
         end

         `cmn_dbg(200, ("Driving: %s", req.convert2string()))
         cycles.delete();
         req.pack_bytes(cycles);
         foreach(cycles[idx]) begin
            driving = 1;
            vi.drv_cb.valid <= 1'b1;
            vi.drv_cb.data <= cycles[idx];
            `cmn_dbg(300, ("Cycle: %02X", cycles[idx]))
            @(vi.drv_cb);
         end
         most_recent = req;
         seq_item_port.item_done(req);
         driving = 0;
         `cmn_dbg(200, ("%s Completed.", req.convert2string()))
         vi.reset();
         @(vi.drv_cb);
      end
   endtask : driver

   ////////////////////////////////////////////
   // func: write_downstream
   // Receives monitored items and marks them with the most recently sent UID
   virtual function void write_downstream(item_c _item);
      if(most_recent)
         _item.uid = most_recent.uid;
   endfunction : write_downstream
endclass : drv_c

`endif // __DRV_SV__
