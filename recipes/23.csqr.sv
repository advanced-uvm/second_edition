// ***********************************************************************
// File:   23.csqr.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Brian P. Hunter
 *************************************************************************/

`ifndef __23_CSQR_SV__
   `define __23_CSQR_SV___

class csqr_c#(type UP_REQ=uvm_sequence_item, UP_TRAFFIC=UP_REQ,
              DOWN_REQ=uvm_sequence_item, DOWN_TRAFFIC=DOWN_REQ)
              extends uvm_sequencer#(DOWN_REQ);
   `uvm_component_utils_begin(csqr_c)
      `uvm_field_int(chain_break, UVM_DEFAULT)
      `uvm_field_enum(uvm_sequencer_arb_mode, sqr_arb_mode, UVM_DEFAULT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: sqr_arb_mode
   // The sequencer arbitration mode
   uvm_sequencer_arb_mode sqr_arb_mode = UVM_SEQ_ARB_STRICT_FIFO;

   // var: chain_break
   // Set this configuration variable if this chained sequencer is the
   // end of the chain but does NOT send to a driver.
   //
   // When set, the down_seq_item_port is created and takes the place
   // of another chained sequencer's driver. Downstream requests are
   // then automatically pulled from the opposite side's chained
   // sequencer.
   bit chain_break = 0;

   //----------------------------------------------------------------
   // Group: TLM Ports

   // var: up_seq_item_port
   // Gets the next sequence from the upstream sequencer
   uvm_seq_item_pull_port#(UP_REQ) up_seq_item_port;

   // var: up_traffic_port
   // Drives traffic back upstream
   uvm_analysis_port#(UP_TRAFFIC) up_traffic_port;

   // var: down_traffic_export
   // Receives traffic from the downstream sequencer
   uvm_analysis_export #(DOWN_TRAFFIC) down_traffic_export;

   // var: down_seq_item_port
   // Pulls downstream items from another chained sequencer just as a
   // driver would.
   // only created when chain_break == 1
   uvm_seq_item_pull_port#(DOWN_REQ, DOWN_TRAFFIC) down_seq_item_port;

   //----------------------------------------------------------------------------------------
   // Group: Fields
   // var: up_seq_item_fifo
   // Receives upstream sequence items
   uvm_tlm_analysis_fifo#(UP_REQ) up_seq_item_fifo;

   // var: down_traffic_fifo
   // Receives the traffic from the downstream sequencer
   uvm_tlm_analysis_fifo#(DOWN_TRAFFIC) down_traffic_fifo;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="csqr",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      up_traffic_port = new("up_traffic_port", this);
      down_traffic_export = new("down_traffic_export", this);
      down_traffic_fifo = new("down_traffic_fifo", this);
      up_seq_item_port = new("up_seq_item_port", this);
      up_seq_item_fifo = new("up_seq_item_fifo", this);
      set_arbitration(sqr_arb_mode);
      if(chain_break)
         down_seq_item_port = new("down_seq_item_port", this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: connect_phase
   // Connect downstream traffic fifo to export
   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      down_traffic_export.connect(down_traffic_fifo.analysis_export);
   endfunction : connect_phase

   ////////////////////////////////////////////
   // func: run_phase
   virtual task run_phase(uvm_phase phase);
      fork
         up_fetcher();
         if(chain_break)
            downstream_driver();
      join
   endtask : run_phase

   ////////////////////////////////////////////
   // func: up_fetcher
   // continuously get the next item from upstream and write it
   // into the up_seq_item_fifo. Then tell the upstream sequencer that
   // the item is done.
   virtual task up_fetcher();
      UP_REQ item;

      forever begin
         up_seq_item_port.get_next_item(item);
         up_seq_item_fifo.analysis_export.write(item);
         up_seq_item_port.item_done();
      end
   endtask : up_fetcher

   ////////////////////////////////////////////
   // func: downstream_driver
   // Pulls the requests out of the down_seq_item_port as a
   // driver would. Converts these to downstream traffic and pushes
   // it into the downstream fifo
   virtual task downstream_driver();
      DOWN_REQ down_req;
      DOWN_TRAFFIC down_traffic;

      forever begin
         down_seq_item_port.get_next_item(down_req);
         down_traffic = convert_down_req(down_req);
         down_traffic_fifo.analysis_export.write(down_traffic);
         down_traffic_user_task(down_traffic);
         down_seq_item_port.item_done();
      end
   endtask : downstream_driver

   ////////////////////////////////////////////
   // func: convert_down_req
   // Convert a downstream request to downstream traffic
   // By default, these are the same types and a cast will work.
   // Override if necessary.
   virtual function DOWN_TRAFFIC convert_down_req(ref DOWN_REQ _down_req);
      $cast(convert_down_req, _down_req);
   endfunction : convert_down_req

   ////////////////////////////////////////////
   // func: down_traffic_user_task
   // Allow the user to handle what happens to downstream traffic
   // before its item_done is called. This task is only ever called
   // when chain_break is set.
   virtual task down_traffic_user_task(ref DOWN_TRAFFIC _down_traffic);
   endtask : down_traffic_user_task
endclass : csqr_c

`endif // __23_CSQR_SV__
