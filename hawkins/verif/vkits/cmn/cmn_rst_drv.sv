// ***********************************************************************
// File:   cmn_rst_drv.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
 *************************************************************************/

`ifndef __CMN_RST_DRV_SV__
   `define __CMN_RST_DRV_SV__

// class: rst_drv_c
class rst_drv_c extends uvm_driver;
   `uvm_component_utils_begin(cmn_pkg::rst_drv_c)
      `uvm_field_string(intf_name,            UVM_COMPONENT)
      `uvm_field_int(active_low,              UVM_COMPONENT)
      `uvm_field_int(x_time_ps,               UVM_COMPONENT | UVM_DEC)
      `uvm_field_int(reset_time_ps,           UVM_COMPONENT | UVM_DEC)
      `uvm_field_int(reset_drain_time_ps,     UVM_COMPONENT | UVM_DEC)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Configuration Fields

   // var: intf_name
   // Name in the resource database under which the vintf is stored. The scope
   // under which it is stored is "cmn_pkg::rst_intf".
   string intf_name = "rst_i";

   // var: active_low
   // When set, the reset signal will start low and go high.  When clear, it's the opposite.
   bit active_low = 1;

   // var: x_time_ps
   // The length of time that reset signal will stay at x at the beginning of time
   rand int unsigned x_time_ps;

   // var: reset_time_ps
   // The length of time that reset will stay active
   rand int unsigned reset_time_ps;

   // var: reset_drain_time
   // The amount of time after reset is asserted to continue the reset phase
   rand int unsigned reset_drain_time_ps;

   // Base constraints.  Turn these off if you wish to override them
   constraint L0_cnstr {
      x_time_ps >= 0;
      x_time_ps < 100000;
      reset_time_ps >= 0;
      reset_time_ps < 1000000;
      reset_drain_time_ps inside {[1000:50000]};
   }

   //----------------------------------------------------------------------------------------
   // Fields
   // var: rst_vi
   // Reset interface
   virtual cmn_rst_intf rst_vi;

   //----------------------------------------------------------------------------------------
   // Methods
   function new(string name="rst_drv",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   // Fetch the reset interface
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `cmn_get_intf(virtual cmn_rst_intf, "cmn_pkg::rst_intf", intf_name, rst_vi)
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: pre_reset_phase
   virtual task pre_reset_phase(uvm_phase phase);
      phase.raise_objection(this);
      if(x_time_ps) begin
         rst_vi.rst_n <= 'bx;
         #(x_time_ps * 1ps);
      end
      rst_vi.rst_n <= ~active_low;
      phase.drop_objection(this);
   endtask : pre_reset_phase

   ////////////////////////////////////////////
   // func: reset_phase
   virtual task reset_phase(uvm_phase phase);
      int run_count;
      phase.raise_objection(this);

      // if reset phase has been executed more than once this means testbench
      // is doing a phase jump. In this case, assert reset signal in reset phase.
      run_count = phase.get_run_count();

      if(run_count > 1 ) begin
         `cmn_info(("reset phase run count %0d", run_count))
         rst_vi.rst_n <= ~active_low;
      end

      #(reset_time_ps * 1ps);       // drive reset to disabled value
      rst_vi.rst_n <= active_low;
      #(reset_drain_time_ps * 1ps); // wait the ‘drain’ time
      phase.drop_objection(this);   // and drop the objection
   endtask : reset_phase
endclass : rst_drv_c

`endif // __CMN_RST_DRV_SV__
