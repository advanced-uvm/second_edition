class multi_subscriber_c#(type TYPE=uvm_sequence_item) extends uvm_component;
   `uvm_component_utils_begin(multi_subscriber_c)
      `uvm_field_int(num_exports, UVM_COMPONENT | UVM_DEC)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: num_exports
   // The number of exports/fifos to create
   int num_exports = 8;

   //----------------------------------------------------------------------------------------
   // Group: TLM Ports

   // var: item_export
   // Items come in through here
   uvm_analysis_export #(TYPE) item_export[];

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: item_fifo
   // Receives the items from the exports
   uvm_tlm_analysis_fifo#(TYPE) item_fifo[];

   //----------------------------------------------------------------------------------------
   // Group: Methods
   // func: new
   virtual function void new(string name="",
                             uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   // Create the fifos and the exports
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      item_export = new[num_exports];
      foreach(item_export[idx])
         item_export[idx] = new($sformatf("item_export[%0d]", idx), this);
      item_fifo = new[num_fifos];
      foreach(item_fifo[idx])
         item_fifo[idx] = new($sformatf("item_fifo[%0d]", idx), this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: connect_phase
   // Connect the exports to the FIFOs
   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      foreach(item_export[idx])
         item_export[idx].connect(item_fifo[idx].analysis_export);
   endfunction : connect_phase

   ////////////////////////////////////////////
   // func: run_phase
   // Launch the read_fifo tasks
   virtual task run_phase(uvm_phase phase);
      foreach(item_fifo[idx]) begin
         automatic int _idx = idx;
         fork
            read_fifo(_idx);
         join_none
      end
   endtask : run_phase

   ////////////////////////////////////////////
   // func: read_fifo
   // Pull items from the fifo as they come in
   virtual task read_fifo(int _fifo_idx);
      TYPE item;
      forever begin
         item_fifo[_fifo_idx].get(item);
         write_item(item, _fifo_idx);
      end
   endtask : read_fifo

   ////////////////////////////////////////////
   // func: write_item
   // Process items as they come in
   pure virtual function void write_item(TYPE _item,
                                         int _idx);
   endfunction : write_item
endclass : multi_subscriber_c
