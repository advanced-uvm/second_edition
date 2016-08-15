// ***********************************************************************
// File:   hawk_drv.sv
// Author: bhunter
/* About:  Hawk Driver
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_DRV_SV__
   `define __HAWK_DRV_SV__

`include "hawk_phy_item.sv"
`include "hawk_types.sv"

// class: drv_c
class drv_c extends uvm_driver#(phy_item_c);
   `uvm_component_utils_begin(hawk_pkg::drv_c)
      `uvm_field_string(intf_name, UVM_DEFAULT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: intf_name
   // Name of virtual interface handle
   string intf_name = "<UNASSIGNED>";

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: vi
   // The interface
   virtual hawk_intf.drv_mp vi;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="drv",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `cmn_get_intf(virtual hawk_intf.drv_mp, "hawk_pkg::hawk_intf", intf_name, vi)
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: run_phase
   virtual task run_phase(uvm_phase phase);
      forever begin
         // wait first for reset to go high
         @(posedge vi.drv_cb.rst_n);

         // put interface in "reset"
         vi.drv_cb.valid <= 1'b0;
         vi.drv_cb.data <= 'h0;

         fork
            driver();
         join_none

         @(negedge vi.drv_cb.rst_n);
         disable fork;
      end
   endtask : run_phase

   ////////////////////////////////////////////
   // func: driver
   // Drive stuff
   virtual task driver();
      // ensure that we start on a clock edge
      @(vi.drv_cb);

      forever begin
         seq_item_port.try_next_item(req);
         if(!req) begin
            vi.drv_cb.valid <= 1'b0;
            vi.drv_cb.data <= 'h0;
            seq_item_port.get_next_item(req);
            @(vi.drv_cb);
         end

         `cmn_dbg(300, ("Driving %s", req.convert2string()))
         vi.drv_cb.valid <= req.valid;
         vi.drv_cb.data <= req.data;
         seq_item_port.item_done();
         @(vi.drv_cb);
      end
   endtask : driver
endclass : drv_c

`endif // __HAWK_DRV_SV__

