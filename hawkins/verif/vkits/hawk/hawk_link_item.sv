
// ***********************************************************************
// File:   hawk_link_item.sv
// Author: bhunter
/* About:  Link-level Sequence Items.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_LINK_ITEM_SV__
   `define __HAWK_LINK_ITEM_SV__

`include "hawk_types.sv"

// class: link_item_c
class link_item_c extends uvm_sequence_item;
   `uvm_object_utils_begin(hawk_pkg::link_item_c)
      `uvm_field_enum(phy_char_e, phy_char,UVM_DEFAULT | UVM_NOPACK)
      `uvm_field_int(link_id,              UVM_DEFAULT | UVM_HEX | UVM_NOPACK)
      `uvm_field_object(trans_item,        UVM_DEFAULT | UVM_NOPACK)
      `uvm_field_int(crc,                  UVM_DEFAULT | UVM_HEX | UVM_NOPACK)
      `uvm_field_int(corrupt_crc,          UVM_DEFAULT | UVM_NOPACK | UVM_HEX | UVM_NOCOMPARE)
   `uvm_object_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: uid
   // Unique ID
   cmn_pkg::uid_c uid;

   // var: phy_char
   // When set to anything but PKT, this is what is sent instead
   rand phy_char_e phy_char;

   // constraint: phy_char_cnstr
   // Cannot be an idle or training. Link layer doesn't deal with these
   constraint phy_char_cnstr {
      phy_char != IDLE;
      phy_char != TRAIN;
   }

   // var: link_id
   // The LINK ID
   rand byte unsigned link_id;

   // var: trans_item
   // The transaction item that this link item encloses (if any)
   trans_item_c trans_item;

   // var: crc
   // The CRC enclosing this transaction item
   byte unsigned crc;

   // var: corrupt_crc
   // Set to 1 to corrupt the CRC
   rand bit corrupt_crc;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="link");
      super.new(name);
      uid = new("LNK");
   endfunction : new

   ////////////////////////////////////////////
   // func: post_randomize
   // Set CRC
   function void post_randomize();
      crc = calc_crc();
   endfunction : post_randomize

   ////////////////////////////////////////////
   // func: calc_crc
   // Returns the 8-bit CRC, if trans_item is set. Otherwise returns 0
   virtual function byte unsigned calc_crc();
      if(trans_item == null)
         calc_crc = 8'b0;
      else if(corrupt_crc) begin
         std::randomize(calc_crc);
      end else begin
         calc_crc = {trans_item.tag, tag_t'(trans_item.cmd)};
         if(trans_item.cmd inside {RD, WR})
            for(int idx=0; idx < 8; idx++)
               calc_crc += trans_item.addr[63-8*idx -: 8];
         if(trans_item.cmd inside {WR, RESP})
            for(int idx=0; idx < 8; idx++)
               calc_crc += trans_item.data[63-8*idx -: 8];
         `cmn_dbg(400, ("Calculated CRC = %02X from %s", calc_crc, trans_item.convert2string()))
      end
   endfunction : calc_crc

   ////////////////////////////////////////////
   // func: convert2string
   // Single-line printing
   virtual function string convert2string();
      case(phy_char)
         ACK, NAK: convert2string = phy_char.name();
         PKT: begin
            convert2string = $sformatf("%s LINK_ID:%02X CRC:%02X PKT:%s", uid.convert2string(),
                                       link_id, crc, trans_item.convert2string());
            if(corrupt_crc)
               convert2string = {convert2string, " BAD_CRC"};
         end
         default: begin
            `cmn_err(("Link should never see IDLEs, EOP, or TRAIN."))
            return "";
         end
      endcase
   endfunction : convert2string

   ////////////////////////////////////////////
   // func: do_pack
   // Pack a link-level item into a stream
   virtual function void do_pack(uvm_packer packer);
      if(phy_char == PKT) begin
         `uvm_pack_int(link_id)
         packer.pack_object(trans_item);
         `uvm_pack_int(crc)
      end else begin
         `uvm_pack_enum(phy_char)
      end
   endfunction : do_pack

   ////////////////////////////////////////////
   // func: do_unpack
   // Unpack a stream of bits into this item. Only full packets
   // be unpacked
   virtual function void do_unpack(uvm_packer packer);
      phy_char = PKT; // TODO: This is a hack
      super.do_unpack(packer);
      `uvm_unpack_int(link_id)
      trans_item = trans_item_c::type_id::create("trans_item");
      packer.unpack_object(trans_item);
      `uvm_unpack_int(crc)
   endfunction : do_unpack

endclass : link_item_c

`endif // __HAWK_LINK_ITEM_SV__


