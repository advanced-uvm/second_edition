
// ***********************************************************************
// File:   passive.sv
// Author: bhunter
/* About:  Adds a passive agent to the environment.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __PASSIVE_SV__
   `define __PASSIVE_SV__

   `include "basic.sv"

// class: passive_test_c
class passive_test_c extends basic_test_c;
   `uvm_component_utils(passive_test_c)

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: passive_hawk_env
   // Passively watches the same hawk interface
   hawk_pkg::env_c passive_hawk_env;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="passive",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   // Do not enable the phy level stuff.
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // create a passive environment
      passive_hawk_env = hawk_pkg::env_c::type_id::create("passive_hawk_env", this);
      uvm_config_db#(uvm_object)::set(this, "passive_hawk_env", "cfg", cfg);

      // set the interfaces
      uvm_config_db#(string)::set(this, "passive_hawk_env.tx_agent.*", "intf_name", "hawk_tx_vi");
      uvm_config_db#(string)::set(this, "passive_hawk_env.rx_agent.*", "intf_name", "hawk_rx_vi");

      // use these chaining sequences
      uvm_config_db#(uvm_object_wrapper)::set(this, "passive_hawk_env.*_agent.phy_csqr.run_phase", "default_sequence", hawk_pkg::phy_cseq_c::type_id::get());
      uvm_config_db#(uvm_object_wrapper)::set(this, "passive_hawk_env.*_agent.link_csqr.run_phase", "default_sequence", hawk_pkg::link_cseq_c::type_id::get());
      uvm_config_db#(uvm_object_wrapper)::set(this, "passive_hawk_env.*_agent.trans_csqr.run_phase", "default_sequence", hawk_pkg::passive_trans_cseq_c::type_id::get());

      // the passive environment will only use the passive version of the driver
      set_inst_override_by_type("passive_hawk_env.rx_agent.drv", hawk_pkg::drv_c::get_type(), hawk_pkg::passive_drv_c::get_type());
      set_inst_override_by_type("passive_hawk_env.tx_agent.drv", hawk_pkg::drv_c::get_type(), hawk_pkg::passive_drv_c::get_type());
   endfunction : build_phase

endclass : passive_test_c

`endif // __PASSIVE_SV__

