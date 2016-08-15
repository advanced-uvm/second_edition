
// ***********************************************************************
// File:   hawk_trans_item.sv
// Author: bhunter
/* About:  Transaction-Level Items
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_TRANS_ITEM_SV__
   `define __HAWK_TRANS_ITEM_SV__

`include "hawk_types.sv"

// class: trans_item_c
// A transical level item
class trans_item_c extends uvm_sequence_item;
   `uvm_object_utils_begin(hawk_pkg::trans_item_c)
      `uvm_field_int(tag,            UVM_DEFAULT | UVM_HEX)
      `uvm_field_enum(trans_cmd_e, cmd,UVM_DEFAULT)
      `uvm_field_int(addr,           UVM_DEFAULT | UVM_HEX | UVM_NOPACK)
      `uvm_field_int(data,           UVM_DEFAULT | UVM_HEX | UVM_NOPACK)
   `uvm_object_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: uid
   // Unique ID
   cmn_pkg::uid_c uid;

   // var: tag
   // transaction tag number
   rand tag_t tag;

   // var: cmd
   // The transical command
   rand trans_cmd_e cmd;

   // constraint: tag_cnstr
   // When sending a write, tag must be zero
   constraint tag_cnstr {
      cmd == WR -> tag == 0;
   }

   // var: addr
   // The 64-bit address
   rand addr_t addr;

   // var: data
   // The 64-bit data
   rand data_t data;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="trans_item");
      super.new(name);
      uid = new("TRN");
   endfunction : new

   ////////////////////////////////////////////
   // func: convert2string
   // Single-line printing
   virtual function string convert2string();
      convert2string = {uid.convert2string(), " ", cmd.name()};
      case(cmd)
         RD  : convert2string = $sformatf("%s TAG:%01x ADDR:%016X", convert2string, tag, addr);
         WR  : convert2string = $sformatf("%s ADDR:%016X DATA:%016X", convert2string, addr, data);
         RESP : convert2string = $sformatf("%s TAG:%01x DATA:%016X", convert2string, tag, data);
      endcase
   endfunction : convert2string

   ////////////////////////////////////////////
   // func: do_pack
   // Conditionally pack the address and/or data
   virtual function void do_pack(uvm_packer packer);
      super.do_pack(packer);
      if(cmd inside {RD, WR})
         `uvm_pack_int(addr)
      if(cmd inside {WR, RESP})
         `uvm_pack_int(data)
   endfunction : do_pack

   ////////////////////////////////////////////
   // func: do_unpack
   // Unpack a stream into this
   virtual function void do_unpack(uvm_packer packer);
      super.do_unpack(packer);
      if(cmd inside {RD, WR})
         `uvm_unpack_int(addr)
      if(cmd inside {WR, RESP})
         `uvm_unpack_int(data)
   endfunction : do_unpack

endclass : trans_item_c

`endif // __HAWK_TRANS_ITEM_SV__


