
// ***********************************************************************
// File:   hawk_phy_cseq.sv
// Author: bhunter
/* About:  Chaining sequence receives link items and transmits phy items
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_PHY_CSEQ_SV__
   `define __HAWK_PHY_CSEQ_SV__

`include "hawk_link_item.sv"
`include "hawk_phy_item.sv"
`include "hawk_phy_idle_seq.sv"
`include "hawk_phy_train_seq.sv"

typedef class phy_csqr_c;

// class: phy_cseq_c
class phy_cseq_c extends cmn_pkg::cseq_c#(phy_item_c, phy_item_c,
                                          link_item_c, link_item_c,
                                          phy_csqr_c);
   `uvm_object_utils(hawk_pkg::phy_cseq_c)

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="phy_cseq");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   virtual task body();
      phy_idle_seq_c phy_idle_seq;
      phy_train_seq_c phy_train_seq;

      fork
         handle_up_items();
         `uvm_do(phy_idle_seq)
         `uvm_do(phy_train_seq)
         handle_down_traffic();
      join
   endtask : body

   ////////////////////////////////////////////
   // func: handle_up_items
   // Send the link items coming from upstream
   // Because each link item converts to more than 1 phy item,
   // we cannot simply override make_down_req
   virtual task handle_up_items();
      link_item_c link_item;
      phy_item_c phy_item;

      forever begin
         // fetch the next upstream link packet to send
         get_next_up_item(link_item);

         `cmn_dbg(200, ("RX from LNK: %s", link_item.convert2string()))
         if(link_item.phy_char == PKT) begin
            byte unsigned stream[];
            link_item.pack_bytes(stream);
            foreach(stream[idx]) begin
               `uvm_create(phy_item)
               phy_item.uid = link_item.uid.new_subid("PHY");
               phy_item.valid = 1;
               phy_item.data = stream[idx];
               `uvm_send_pri(phy_item, PKT_PRI)
               `cmn_dbg(200, ("TX to   DRV: %s", phy_item.convert2string()))
            end
            `uvm_create(phy_item)
            phy_item.uid = link_item.uid.new_subid("PHY");
            phy_item.valid = 0;
            phy_item.data = EOP;
            `uvm_send_pri(phy_item, PKT_PRI)
         end else begin
            // otherwise send the PHY character (ACK or NAK)
            phy_item_c phy_item;
            `uvm_create(phy_item)
            phy_item.uid = link_item.uid.new_subid("PHY");
            `uvm_rand_send_pri_with(phy_item, ACK_NAK_PRI, {
               valid == link_item.phy_char[8];
               data == link_item.phy_char[7:0];
            })
            `cmn_dbg(200, ("TX to   DRV: %s", phy_item.convert2string()))
         end
      end
   endtask : handle_up_items

   ////////////////////////////////////////////
   // func: handle_down_traffic
   // Pull phy items from sequencer. Filter out idles and training.
   // from the rest, pack up as link_items and send as upstream traffic
   virtual task handle_down_traffic();
      link_item_c up_item;
      phy_item_c pkt_items[$];
      phy_item_c down_traffic;

      forever begin
         get_down_traffic(down_traffic);
         `cmn_dbg(200, ("RX from DRV: %s", down_traffic.convert2string()))

         // if it's either IDLE or training, then toss it on the floor
         if(down_traffic.is_idle_or_train())
            continue;

         if(down_traffic.valid == 1)
            pkt_items.push_back(down_traffic);
         else if(down_traffic.data == EOP) begin
            // create a link item out of all the pkt_items in the queue
            up_item = make_link_item(pkt_items);
            pkt_items.delete();
            // send upstream
            put_up_traffic(up_item);
         end else begin
            up_item = link_item_c::type_id::create("up_item");
            up_item.phy_char = {down_traffic.valid, down_traffic.data};
            put_up_traffic(up_item);
         end
      end
   endtask : handle_down_traffic

   ////////////////////////////////////////////
   // func: make_link_item
   // Pack up phy items into a link item
   virtual function link_item_c make_link_item(ref phy_item_c _items[$]);
      byte unsigned stream[];
      make_link_item = link_item_c::type_id::create("make_link_item");
      stream = new[_items.size()];
      foreach(_items[idx])
         stream[idx] = _items[idx].data;
      make_link_item.unpack_bytes(stream);
      make_link_item.corrupt_crc = 0;
   endfunction : make_link_item
endclass : phy_cseq_c

`endif // __HAWK_PHY_CSEQ_SV__

