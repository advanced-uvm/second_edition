
// ***********************************************************************
// File:   cmn_macros.sv
// Author: bhunter
/* About:  Common Macros
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
   *************************************************************************/

`ifndef __CMN_MACROS_SV__
 `define __CMN_MACROS_SV__

   `include "uvm_macros.svh"

   //----------------------------------------------------------------------------------------
   // Includes
   `include "cmn_msgs.sv"

////////////////////////////////////////////
// macro: `cmn_seq_raise
// Handy macro to ensure that all sequences raise the phase's objection if they are the default phase.
`ifdef UVM_MAJOR_VERSION_1_1
   `define cmn_seq_raise \
      begin \
         if(starting_phase) \
            starting_phase.raise_objection(this); \
      end
`endif // UVM_MAJOR_VERSION_1_1
`ifdef UVM_MAJOR_VERSION_1_2
   `define cmn_seq_raise \
      begin \
         if(get_starting_phase()) \
            get_starting_phase().raise_objection(this); \
      end
`endif // UVM_MAJOR_VERSION_1_2

////////////////////////////////////////////
// macro: `cmn_seq_drop
// Handy macro to ensure that all sequences drop the phase's objection if they are the default phase.
`ifdef UVM_MAJOR_VERSION_1_1
   `define cmn_seq_drop \
      begin \
         if(starting_phase) \
            starting_phase.drop_objection(this); \
      end
`endif // UVM_MAJOR_VERSION_1_1
`ifdef UVM_MAJOR_VERSION_1_2
   `define cmn_seq_drop \
      begin \
         if(get_starting_phase()) \
            get_starting_phase().drop_objection(this); \
      end
`endif // UVM_MAJOR_VERSION_1_2

////////////////////////////////////////////
// macro: `cmn_set_intf
   `define cmn_set_intf(TYPE, RSRC, NAME, INSTANCE) \
      begin \
         uvm_resource_db#(TYPE)::set(RSRC, NAME, INSTANCE); \
      end

////////////////////////////////////////////
// macro: `cmn_get_intf
   `define cmn_get_intf(TYPE, RSRC, NAME, VARIABLE) \
      begin \
         if(!uvm_resource_db#(TYPE)::read_by_name(RSRC, NAME, VARIABLE)) \
            `cmn_err(("%s.%s interface not found in resource database.", RSRC, NAME)); \
      end

`endif // __CMN_MACROS_SV__