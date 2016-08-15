
// ***********************************************************************
// File:   hawk_os_seq_lib.sv
// Author: bhunter
/* About:  Operating-System Testing Sequence.
           This sequence runs during the main phase. It picks 50 random
           addresses, writes to them, and then performs 100 random reads,
           expecting each to match the expected results that were written
           before.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_OS_SEQ_LIB_SV__
   `define __HAWK_OS_SEQ_LIB_SV__

// class: os_main_seq_c
class os_main_seq_c extends uvm_sequence#(os_item_c);
   `uvm_object_utils(hawk_pkg::os_main_seq_c)

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: addresses
   // 50 addresses to read and write to
   rand addr_t addresses[50];

   // var: exp_results
   // The results expected upon reading
   data_t exp_results[addr_t];

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="os_seq");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   virtual task body();
      os_item_c item;
      int rd_idx;
      `cmn_seq_raise

      `cmn_info(("Sending in writes..."))

      // prime the addresses
      foreach(addresses[idx]) begin
         `uvm_do_with(item, {
            cmd == WR;
            addr == addresses[idx];
         })
         exp_results[item.addr] = item.data;
      end

      `cmn_info(("Sending in 100 reads..."))
      repeat(100) begin
         rd_idx = $urandom_range(0, 49);
         `uvm_do_with(item, {
            cmd == RD;
            addr == addresses[rd_idx];
         })
         get_response(rsp);
         `cmn_dbg(100, ("Received response from ADDR: %016X, DATA: %016X", addresses[rd_idx], rsp.data))
         if(exp_results[addresses[rd_idx]] != rsp.data)
            `cmn_err(("Expected a value of %016X", exp_results[addresses[rd_idx]]))
      end

      `cmn_info(("All traffic completed."))
      `cmn_seq_drop
   endtask : body
endclass : os_main_seq_c

`endif // __HAWK_OS_SEQ_LIB_SV__

