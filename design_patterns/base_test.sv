// ***********************************************************************
// File:   base_test.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
 *************************************************************************/

`ifndef __BASE_TEST_SV__
   `define __BASE_TEST_SV__

// class: base_test_c
class base_test_c extends uvm_test;
   `uvm_component_utils_begin(base_test_c)
      `uvm_field_object(cfg,       UVM_COMPONENT)
      `uvm_field_object(reg_block, UVM_COMPONENT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: cfg
   // The configuration class
   rand foo_pkg::cfg_c cfg;

   // var: reg_block
   // The register block
   csr_foo_pkg::reg_block_c reg_block;

   // var: clk_drv
   // The testbench clock driver
   cmn_pkg::clk_drv_c clk_drv;

   // var: rst_drv
   // The testbench reset driver
   cmn_pkg::rst_drv_c rst_drv;

   // var: env
   // The foo env
   foo_pkg::env_c env;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="base_test",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // Create the global environment
      global_pkg::env = global_pkg::env_c::type_id::create("global_env", this);

      // create the random configurations
      cfg = foo_pkg::cfg_c::type_id::create("cfg");

      // create reg_block
      if(reg_block == null) begin
         reg_block = csr_foo_pkg::reg_block_c::type_id::create("reg_block", this);
         reg_block.build();
         reg_block.lock_model();
      end

      // add reg_block to cfg class
      cfg.reg_block = reg_block;

      // randomize the cfg and CSR fields
      randomize_cfg();


      // populate environment's handle to cfg
      uvm_config_db#(uvm_object)::set(this, "env", "cfg", cfg);
      env = foo_pkg::env_c::type_id::create("env", this);

      // Create the clock and reset drivers
      clk_drv = cmn_pkg::clk_drv_c::type_id::create("clk_drv", this);
      uvm_config_db#(int)::set(this, "clk_drv", "period_ps", 2000);
      rst_drv = cmn_pkg::rst_drv_c::type_id::create("rst_drv", this);
      uvm_config_db#(int)::set(this, "rst_drv", "reset_time_ps", 20000);

      // set interface names
      uvm_config_db#(string)::set(this, "clk_drv", "intf_name", "clk_vi");
      uvm_config_db#(string)::set(this, "rst_drv", "intf_name", "rst_vi");
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: connect_phase
   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      // Connecting the map with the sequencer must be done after the build_phase
      reg_block.map.set_sequencer(env.agent.sqr, env.reg_adapter);
   endfunction : connect_phase

   ////////////////////////////////////////////
   // func: pre_reset_phase
   // re-randomize all of the test knobs during a reset if performing reset testing
   virtual task pre_reset_phase(uvm_phase phase);
      // randomize_cfg();
   endtask : pre_reset_phase

   ////////////////////////////////////////////
   // func: randomize_cfg
   // Descendent test classes can override this method to disable constraints, etc.
   virtual function void randomize_cfg();
      assert(randomize()) else
         `cmn_fatal(("Unable to randomize testbench"))
      cfg.sample_cg();
   endfunction : randomize_cfg
endclass : base_test_c

`endif // __BASE_TEST_SV__
