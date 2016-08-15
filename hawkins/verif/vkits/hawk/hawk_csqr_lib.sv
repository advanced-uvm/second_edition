
// ***********************************************************************
// File:   hawk_csqr_lib.sv
// Author: bhunter
/* About:  Contains types of chained sequencers used by the hawkins
           package.

   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_SQR_LIB_SV__
   `define __HAWK_SQR_LIB_SV__

typedef class link_item_c;
typedef class phy_item_c;
typedef class trans_item_c;
typedef class os_item_c;
typedef class cfg_c;

//****************************************************************************************
// class: phy_csqr_c
// A chaining sequencer that operates at the PHY level
class phy_csqr_c extends cmn_pkg::csqr_c#(link_item_c, link_item_c,
                                         phy_item_c, phy_item_c);
   `uvm_component_utils(hawk_pkg::phy_csqr_c)

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="phy_csqr",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new
endclass : phy_csqr_c

//****************************************************************************************
// class: link_csqr_c
// A chaining sequencer that operates at the LINK level
class link_csqr_c extends cmn_pkg::csqr_c#(trans_item_c, trans_item_c,
                                          link_item_c, link_item_c);
   `uvm_component_utils_begin(hawk_pkg::link_csqr_c)
      `uvm_field_object(cfg, UVM_DEFAULT)
      `uvm_field_object(rand_delays, UVM_DEFAULT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: cfg
   // The cfg class
   cfg_c cfg;

   // var: rand_delays
   // Provides a random delay
   cmn_pkg::rand_delays_c rand_delays;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="link_csqr",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: down_traffic_user_task
   // When the PHY level is disabled, a random delay between 5 and 30ns is added to
   // simulate phy-level activity
   virtual task down_traffic_user_task(ref DOWN_TRAFFIC _down_traffic);
      cmn_pkg::rand_delays_c::delay_t delay;

      // wait for a random delay period
      delay = rand_delays.get_next_delay();
      `cmn_info(("Waiting %0d ns", delay))
      #(delay * 1ns);
      `cmn_info(("Done waiting"))
   endtask : down_traffic_user_task
endclass : link_csqr_c

//****************************************************************************************
// class: trans_csqr_c
// A chaining sequencer that operates at the TRANS level
class trans_csqr_c extends cmn_pkg::csqr_c#(os_item_c, os_item_c,
                                         trans_item_c, trans_item_c);
   `uvm_component_utils(hawk_pkg::trans_csqr_c)

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="trans_csqr",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new
endclass : trans_csqr_c

`endif // __HAWK_SQR_LIB_SV__

