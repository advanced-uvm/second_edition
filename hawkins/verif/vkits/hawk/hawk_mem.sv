
// ***********************************************************************
// File:   hawk_mem.sv
// Author: bhunter
/* About:  Contains the memory of an agent.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_MEM_SV__
   `define __HAWK_MEM_SV__

`include "hawk_types.sv"

// class: mem
// Just holds a memory. More advanced stuff if you need it.
class mem_c extends uvm_component;
   `uvm_component_utils_begin(hawk_pkg::mem_c)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: memory
   // The actual memory values of this node. May be written to or read from.
   data_t memory[addr_t];

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="mem",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new
endclass : mem_c

`endif // __HAWK_MEM_SV__

