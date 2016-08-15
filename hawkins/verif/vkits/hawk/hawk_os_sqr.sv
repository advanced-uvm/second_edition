
// ***********************************************************************
// File:   hawk_os_sqr.sv
// Author: bhunter
/* About:  The operating system sequencer.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_OS_SQR_SV__
   `define __HAWK_OS_SQR_SV__

`include "hawk_mem.sv"

typedef class os_mem_seq_c;

//****************************************************************************************
// class: os_sqr_c
// A sequencer that operates at the OS level. Holds a handle to the memory so that the os_mem_seq
// can perform reads, writes, and generate responses
class os_sqr_c extends uvm_sequencer#(os_item_c, os_item_c);
   `uvm_component_utils_begin(hawk_pkg::os_sqr_c)
      `uvm_field_object(mem, UVM_REFERENCE)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: mem
   // A handle to the memory component
   mem_c mem;

   //----------------------------------------------------------------------------------------
   // Group: TLM Ports

   // var: rcvd_os_item_export
   // Receives all OS-level items from the other agent.
   uvm_analysis_export #(os_item_c) rcvd_os_item_export;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: rcvd_os_item_fifo
   // Gets the OS items and holds them for the os_mem sequence
   uvm_tlm_analysis_fifo#(os_item_c) rcvd_os_item_fifo;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="os_vsqr",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   // Ensure that the memory component was populated
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      assert(mem) else
         `cmn_fatal(("Eek! There is no mem"))
      // build export and fifo
      rcvd_os_item_export = new("rcvd_os_item_export", this);
      rcvd_os_item_fifo = new("rcvd_os_item_fifo", this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: connect_phase
   // Connext rcvd_os_item_export to fifo
   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      rcvd_os_item_export.connect(rcvd_os_item_fifo.analysis_export);
   endfunction : connect_phase

   ////////////////////////////////////////////
   // func: run_phase
   // Launch the memory handler sequence
   virtual task run_phase(uvm_phase phase);
      os_mem_seq_c os_mem_seq = os_mem_seq_c::type_id::create("os_mem_seq");
      os_mem_seq.start(this);
   endtask : run_phase
endclass : os_sqr_c

`endif // __HAWK_OS_SQR_SV__

