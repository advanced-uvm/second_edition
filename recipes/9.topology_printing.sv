   ////////////////////////////////////////////
   // func: start_of_simualtion_phase
   // Print the topology
   virtual function void start_of_simulation_phase(uvm_phase phase);
      int topo_depth;
      super.start_of_simulation_phase(phase);

      // print the topology only if TOPO is a plusarg
      if(!$value$plusargs("TOPO=%d", topo_depth))
         return;
      else begin
         global_table_printer_c printer = new();
         string topology;

         printer.knobs.depth = topo_depth;
         printer.knobs.indent = 3;

         topology = uvm_top.sprint(printer);
         `cmn_info(("Printing the topology at depth %0d:\n%s", depth, topology))
      end
   endfunction : start_of_simulation_phase
