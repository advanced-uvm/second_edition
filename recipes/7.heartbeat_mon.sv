// ***********************************************************************
// File:   7.heartbeat_mon.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
 *************************************************************************/

`ifndef __7_HEARTBEAT_MON_SV__
   `define __7_HEARTBEAT_MON_SV__

class heartbeat_mon_c extends uvm_component;
   `uvm_component_utils_begin(heartbeat_mon_c)
      `uvm_field_int(enabled,        UVM_COMPONENT)
      `uvm_field_int(sample_time_ns, UVM_COMPONENT | UVM_DEC)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: enabled
   // Set to 0 to disable the heartbeat monitor
   bit enabled = 1;

   // var: sample_time_ns
   // The time between checking to see if at least one component has raised its objection
   int unsigned sample_time_ns = 5000;

   //----------------------------------------------------------------------------------------
   // Group: Fields
   // var: objections
   // A hash of objections, one for each component, and hashed by sample_time.
   // If the sample_time is zero, that means they use sample_time_ns.
   objection_c objections[uvm_component];

   // var: override_times
   // A hash of times for each component that wishes to override the sample_time
   time override_times[uvm_component];

   // var: start_monitor
   // An event that is triggered when main_phase starts
   event start_monitor;

   // var: stop_monitor
   // An event that is triggered when all either the shutdown or pre_reset phases end
   event stop_monitor;

   // var: deadlock_occurred
   // Set to 1 on deadlock
   bit deadlock_occurred = 0;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="heartbeat_mon",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: run_phase
   // launches the heartbeat monitor
   virtual task run_phase(uvm_phase phase);
      forever begin
         // do nothing if not enabled or if no components were added
         if(enabled == 0 || objections.size() == 0)
            return;

         // wait for the pre_configure phase to start
         @(start_monitor);

         // run the hb_monitor until the post_shutdown_phase.
         fork
            hb_monitor(phase);
            @(stop_monitor);
         join_any
         disable fork;
      end
   endtask : run_phase

   ////////////////////////////////////////////
   // func: phase_started
   // Turn the monitor on during the correct phase
   virtual function void phase_started(uvm_phase phase);
      if(phase.is(uvm_pre_configure_phase::get()))
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
   // Func: final_phase
   // Ensure that a fatal error is reported
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

         // check for deadlock situation
         if(actives.size() == 0) begin
            uvm_object objectors[$];
            uvm_phase current_phase = get_current_phase();
            `cmn_err(("Deadlock! These components registered no activity during in the last %0dns:",
                       sample_time_ns))
            summarize(inactives);
            current_phase.get_objection().get_objectors(objectors);
            `cmn_info(({"These are the ", current_phase.get_name(), " phase's current objectors:\n",
                        get_obj_list(objectors)}))
            uvm_domain::jump_all(uvm_check_phase::get());
            // ensure that `cmn_fatal is called during final phase
            deadlock_occurred = 1;
         end

         // clear out the actives/inactives lists.
         actives.delete();
         inactives.delete();
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
         objection_c obj = new({_comp.get_full_name(), ".heartbeat"});

         objections[_comp] = obj;
         if(_override_time)
            override_times[_comp] = _override_time;
      end
   endfunction : register

   ////////////////////////////////////////////
   // func: raise
   // Components call this to raise their objections
   virtual function void raise(uvm_component _comp);
      if(!enabled)
         return;
      if(objections.exists(_comp)) begin
         objections[_comp].raise();
      end else
         `uvm_warn(({"Component is not registered with the heartbeat monitor: ",
                     _comp.get_full_name()}))
   endfunction : raise

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
   // Print the list of components and their last raised objection time
   virtual function void summarize(uvm_component _comps[$]);
      if(_comps.size() == 0)
         $display("  <none>");
      $display("              COMPONENT NAME         LAST HEARTBEAT");
      foreach(_comps[x])
         $display("  %-70s : %t", _comps[x].get_full_name(), objections[_comps[x]].last_raised_time);
   endfunction : summarize
endclass : heartbeat_mon_c

`endif // __7_HEARTBEAT_MON_SV__
