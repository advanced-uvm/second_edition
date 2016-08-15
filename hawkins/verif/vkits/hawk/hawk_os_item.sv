
// ***********************************************************************
// File:   hawk_os_item.sv
// Author: bhunter
/* About:  The Operating System level items that go into the transaction level
           These describe either a read or a write. They are intentionally
           generic.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_OS_ITEM_SV__
   `define __HAWK_OS_ITEM_SV__

// class: os_item_c
class os_item_c extends uvm_sequence_item;
   `uvm_object_utils_begin(hawk_pkg::os_item_c)
      `uvm_field_enum(trans_cmd_e, cmd, UVM_DEFAULT)
      `uvm_field_int(addr, UVM_DEFAULT | UVM_HEX)
      `uvm_field_int(data, UVM_DEFAULT | UVM_HEX)
   `uvm_object_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: uid
   // Unique ID
   cmn_pkg::uid_c uid;

   // var: cmd
   // The command is either a read, write, or response
   rand trans_cmd_e cmd;

   // var: addr
   // The 64-bit address
   rand addr_t addr;

   // var: data
   // 64-bit data
   rand data_t data;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="os");
      super.new(name);
      uid = new("OS");
   endfunction : new

   ////////////////////////////////////////////
   // func: convert2string
   // Single-line printing
   virtual function string convert2string();
      convert2string = $sformatf("%s %s ADDR:%016X", uid.convert2string(), cmd.name(), addr);
      if(cmd inside {WR, RESP})
         convert2string = {convert2string, $sformatf(" DATA:%016X", data)};
   endfunction : convert2string

endclass : os_item_c

`endif // __HAWK_OS_ITEM_SV__


