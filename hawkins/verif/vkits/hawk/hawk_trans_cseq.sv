
// ***********************************************************************
// File:   hawk_trans_cseq.sv
// Author: bhunter
/* About:  Chaining sequence for Transaction level.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_TRANS_CSEQ_SV__
   `define __HAWK_TRANS_CSEQ_SV__

`include "hawk_trans_item.sv"
`include "hawk_os_item.sv"
`include "hawk_types.sv"

typedef class trans_csqr_c;

// class: trans_cseq_c
// Sends transaction items to the link layer. Also receives inbound transaction items as responses
class trans_cseq_c extends cmn_pkg::cseq_c#(trans_item_c, trans_item_c,
                                            os_item_c, os_item_c,
                                            trans_csqr_c);
   `uvm_object_utils(hawk_pkg::trans_cseq_c)
   `uvm_declare_p_sequencer(trans_csqr_c)

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: outstanding_reads
   // All of the reads from the OS that are expecting a response, based on tag
   os_item_c outstanding_reads[tag_t];

   // var: outstanding_resp_tags
   // All incoming reads are pushed upstream. When the OS responds, match the address with the outstanding tag
   // and use that one
   tag_t outstanding_resp_tags[addr_t];

   // var: free_tags
   // A pool of free tags
   tag_t free_tags[$];

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="trans_cseq");
      super.new(name);

      // seed all free tags
      for(int tag=0; tag < 16; tag++)
         free_tags.push_back(tag);
      free_tags.shuffle();
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   // Prototype is what we want, no reason to override

   ////////////////////////////////////////////
   // func: handle_up_items
   // Retrieve transaction-level items from upstream and send them along
   virtual task handle_up_items();
      trans_item_c trans_item;
      os_item_c os_item;

      forever begin
         get_next_up_item(os_item);
         `cmn_dbg(200, ("RX from OS : %s", os_item.convert2string()))
         case(os_item.cmd)
            RD: begin
               // for reads, we must first get a free tag before the read can be done
               // once sent, we need to keep it as an outstanding read to be retired later
               tag_t read_tag;
               get_a_free_tag(read_tag);
               `uvm_create(trans_item)
               trans_item.uid = os_item.uid.new_subid("TRN");
               `uvm_rand_send_with(trans_item, {
                  tag == read_tag;
                  cmd == RD;
                  addr == os_item.addr;
               })
               outstanding_reads[read_tag] = os_item;
            end
            WR: begin
               // writes can just be done straightaway. Just give the trans-item
               // it's own unique sub-id
               `uvm_create(trans_item)
               trans_item.uid = os_item.uid.new_subid("TRN");
               `uvm_rand_send_with(trans_item, {
                  cmd == WR;
                  addr == os_item.addr;
                  data == os_item.data;
               })
            end
            RESP: begin
               // find the most tag and use that one
               tag_t my_tag = outstanding_resp_tags[os_item.addr];
               `uvm_do_with(trans_item, {
                  cmd == RESP;
                  addr == os_item.addr;
                  data == os_item.data;
                  tag == my_tag;
               })
               outstanding_resp_tags.delete(my_tag);
            end
         endcase
         `cmn_dbg(200, ("TX to   LNK: %s", trans_item.convert2string()))
      end
   endtask : handle_up_items

   ////////////////////////////////////////////
   // func: handle_down_traffic
   // Because send_read_response is a task, we cannot simply use create_up_rsp
   // and must instead override handle_down_traffic
   // This function handles all of the reads and writes, and only sends UP the responses
   // to reads from the OS level
   virtual task handle_down_traffic();
      trans_item_c down_traffic;
      os_item_c os_item;

      forever begin
         get_down_traffic(down_traffic);
         `cmn_dbg(200, ("RX from LNK: %s", down_traffic.convert2string()))

         case(down_traffic.cmd)
            RESP: begin
               if(outstanding_reads.exists(down_traffic.tag)) begin
                  os_item_c outstanding_read = outstanding_reads[down_traffic.tag];
                  outstanding_read.data = down_traffic.data;
                  put_up_response(outstanding_read);
                  outstanding_reads.delete(down_traffic.tag);
                  free_a_tag(down_traffic.tag);
               end else
                  `cmn_err(("TAG:%01X Received response with tag that does not match any outstanding reads.", down_traffic.tag))
            end
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
      wait(free_tags.size() > 0);
      _tag = free_tags.pop_front();
      `cmn_dbg(300, ("TAG:%01X Consumed", _tag))
   endtask : get_a_free_tag

   ////////////////////////////////////////////
   // func: free_a_tag
   // Frees up a tag for consumption
   virtual function void free_a_tag(tag_t _tag);
      free_tags.push_back(_tag);
      `cmn_dbg(300, ("TAG:%01X Freed", _tag))
   endfunction : free_a_tag

endclass : trans_cseq_c

`endif // __HAWK_TRANS_CSEQ_SV__

