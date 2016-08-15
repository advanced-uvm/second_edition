
// ***********************************************************************
// File:   hawk_passive_trans_cseq.sv
// Author: bhunter
/* About:  Chaining sequence for Transaction level.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_PASSIVE_TRANS_CSEQ_SV__
   `define __HAWK_PASSIVE_TRANS_CSEQ_SV__

`include "hawk_trans_cseq.sv"

// class: passive_trans_cseq_c
// Sends transaction items to the link layer. Also receives inbound transaction items as responses
class passive_trans_cseq_c extends trans_cseq_c;
   `uvm_object_utils(hawk_pkg::passive_trans_cseq_c)
   `uvm_declare_p_sequencer(trans_csqr_c)

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="passive_trans_cseq");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   // Prototype is what we want, no reason to override

   ////////////////////////////////////////////
   // func: handle_up_items
   // Retrieve transaction-level items from upstream and send them along
   virtual task handle_up_items();
      // trans_item_c trans_item;
      // os_item_c os_item;

      // forever begin
      //    get_next_up_item(os_item);
      //    `cmn_dbg(200, ("RX from OS : %s", os_item.convert2string()))
      //    case(os_item.cmd)
      //       RD: begin
      //          // for reads, we must first get a free tag before the read can be done
      //          // once sent, we need to keep it as an outstanding read to be retired later
      //          tag_t read_tag;
      //          get_a_free_tag(read_tag);
      //          `uvm_create(trans_item)
      //          trans_item.uid = os_item.uid.new_subid("TRN");
      //          `uvm_rand_send_with(trans_item, {
      //             tag == read_tag;
      //             cmd == RD;
      //             addr == os_item.addr;
      //          })
      //          outstanding_reads[read_tag] = os_item;
      //       end
      //       WR: begin
      //          // writes can just be done straightaway. Just give the trans-item
      //          // it's own unique sub-id
      //          `uvm_create(trans_item)
      //          trans_item.uid = os_item.uid.new_subid("TRN");
      //          `uvm_rand_send_with(trans_item, {
      //             cmd == WR;
      //             addr == os_item.addr;
      //             data == os_item.data;
      //          })
      //       end
      //       RESP: begin
      //          // find the most tag and use that one
      //          tag_t my_tag = outstanding_resp_tags[os_item.addr];
      //          `uvm_do_with(trans_item, {
      //             cmd == RESP;
      //             addr == os_item.addr;
      //             data == os_item.data;
      //             tag == my_tag;
      //          })
      //          outstanding_resp_tags.delete(my_tag);
      //       end
      //    endcase
      //    `cmn_dbg(200, ("TX to   LNK: %s", trans_item.convert2string()))
      // end
   endtask : handle_up_items

   ////////////////////////////////////////////
   // func: handle_down_traffic
   // Merely watch all downstream traffic.
   virtual task handle_down_traffic();
      trans_item_c down_traffic;
      os_item_c os_item;

      forever begin
         get_down_traffic(down_traffic);
         `cmn_dbg(200, ("RX from LNK: %s", down_traffic.convert2string()))

         case(down_traffic.cmd)
            default: begin
               os_item = os_item_c::type_id::create("os_item");
               os_item.uid = down_traffic.uid.new_subid("OS");
               os_item.cmd = down_traffic.cmd;
               os_item.addr = down_traffic.addr;
               os_item.data = down_traffic.data;
               outstanding_resp_tags[down_traffic.addr] = down_traffic.tag;
               put_up_traffic(os_item);
            end
         endcase

      end
   endtask : handle_down_traffic

   ////////////////////////////////////////////
   // func: get_a_free_tag
   // Get a tag. Block if none are available
   virtual task get_a_free_tag(ref tag_t _tag);
   endtask : get_a_free_tag

   ////////////////////////////////////////////
   // func: free_a_tag
   // Frees up a tag for consumption
   virtual function void free_a_tag(tag_t _tag);
   endfunction : free_a_tag

endclass : passive_trans_cseq_c

`endif // __HAWK_PASSIVE_TRANS_CSEQ_SV__

