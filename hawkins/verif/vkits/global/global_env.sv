
// ***********************************************************************
// File:   global_env.sv
// Author: bhunter
/* About:  Common package
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
   *************************************************************************/


`ifndef __GLOBAL_ENV_SV__
   `define __GLOBAL_ENV_SV__

   `define DEFAULT_TOPO_DEPTH  4
   `define DEFAULT_QUIET_DRAIN_TIME 20ns

`include "global_watchdog.sv"
`include "global_heartbeat_mon.sv"

// class: env_c
// The Global environment, instantiated in all testbenches at the global scope.
class env_c extends uvm_env;
   // type: heartbeat_rate_e
   // Controls the frequency of the heartbeat rate
   typedef enum { NORMAL, SLOW, SLOWER } heartbeat_rate_e;

   `uvm_component_utils_begin(global_pkg::env_c)
      `uvm_field_int(topo_depth, UVM_DEFAULT | UVM_DEC)
      `uvm_field_enum(heartbeat_rate_e, heartbeat_rate, UVM_DEFAULT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: topo_depth
   // The depth of topology printing (-1 means that it was not set in config_db)
   int topo_depth = -1;

   // var: heartbeat_rate
   // Determinate for setting heartbeat_time_ns
   heartbeat_rate_e heartbeat_rate = NORMAL;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: watchdog
   // Looks for deadlocks or watchdog timeouts.  Calls global_stop_request on either.
   watchdog_c watchdog;

   // var: heartbeat
   // Monitors heartbeat of registered components during main and shutdown phases
   heartbeat_mon_c heartbeat_mon;

   // var: current_phase
   // This holds the current run-time phase of the test
   local uvm_phase current_phase;

   // var: current_phase_start_time
   // Used for tracking wall-clock duration of each phase
   local real current_phase_start_time;

   // var: idle_checks
   // Number of idle checks to perform at the end of the test
   int       idle_checks;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="env",
                uvm_component parent=null);
      super.new(name, parent);

      idle_checks = 1;
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   // Connect the hearbeat mon and wdog
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      watchdog = watchdog_c::type_id::create("watchdog", this);
      heartbeat_mon = heartbeat_mon_c::type_id::create("heartbeat_mon", this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: start_of_simualtion_phase
   // Print the topology
   virtual function void start_of_simulation_phase(uvm_phase phase);
      super.start_of_simulation_phase(phase);

      // plusargs override configured value
      // configured value overrides DEFAULT_TOPO_DEPTH
      if(!$value$plusargs("UVM_TOPO_DEPTH=%d", topo_depth)) begin
         if(topo_depth == -1)
            topo_depth = (get_report_verbosity_level())? `DEFAULT_TOPO_DEPTH:0;
         else
            topo_depth = 0;
      end

      if(topo_depth)
         print_topology(uvm_top, topo_depth);
   endfunction

   ////////////////////////////////////////////
   // Func: run_phase
   // Raises phase objection and waits on clock to start
   virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);

      fork
         begin
            still_going();
         end
      join;

   endtask

   ////////////////////////////////////////////
   // funcs: Changes the current_phase field
   virtual function void phase_started(uvm_phase phase);
      super.phase_started(phase);
      current_phase = phase;
      `cmn_info(("Entered phase: %s", current_phase.get_name()))
   endfunction : phase_started

   ////////////////////////////////////////////
   // func: print_topology
   virtual function void print_topology(uvm_object _object,
                                        int _depth,
                                        int _name_width=-1,
                                        int _type_width=-1);

      uvm_table_printer printer = new();
      int topo_name_width, topo_type_width;
      string topology;

      printer.knobs.depth = _depth;
      printer.knobs.indent = 3;

      topology = _object.sprint(printer);
      `cmn_info(("Printing the %s topology at depth %0d:", _object.get_full_name(), _depth))
      $display("%s", topology);
   endfunction : print_topology

   ////////////////////////////////////////////
   // task: still_going
   // Prints "Still going at 1234.5 cycles/sec..." every heartbeat_time_ns
   virtual task still_going();
      int unsigned heartbeat_time_ns;

      // Setup heartbeat message delay
      case (heartbeat_rate)
        NORMAL: heartbeat_time_ns = 5000;
        SLOW:   heartbeat_time_ns = 50000;
        SLOWER: heartbeat_time_ns = 500000;
      endcase

      forever begin
         #(heartbeat_time_ns*1ns);
         `cmn_info(("Still going..."))
      end
   endtask : still_going

   ////////////////////////////////////////////
   // func: get_current_phase
   // Return the currently running phase
   virtual   function uvm_phase get_current_phase();
      return current_phase;
   endfunction : get_current_phase

   ////////////////////////////////////////////
   // func: mformat
   // Converts a memory value in megabytes to a unit-adjusted string
   function string mformat(input longint _mb);
      return (_mb < 1024
              ? $sformatf("%0dm", _mb)
              : $sformatf("%1.1fg", _mb/real'(1024)));
   endfunction : mformat

   ////////////////////////////////////////////
   // func: tformat
   // Converts a time value in seconds to a H:MM:SS string
   function string tformat(input real _sec);
      integer h, m, s;
      s = integer'(_sec);
      h = (s / 3600);
      m = (s / 60) % 60;
      s = (s % 60);
      return ($sformatf("%0d:%02d:%02d", h, m, s));
   endfunction : tformat
endclass : env_c

//****************************************************************************************
// instantiate this class so that it is visible to all importers
// The class must be ::create'd by the base test
static env_c env;


`endif // __GLOBAL_ENV_SV__
