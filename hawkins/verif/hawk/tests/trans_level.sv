
// ***********************************************************************
// File:   trans_level.sv
// Author: bhunter
/* About:  Run test with neither the PHY nor the LINK level sequences populated.
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
   *************************************************************************/

`ifndef __TRANS_LEVEL_SV__
   `define __TRANS_LEVEL_SV__

   `include "basic.sv"

// class: trans_level_test_c
class trans_level_test_c extends basic_test_c;
   `uvm_component_utils(trans_level_test_c)

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="trans_level",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_config_db#(int)::set(this, "hawk_env", "link_enable", 0);
   endfunction : build_phase

endclass : trans_level_test_c

`endif // __TRANS_LEVEL_SV__

