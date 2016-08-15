`include "cmn_rand_delay.sv"

// class: reg_background_cfg_c
class reg_background_cfg_c extends uvm_object;
   `uvm_object_utils_begin(cmn_pkg::reg_background_cfg_c)
      `uvm_field_queue_string(exclude_regs, UVM_DEFAULT)
      `uvm_field_object(rand_delays, UVM_DEFAULT)
   `uvm_object_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: exclude_regs
   // Registers that must be excluded
   string exclude_regs[$];

   // var: exclude_types
   // A queue of register TYPE names that should also be excluded
   string exclude_types[$];

   // var: rand_delays
   // A random delay object
   rand rand_delays_c rand_delays;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="reg_background_cfg");
      super.new(name);
      // create the rand_delays object
      rand_delays = cmn_pkg::rand_delays_c::type_id::create("rand_delays");
   endfunction : new
endclass : reg_background_cfg_c
