
// ***********************************************************************
// File:   hawk_env.sv
// Author: bhunter
/* About:  Creates an rx and tx agent that run independently.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_ENV_SV__
   `define __HAWK_ENV_SV__

`include "hawk_agent.sv"
`include "hawk_drv.sv"
`include "hawk_passive_drv.sv"

// class: env_c
class env_c extends uvm_env;
   `uvm_component_utils_begin(hawk_pkg::env_c)
      `uvm_field_object(cfg, UVM_REFERENCE)
      `uvm_field_int(phy_enable, UVM_DEFAULT)
      `uvm_field_int(link_enable, UVM_DEFAULT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: cfg
   // The hawk cfg knobs class
   cfg_c cfg;

   // var: phy_enable
   // When set, phy csqr, drivers, and monitors will be present
   bit phy_enable = 1;

   // var: link_enable
   // When link csqr is present.
   bit link_enable = 1;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: rx_agent, tx_agent
   // The hawk rx_agent & tx_agent
   agent_c rx_agent, tx_agent;

   // var: rx_mem, tx_mem
   // Memories for RX and TX
   mem_c rx_mem, tx_mem;

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
      uvm_config_db#(uvm_object)::set(this, "*", "cfg", cfg);
      uvm_config_db#(int)::set(this, "*", "phy_enable", phy_enable);
      uvm_config_db#(int)::set(this, "*", "link_enable", link_enable);

      tx_agent = agent_c::type_id::create("rx_agent", this);
      rx_agent = agent_c::type_id::create("tx_agent", this);
      tx_mem = mem_c::type_id::create("rx_mem", this);
      rx_mem = mem_c::type_id::create("tx_mem", this);

      // distribute memories to each agent's os sqr
      uvm_config_db#(uvm_object)::set(this, "rx_agent.os_sqr", "mem", rx_mem);
      uvm_config_db#(uvm_object)::set(this, "tx_agent.os_sqr", "mem", tx_mem);

      // distribute link_chain_break delays whenever phy_enable is zero but link_enable is 1
      if(phy_enable == 0 && link_enable == 1) begin
         uvm_config_db#(uvm_object)::set(this, "rx_agent.link_csqr", "rand_delays", cfg.rx_link_chain_break_delays);
         uvm_config_db#(uvm_object)::set(this, "tx_agent.link_csqr", "rand_delays", cfg.tx_link_chain_break_delays);
      end
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: connect_phase
   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if(rx_agent.mon_item_port && tx_agent.inb_item_export)
         rx_agent.mon_item_port.connect(tx_agent.inb_item_export);
      if(tx_agent.mon_item_port && rx_agent.inb_item_export)
         tx_agent.mon_item_port.connect(rx_agent.inb_item_export);

      if(!link_enable) begin
         rx_agent.trans_csqr.down_seq_item_port.connect(tx_agent.trans_csqr.seq_item_export);
         tx_agent.trans_csqr.down_seq_item_port.connect(rx_agent.trans_csqr.seq_item_export);
      end else if(!phy_enable) begin
         rx_agent.link_csqr.down_seq_item_port.connect(tx_agent.link_csqr.seq_item_export);
         tx_agent.link_csqr.down_seq_item_port.connect(rx_agent.link_csqr.seq_item_export);
      end
   endfunction : connect_phase
endclass : env_c

`endif // __HAWK_ENV_SV__

