
// ***********************************************************************
// File:   hawk_cfg.sv
// Author: bhunter
/* About:  Knobs for hawk vkit.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_CFG_SV__
   `define __HAWK_CFG_SV__

// class: cfg_c
class cfg_c extends uvm_object;
   `uvm_object_utils_begin(hawk_pkg::cfg_c)
      `uvm_field_int(coverage_enable, UVM_ALL_ON)
      `uvm_field_int(nak_pct,         UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(bad_crc_pct,     UVM_DEFAULT | UVM_DEC)
      `uvm_field_object(rx_link_chain_break_delays, UVM_DEFAULT)
      `uvm_field_object(tx_link_chain_break_delays, UVM_DEFAULT)
   `uvm_object_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: coverage_enable
   // Is functional coverage collection enabled?
   int coverage_enable;

   // var: nak_pct
   // The percentage of packets received by the link layer that will be NAK'ed.
   rand int unsigned nak_pct;

   // constraint: L0_nak_pct_cnstr
   // Keep NAK betweek 0-100
   constraint L0_nak_pct_cnstr {
      nak_pct inside {[0:100]};
   }

   // constraint: L1_nak_pct_cnstr
   // Keep NAK low
   constraint L1_nak_pct_cnstr {
      nak_pct inside {[0:10]};
   }

   // constraint: L2_nak_pct_cnstr
   // Turn it off altogether
   constraint L2_nak_pct_cnstr {
      nak_pct == 0;
   }

   // var: bad_crc_pct
   // Percentage of time that BAD CRC should be sent
   rand int unsigned bad_crc_pct;

   // constraint: L0_bad_crc_pct_cnstr
   // Keep between 0 and 100
   constraint L0_bad_crc_pct_cnstr {
      bad_crc_pct inside {[0:100]};
   }

   // constraint: L1_bad_crc_pct_cnstr
   // Keep it small
   constraint L1_bad_crc_pct_cnstr {
      bad_crc_pct inside {[0:10]};
   }

   // constraint: L2_bad_crc_pct_cnstr
   // Turn it off
   constraint L2_bad_crc_pct_cnstr {
      bad_crc_pct == 0;
   }

   // var: tx_link_chain_break_delays, rx_link_chain_break_delays
   // A random time delay meant to simulate the time it takes for transactions to be
   // processed by the physical layer. Used by the link_csqr_c class.
   rand cmn_pkg::rand_delays_c tx_link_chain_break_delays, rx_link_chain_break_delays;

   // constraint: L0_link_chain_break_delays_cnstr
   // Basic min and max delays
   constraint L0_link_chain_break_delays_cnstr {
      rx_link_chain_break_delays.min_delay == 1;
      rx_link_chain_break_delays.max_delay == 100;
      tx_link_chain_break_delays.min_delay == 1;
      tx_link_chain_break_delays.max_delay == 100;
   }

   // constraint: L1_link_chain_break_delays_cnstr
   // ensure that it never waits for 0ns. This is not realistic
   constraint L1_link_chain_break_delays_cnstr {
      rx_link_chain_break_delays.traffic_type == cmn_pkg::rand_delays_c::REGULAR;
      tx_link_chain_break_delays.traffic_type == cmn_pkg::rand_delays_c::REGULAR;
   }

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="[name]");
      super.new(name);
      if(coverage_enable)
         cg = new();

      // create delay objects, whether they'll be used or not
      tx_link_chain_break_delays = cmn_pkg::rand_delays_c::type_id::create("tx_link_chain_break_delays");
      rx_link_chain_break_delays = cmn_pkg::rand_delays_c::type_id::create("rx_link_chain_break_delays");
   endfunction : new

   ////////////////////////////////////////////
   // func: sample_cg
   // Sample the covergroup if functional coverage is enabled
   virtual function void sample_cg();
      if(cg)
         cg.sample();
   endfunction : sample_cg

   //----------------------------------------------------------------------------------------
   // Group: Functional Coverage

   // prop: cg
   // Covergroup for configuration options
   covergroup cg;
      coverpoint nak_pct {
         bins disabled = {0};
         bins enabled  = {[1:100]};
      }
      coverpoint bad_crc_pct {
         bins disabled = {0};
         bins enabled  = {[1:100]};
      }
   endgroup : cg

endclass : cfg_c

`endif // __HAWK_CFG_SV__

