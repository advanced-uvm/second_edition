
// ***********************************************************************
// File:   cmn_cseq.sv
// Author: bhunter
/* About:  Chaining Sequence Base Class
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __CMN_CSEQ_SV__
   `define __CMN_CSEQ_SV__

`include "cmn_csqr.sv"

//****************************************************************************************
// class: cseq_c
// A parameterizable base class for chaining sequences.
class cseq_c#(type DOWN_REQ=uvm_sequence_item,
              DOWN_TRAFFIC=DOWN_REQ,
              UP_REQ=DOWN_REQ,
              UP_TRAFFIC=DOWN_REQ,
              CSQR=cmn_pkg::csqr_c)
              extends uvm_sequence#(DOWN_REQ);

   `uvm_object_utils_begin(cmn_pkg::cseq_c)
   `uvm_object_utils_end
   `uvm_declare_p_sequencer(CSQR)

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="cseq_seq");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   virtual task body();
      fork
         handle_up_items();
         handle_down_traffic();
      join
   endtask : body

   ////////////////////////////////////////////
   // func: handle_up_items
   // Get items from the upstream chained sequencer and send them as downstream items
   virtual task handle_up_items();
      UP_REQ up_req_item;
      DOWN_REQ down_req_item;

      forever begin
         get_next_up_item(up_req_item);
         `uvm_create(down_req_item)
         make_down_req(down_req_item, up_req_item);
         `uvm_send(down_req_item)
      end
   endtask : handle_up_items

   ////////////////////////////////////////////
   // func: handle_down_traffic
   // Get traffic from downstream, create upstream traffic, and push it up
   virtual task handle_down_traffic();
      DOWN_TRAFFIC down_traffic;
      UP_TRAFFIC up_traffic;

      forever begin
         get_down_traffic(down_traffic);
         up_traffic = create_up_traffic(down_traffic);
         if(up_traffic)
            put_up_traffic(up_traffic);
      end
   endtask : handle_down_traffic

   ////////////////////////////////////////////
   // func: get_next_up_item
   // Get the next upstream item request
   virtual task get_next_up_item(ref UP_REQ _item);
      p_sequencer.up_seq_item_fifo.get(_item);
   endtask : get_next_up_item

   ////////////////////////////////////////////
   // func: try_get_next_up_item
   // Returns a 1 if an upstream item was available, otherwise returns 0
   virtual function bit try_get_next_up_item(ref UP_REQ _item);
      try_get_next_up_item = p_sequencer.up_seq_item_fifo.try_get(_item);
   endfunction : try_get_next_up_item

   ////////////////////////////////////////////
   // func: put_up_traffic
   // Send traffic upstream.
   virtual function void put_up_traffic(UP_TRAFFIC _up_traffic);
      p_sequencer.up_traffic_port.write(_up_traffic);
   endfunction : put_up_traffic

   ////////////////////////////////////////////
   // func: put_up_response
   // Send a response upstream using the sequence item port
   virtual function void put_up_response(UP_TRAFFIC _up_traffic);
      p_sequencer.up_seq_item_port.put_response(_up_traffic);
   endfunction : put_up_response

   ////////////////////////////////////////////
   // func: try_get_down_traffic
   // Returns a 1 if any downstream traffic item was available, otherwise returns 0
   // Fills in the _traffic
   virtual function bit try_get_down_traffic(ref DOWN_TRAFFIC _traffic);
      return p_sequencer.down_traffic_fifo.try_get(_traffic);
   endfunction : try_get_down_traffic

   ////////////////////////////////////////////
   // func: get_down_traffic
   // Return the next available piece of traffic from downstream
   virtual task get_down_traffic(ref DOWN_TRAFFIC _down_traffic);
      p_sequencer.down_traffic_fifo.get(_down_traffic);
   endtask : get_down_traffic

   ////////////////////////////////////////////
   // func: make_down_req
   // make a downstream request item from an upstream request item
   virtual function DOWN_REQ make_down_req(ref DOWN_REQ _down_req_item,
                                               UP_REQ _up_req_item);
   endfunction : make_down_req

   ////////////////////////////////////////////
   // func: create_up_traffic
   // Create an upstream traffic item from the downstream traffic
   virtual function UP_TRAFFIC create_up_traffic(ref DOWN_TRAFFIC _down_traffic);
   endfunction : create_up_traffic
endclass : cseq_c

`endif // __CMN_CSEQ_SV__

