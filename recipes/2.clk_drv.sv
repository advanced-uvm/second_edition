// ***********************************************************************
// File:   2.clk_drv.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Brian P. Hunter
 *************************************************************************/

`ifndef __2_CLK_DRV_SV__
   `define __2_CLK_DRV_SV__

class clk_drv_c extends uvm_driver;
   `uvm_component_utils_begin(cmn_pkg::clk_drv_c)
      `uvm_field_string(intf_name,     UVM_COMPONENT)
      `uvm_field_int(init_delay_ps,    UVM_COMPONENT | UVM_DEC)
      `uvm_field_int(init_value,       UVM_COMPONENT | UVM_DEC)
      `uvm_field_int(period_ps,        UVM_COMPONENT | UVM_DEC)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: intf_name
   // Name in the resource database under which the interface is stored. The scope
   // under which it is stored is "cmn_pkg::clk_intf".
   string intf_name = "<UNSPECIFIED>";

   // var: period_ps
   // Period in ps. Ensure that default does not cause an infinite loop.
   int period_ps = 2000;

   // var: init_delay_ps
   // Initial delay in ps
   int init_delay_ps;

   // var: init_value
   // The starting value of the clock signal
   bit init_value;

   //----------------------------------------------------------------------------------------
   // Group: Fields
   // interface to clock
   virtual cmn_clk_intf clk_vi;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="clk_drv",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   // Fetch the virtual interface
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `cmn_get_intf(virtual cmn_clk_intf, "cmn_pkg::clk_intf", intf_name, clk_vi)
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: run_phase
   // Produce the clock
   virtual task run_phase(uvm_phase phase);
      // Do some sanity checking of config items.
      if(init_delay_ps < 0)
        `cmn_fatal(("Clock init_delay_ps is less than zero!"))


      // this would cause an infinite loop
      if(period_ps == 0)
        `cmn_fatal(("Clock generator period is zero."))

      // Time-zero setup
      clk_vi.clk = init_value;
      #(init_delay_ps*1ps);
      clk_vi.clk = ~init_value;

      forever
         #(period_ps * 1ps) clk_vi.clk = ~clk_vi.clk;
   endtask : run_phase
endclass : clk_drv_c

`endif // __2_CLK_DRV_SV__
