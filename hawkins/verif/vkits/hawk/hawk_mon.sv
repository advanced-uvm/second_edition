
// ***********************************************************************
// File:   hawk_mon.sv
// Author: bhunter
/* About:  Monitors the interface for physical items
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_MON_SV__
   `define __HAWK_MON_SV__

`include "hawk_phy_item.sv"
`include "hawk_types.sv"

// class: mon_c
class mon_c extends uvm_monitor;
   `uvm_component_utils_begin(hawk_pkg::mon_c)
      `uvm_field_string(intf_name, UVM_DEFAULT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: intf_name
   // Tie me to my interface
   string intf_name = "<UNASSIGNED>";

   //----------------------------------------------------------------------------------------
   // Group: TLM Ports

   // var: phy_item_port
   // All monitored PHY items go out here
   uvm_analysis_port#(phy_item_c) phy_item_port;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: vi
   // Virtual Interface
   virtual hawk_intf.mon_mp vi;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="[name]",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `cmn_get_intf(virtual hawk_intf.mon_mp, "hawk_pkg::hawk_intf", intf_name, vi)
      phy_item_port = new("phy_item_port", this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: run_phase
   virtual task run_phase(uvm_phase phase);
      forever begin
         @(posedge vi.mon_cb.rst_n);

         fork
            monitor();
         join_none

         @(negedge vi.mon_cb.rst_n);
         disable fork;
      end
   endtask : run_phase

   ////////////////////////////////////////////
   // func: monitor
   // Watch the bus, transmit everything that is seen
   virtual task monitor();
      phy_item_c item;
      forever begin
         @(vi.mon_cb);
         item = phy_item_c::type_id::create("item");
         item.valid = vi.mon_cb.valid;
         item.data  = vi.mon_cb.data;
         `cmn_dbg(300, ("MON: %s", item.convert2string()))
         phy_item_port.write(item);
      end
   endtask : monitor
endclass : mon_c

`endif // __HAWK_MON_SV__

