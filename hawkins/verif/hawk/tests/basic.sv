
// ***********************************************************************
// File:   basic.sv
// Author: bhunter
/* About:  Basic test extends the base test and starts a training sequence
           on both the RX and TX agent. This is done here to show that
           numerous sequences can be started independently on a chaining
           sequencer.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __BASIC_SV__
   `define __BASIC_SV__

   `include "base_test.sv"

// class: basic_test_c
class basic_test_c extends base_test_c;
   `uvm_component_utils_begin(basic_test_c)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="<name>",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new
endclass : basic_test_c

`endif // __BASIC_SV__

