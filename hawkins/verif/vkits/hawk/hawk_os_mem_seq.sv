
// ***********************************************************************
// File:   hawk_os_mem_seq.sv
// Author: bhunter
/* About: Handles all memory reads, writes, and responses.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_OS_MEM_SEQ_SV__
   `define __HAWK_OS_MEM_SEQ_SV__

`include "hawk_os_item.sv"
`include "hawk_mem.sv"

typedef class os_sqr_c;

class os_mem_seq_c extends uvm_sequence #(os_item_c, os_item_c);
   `uvm_object_utils_begin(hawk_pkg::os_mem_seq_c)
   `uvm_object_utils_end
   `uvm_declare_p_sequencer(os_sqr_c)

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: mem
   // The memory instance
   mem_c mem;

   //----------------------------------------------------------------------------------------
   // Group: Methods

   function new(string name="os_mem_seq");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   virtual task body();
      os_item_c rcvd_os_item;
      mem = p_sequencer.mem;

      forever begin
         p_sequencer.rcvd_os_item_fifo.get(rcvd_os_item);
         `cmn_dbg(200, ("RX: %s", rcvd_os_item.convert2string()))

         case(rcvd_os_item.cmd)
            WR  : begin
               mem.memory[rcvd_os_item.addr] = rcvd_os_item.data;
               `cmn_dbg(200, ("Wrote [%08X] = %016X", rcvd_os_item.addr, rcvd_os_item.data))
            end
            RD  : send_read_response(rcvd_os_item);
         endcase
      end
   endtask : body

   ////////////////////////////////////////////
   // func: send_read_response
   // Given a read request, fetch the memory data and send a response item
   // that contains the correct data
   // return zeroes and emit a warning when reading from an uninitialized memory location
   virtual task send_read_response(os_item_c _read_request);
      os_item_c response_item;
      data_t rsp_data;

      if(!mem.memory.exists(_read_request.addr)) begin
         mem.memory[_read_request.addr] = 0;
         `cmn_warn(("Reading from uninitialized mem.memory location [%016X]", _read_request.addr))
      end

      rsp_data = mem.memory[_read_request.addr];

      `uvm_do_with(response_item, {
         cmd  == RESP;
         addr == _read_request.addr;  // this helps the transaction layer use the right tag
         data == rsp_data;
      })

      `cmn_dbg(200, ("Responding: %s", response_item.convert2string()))
   endtask : send_read_response
endclass : os_mem_seq_c

`endif // __HAWK_OS_MEM_SEQ_SV__

