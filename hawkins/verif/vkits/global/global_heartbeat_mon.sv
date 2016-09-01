
// ***********************************************************************
// File:   global_heartbeat_mon.sv
// Author: bhunter
/* About:  Global Heartbeat Monitor
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
   *************************************************************************/

`ifndef __GLOBAL_HEARTBEAT_MON_SV__
   `define __GLOBAL_HEARTBEAT_MON_SV__

// class: heartbeat_mon_c
// Registered components must regularly call the heartbeat's raiseunctio// phase and shutdown phases, else this will presume a deadlock and trigger a fatal error.  This
// heartbeat monitor will check every sample_time_ns (default:5000) to ensure that at least 1
// registered component has seen activity.
class heartbeat_mon_c extends uvm_component;
   //----------------------------------------------------------------------------------------
   // Group: Types

   // type: mon_time_t
   // The type that specifies the duration between heartbeat checks per component
   typedef int unsigned sample_time_t;

   // type: starting_phase_e
   // The pre-phase in which the heartbeat monitor will start
   typedef enum { RESET_PHASE, CONFIG_PHASE, MAIN_PHASE } starting_phase_e;

   `uvm_component_utils_begin(global_pkg::heartbeat_mon_c)
      `uvm_field_int(enabled,                           UVM_DEFAULT)
      `uvm_field_int(sample_time_ns,                    UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(permit_overrides,                  UVM_DEFAULT)
      `uvm_field_enum(starting_phase_e, starting_phase, UVM_DEFAULT)
      `uvm_field_int(trace_mode,                        UVM_DEFAULT)
      `uvm_field_int(quiet,                             UVM_DEFAULT)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: enabled
   // Set to 0 to disable the heartbeat monitor
   bit enabled = 1;

   // var: sample_time_ns
   // The time between checking to see if at least one component has raised its objection
   sample_time_t sample_time_ns = 5000;

   // var: permit_overrides
   // When cleared, the heartbeat monitor time will be set to whatever sample_time_ns is set to.
   // Otherwise, it will be the maximum of that time or all the component override times.
   bit         permit_overrides = 1;

   // var: starting_phase
   // The heartbeat monitor will start either during pre_reset_phase, pre_config_phase, or pre_main_phase
   starting_phase_e starting_phase = CONFIG_PHASE;

   // var: trace_mode
   // Set to one to turn on all objection trace modes
   bit trace_mode = 0;

   // var: quiet
   // Set this to prevent heartbeat monitor from sending messages
   bit quiet = 0;

   // var: sampled
   // Tell others that a heartbeat monitor sample just occurred
   event sampled;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: objections
   // A hash of objections, one for each component, and hashed by sample_time.
   // If the sample_time is zero, that means they use sample_time_ns.
   cmn_pkg::objection_c objections[uvm_component];

   // var: override_times
   // A hash of times for each component that wishes to override the sample_time
   time override_times[uvm_component];

   // var: start_monitor
   // An event that is triggered when main_phase starts
   event start_monitor;

   // var: stop_monitor
   // An event that is triggered when all objections to the shutdown phase have ended
   event stop_monitor;

   // var: paused
   // Set or cleared by pauser() function.  When set, the heartbeat monitor will
   // produce reports but will not produce errors.
   bit   paused;

   // var: deadlock_occurred
   // Set to 1 on deadlock
   bit   deadlock_occurred = 0;

   // var: start_monitor_phase
   // This is the actual singleton of the starting_phase, to be decided in build
   local uvm_phase start_monitor_phase;

   // var: stats_clk
   // This holds a reference to the clock used to calculate runtime stats
   // It should be the clock that runs most of the logic in the DUT
   // It should be set through the global_env.sv::set_stats_clk function
   cmn_pkg::clk_drv_c stats_clk;

   // var: pause_objectors
   // Each objector may add a time (in clocks) for which to pause the heartbeat monitor to
   // ensure that it does not report deadlock
   int   pause_objectors[string];

   // var: pause_objectors_ev
   // Emitted whenever pause_objectors changes
   event pause_objectors_ev;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="heartbeat",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      case(starting_phase)
         RESET_PHASE   :
            start_monitor_phase = uvm_pre_reset_phase::get();
         CONFIG_PHASE  :
            start_monitor_phase = uvm_pre_configure_phase::get();
         MAIN_PHASE  :
            start_monitor_phase = uvm_pre_main_phase::get();
      endcase
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: start_of_simulation_phase
   // Determine the correct sample_time based on all registered components and any overrides
   virtual function void start_of_simulation_phase(uvm_phase phase);
      super.start_of_simulation_phase(phase);

      if(permit_overrides) begin
         uvm_component max_comp = null;
         int unsigned new_mon_time = sample_time_ns;
         foreach(override_times[comp]) begin
            if(override_times[comp] > new_mon_time) begin
               max_comp = comp;
               new_mon_time = override_times[comp];
            end
         end
         if(new_mon_time != sample_time_ns) begin
            if(!quiet)
               `cmn_info(("Changed monitor time to %0d because of override by %s.", new_mon_time, max_comp.get_full_name()))
            sample_time_ns = new_mon_time;
         end
      end
   endfunction : start_of_simulation_phase

   ////////////////////////////////////////////
   // func: main_phase
   virtual task run_phase(uvm_phase phase);
      forever begin
         // do nothing if not enabled
         if(enabled == 0) begin
            if(!quiet)
              `cmn_info(("Heartbeat monitor disabled."))
            return;
         end

         // do nothing if no components were added
         if(objections.size() == 0) begin
            if(!quiet)
              `cmn_info(("Heartbeat monitor disabled because no components were added to it."))
            return;
         end

         // wait for the main phase to start
         @(start_monitor);

         // run the hb_monitor and pauser tasks until the post_shutdown_phase.
         fork
            pauser();
            hb_monitor(phase);
            @(stop_monitor);
         join_any
         disable fork;

         if(!quiet)
           `cmn_info(("Heartbeat monitor finished."))
      end
   endtask : run_phase

   ////////////////////////////////////////////
   // func: phase_started
   // Turn the monitor on during the correct phase
   virtual function void phase_started(uvm_phase phase);
      if(phase.is(start_monitor_phase))
         ->start_monitor;
   endfunction : phase_started

   ////////////////////////////////////////////
   // Func: phase_ended
   // Turn the monitor off here when the shutdown phase has ended
   virtual function void phase_ended(uvm_phase phase);
      super.phase_ended(phase);

      if(phase.get_imp() inside {uvm_pre_reset_phase::get(), uvm_shutdown_phase::get()})
        ->stop_monitor;
   endfunction : phase_ended

   ////////////////////////////////////////////
   virtual function void final_phase(uvm_phase phase);
      if(deadlock_occurred)
         `cmn_fatal(("Exiting due to deadlock."))
   endfunction : final_phase

   ////////////////////////////////////////////
   // func: hb_monitor
   // All of the heartbeat monitoring happens here
   virtual task hb_monitor(uvm_phase phase);
      uvm_component inactives[$];
      uvm_component actives[$];

      if(!quiet)
         `cmn_info(("Heartbeat Monitor Starting."))

      // clear out any present objections that may have been raised before the
      // shutdown phase
      foreach(objections[comp])
         objections[comp].clear();

      forever begin
         #(sample_time_ns * 1ns);

         foreach(objections[comp]) begin
            if(objections[comp].get_count() == 0) begin
               inactives.push_back(comp);
            end else begin
               actives.push_back(comp);
               objections[comp].clear();
            end
         end

         if(!quiet)
           `cmn_info(("---------------------- Heartbeat Monitor ----------------------"))

         if(actives.size()) begin
            if(!quiet) begin
              `cmn_info(("The following components had heartbeats in the last %0dns:", sample_time_ns))
               summarize(actives);
            end
         end else if(paused) begin
            if(!quiet)
              `cmn_info(("The heartbeat monitor shows deadlock but is currently paused."))
         end else begin
            uvm_object objectors[$];
            uvm_phase current_phase = env.get_current_phase();  // note: env is the global_env, since we're in the global_pkg

            // TODO: Make this report objections in all domains.
            `cmn_err(("Deadlock! The following components registered no activity during in the last %0dns:", sample_time_ns))
            summarize(inactives);
            current_phase.get_objection().get_objectors(objectors);
            `cmn_info(({"These are the ", current_phase.get_name(), " phase's current objectors:", get_obj_list(objectors)}))
            `cmn_info(("Jumping to extract phase"))
            uvm_domain::jump_all(uvm_extract_phase::get());
            // ensure that `cmn_fatal is called during final phase
            deadlock_occurred = 1;
         end

         // clear out the actives/inactives lists.
         actives.delete();
         inactives.delete();

         ->sampled;
      end
   endtask : hb_monitor

   ////////////////////////////////////////////
   // func: register
   // Registers a component to the list of components that will be checked for activity
   virtual function void register(uvm_component _comp,
                                  time _override_time=0);
      if(!enabled)
         return;

      if(_comp) begin
         cmn_pkg::objection_c obj = new({_comp.get_full_name(), ".heartbeat"});
         string extra_text;

         objections[_comp] = obj;
         if(_override_time) begin
            override_times[_comp] = _override_time;
            extra_text = $sformatf("with monitor override time %t", _override_time);
         end

         if(!quiet)
            `cmn_info(("Component registered with heartbeat monitor: %s %s",
                      _comp.get_full_name(), extra_text));
      end
   endfunction : register

   ////////////////////////////////////////////
   // func: raise
   // Components call this to raise their objections
   virtual function void raise(uvm_component _comp,
                               string _description="",
                               string _filename,
                               int _lineno);
      if(!enabled)
         return;

      if(objections.exists(_comp)) begin
         objections[_comp].raise();
      end else begin
         `cmn_warn(({"Component is not registered with the heartbeat monitor: ", _comp.get_full_name()}))
      end
   endfunction : raise

   ////////////////////////////////////////////
   // func: pause
   // Can be called by components to ensure that a deadlock is not raised.
   virtual function void pause(int _pause_clks,
                               string _objector);
      if(_pause_clks) begin
         `cmn_info(("%s requests that heartbeat monitor is paused for %0d clocks.", _objector, _pause_clks))
         pause_objectors[_objector] = _pause_clks;
      end else
         pause_objectors.delete(_objector);
      ->pause_objectors_ev;
   endfunction : pause

   ////////////////////////////////////////////
   // func: pauser
   virtual task pauser();
      int clks_to_pause; // the number of clocks to wait
      int clks_waited;   // the actual number of clocks waited
      int junk[$];

      forever begin
         do begin
            paused = pause_objectors.size() > 0;
            if(!paused)
               @(pause_objectors_ev);
         end while(!paused);

         // calculate how many clocks to pause
         junk = pause_objectors.max();
         clks_to_pause = junk[0];
         clks_waited = 0;
         `cmn_info(("Heartbeat monitor will be paused for %0d clocks.", clks_to_pause))

         fork
            @(pause_objectors_ev);

            begin : pauser_loop
               repeat(clks_to_pause) begin
                  @(posedge stats_clk.clk_vi.clk);
                  clks_waited++;
               end
            end : pauser_loop
         join_any
         disable fork;

         // decrement actual clks_waited from objectors, deleting those that have expired
         foreach(pause_objectors[p])
            if(pause_objectors[p] <= clks_waited)
               pause_objectors.delete(p);
            else
               pause_objectors[p] -= clks_waited;
         if(pause_objectors.size())
            `cmn_info(("Pause complete but there are other pause objectors."))
         else
            `cmn_info(("Pause completed."))
      end
   endtask : pauser

   ////////////////////////////////////////////
   // func: get_obj_list
   // Return the list of obj as a string suitable for printing
   virtual function string get_obj_list(uvm_object _objs[$]);
      if(_objs.size() == 0)
         return "  <none>";

      foreach(_objs[x])
         get_obj_list = {get_obj_list, "\n  ", _objs[x].get_full_name()};
   endfunction : get_obj_list

   ////////////////////////////////////////////
   // func: get_comp_list
   // Return the list of components and their last raised objection time as a string
   virtual function void summarize(uvm_component _comps[$]);
      if(_comps.size() == 0)
         $display("  <none>");

      $display("              COMPONENT NAME                                               LAST HEARTBEAT");
      foreach(_comps[x])
         $display("  %-70s : %t", _comps[x].get_full_name(), objections[_comps[x]].last_raised_time);
   endfunction : summarize

endclass : heartbeat_mon_c

`endif // __GLOBAL_HEARTBEAT_MON_SV__
