
// ***********************************************************************
// File:   bad_crc.sv
// Author: bhunter
/* About:  Enable Bad CRC generation.
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
   *************************************************************************/

`ifndef __BAD_CRC_SV__
   `define __BAD_CRC_SV__

   `include "basic.sv"

// class: bad_crc_test_c
class bad_crc_test_c extends basic_test_c;
   `uvm_component_utils_begin(bad_crc_test_c)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Constraints

   // constraint: bad_crc_pct_cnstr
   // Allow bad CRC's at a 5% rate
   constraint bad_crc_pct_cnstr {
      cfg.bad_crc_pct == 5;
   }

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="bad_crc",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: randomize_cfg
   // Disable the L2_bad_crc_pct constraint
   virtual function void randomize_cfg();
      cfg.L2_bad_crc_pct_cnstr.constraint_mode(0);
      super.randomize_cfg();
   endfunction : randomize_cfg

endclass : bad_crc_test_c

`endif // __BAD_CRC_SV__

