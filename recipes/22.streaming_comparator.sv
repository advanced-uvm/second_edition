// ***********************************************************************
// File:   22.streaming_comparator.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
 *************************************************************************/

`ifndef __22_STREAMING_COMPARATOR_SV__
   `define __22_STREAMING_COMPARATOR_SV__

class streaming_comparator_c #(type TYPE=uvm_object) extends uvm_component;
   `uvm_component_utils_begin(cmn_pkg::streaming_comparator_c#(TYPE))
      `uvm_field_int(continuity,        UVM_DEFAULT | UVM_NOPACK | UVM_NOCOMPARE | UVM_DEC)
      `uvm_field_int(actual_ok_first,   UVM_DEFAULT | UVM_NOPACK | UVM_NOCOMPARE)
      `uvm_field_int(outstanding_at_end,UVM_DEFAULT | UVM_NOPACK | UVM_NOCOMPARE | UVM_DEC)
      `uvm_field_int(abandon_lock_depth,UVM_DEFAULT | UVM_NOPACK | UVM_NOCOMPARE | UVM_DEC)
   `uvm_component_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Configuration Fields

   // var: continuity
   // This is the number of consecutive matches that must be seen before the streams
   // are considered 'locked'.
   int unsigned continuity = 1;

   // var: comparer
   // A comparer object. If not specified, uses the default comparer.
   uvm_comparer comparer;

   // var: actual_ok_first
   // When set, actual items may enter the comparator before expected values.
   // When clear, this is an error.
   bit actual_ok_first = 1;

   // var: outstanding_at_end
   // Set to a value that permits a certain number of outstanding objects in
   // either the actual or expected streams. If more of either are in the
   // comparator, then the shutdown_phase will be held up.
   int unsigned outstanding_at_end = 0;

   // var: abandon_lock_depth
   // This is the point at which, if the queues of expected or actual objects
   // reach this level without having locked, all attempts to lock will be
   // abandoned. The comparator will not attempt to lock in the future.
   int unsigned abandon_lock_depth = 50;

   //----------------------------------------------------------------------------------------
   // Group: TLM Ports

   // var: exp_imp
   // A stream of expected values
   uvm_analysis_imp_exp #(TYPE, streaming_comparator_c#(TYPE)) exp_imp;

   // var: act_imp
   // A stream of actual values
   uvm_analysis_imp_act #(TYPE, streaming_comparator_c#(TYPE)) act_imp;

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: is_locked
   // Set when the comparator has locked on
   bit is_locked;

   // var: must_be_locked
   // Set by user to indicate that the streams must be locked
   bit must_be_locked;

   // var: exp_q
   // The queue of expected items
   TYPE exp_q[$];

   // var: act_q
   // The queue of expected items
   TYPE act_q[$];

   // var: q_changed
   // Triggered whenever any new data is added to one of the queues
   event q_changed;

   // var: lock_abandoned
   // When set, all hope of locking is abandoned
   bit lock_abandoned;

   // var: quiet_comparer
   // A comparer that doesn't print anything on mismatches, while trying to lock
   uvm_comparer quiet_comparer;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="stream",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(continuity == 0)
         `cmn_fatal(("Programming error: continuity may not be set to zero."))
      exp_imp = new("exp_imp", this);
      act_imp = new("act_imp", this);
      quiet_comparer = new();
      quiet_comparer.verbosity = 1000;
      quiet_comparer.show_max = 1;
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: run_phase
   virtual task run_phase(uvm_phase phase);
      TYPE act_item, exp_item;
      forever begin
         @(q_changed);
         if(is_locked)
            compare_locked();
         else begin
            try_to_lock();
            if(is_locked)
               compare_locked();
         end
         // exit out if locking has ever been abandoned
         if(lock_abandoned)
            break;
      end
   endtask : run_phase

   ////////////////////////////////////////////
   // func: shutdown_phase
   // If locked, ensure that expected values drain out before releasing this phase
   virtual task shutdown_phase(uvm_phase phase);
      if(lock_abandoned)
         return;

      forever begin
         if(!is_locked)
            @(posedge is_locked);
         if(exp_q.size() > outstanding_at_end || act_q.size() > outstanding_at_end) begin
            phase.raise_objection(this);
            `cmn_info(("There are %0d exp and %0d act items remaining (%0d exp are ok at end).",
               exp_q.size(), act_q.size(), outstanding_at_end))
            print_queues(0);
            while(exp_q.size() > outstanding_at_end || act_q.size() > outstanding_at_end)
               @(q_changed);
            `cmn_info(("Shutdown complete after queues have drained."))
            print_queues(0);
            phase.drop_objection(this);
         end

         @(q_changed);
      end
   endtask : shutdown_phase

   ////////////////////////////////////////////
   // func: check_phase
   // Ensure that if must_be_locked is true, then the comparator has locked at the end of the test
   virtual function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if(lock_abandoned)
         `cmn_err(("Lock attempts were abandoned."))

      if(must_be_locked && !is_locked)
         `cmn_err(("This comparator must be locked by the end of the test, but isn't."))

      if(act_q.size() > outstanding_at_end)
         `cmn_err(("There are %0d actual items outstanding, but only %0d are permitted.",
                   act_q.size(), outstanding_at_end))

      if(exp_q.size() > outstanding_at_end)
         `cmn_err(("There are %0d expected items outstanding, but only %0d are permitted.",
                    exp_q.size(), outstanding_at_end))
   endfunction : check_phase

   ////////////////////////////////////////////
   // func: must_lock
   // Called by the user to indicate that the comparator must by now be locked,
   // or when it may become unlocked
   virtual function void must_lock(bit _must_lock=1);
      must_be_locked = _must_lock;
      if(!is_locked && must_be_locked) begin
         `cmn_err(("Comparator must now be locked, but it hasn't locked yet."))
         lock_abandoned = 1;
      end
   endfunction : must_lock

   ////////////////////////////////////////////
   // func: flush_actual
   // Flushes all outstanding actual items
   virtual function void flush_actual();
      `cmn_dbg(200, ("Flushing %0d outstanding actual items.", act_q.size()))
      act_q.delete();
   endfunction : flush_actual

   ////////////////////////////////////////////
   // func: flush_expected
   // Flushes all outstanding expected items
   virtual function void flush_expected();
      `cmn_dbg(200, ("Flushing %0d outstanding expected items.", exp_q.size()))
      exp_q.delete();
   endfunction : flush_expected

   ////////////////////////////////////////////
   // func: compare_locked
   // Compare the two streams as if they are locked
   virtual function void compare_locked();
      TYPE act_item, exp_item;
      `cmn_dbg(200, ("Comparing as locked"))
      while(act_q.size()) begin
         if(exp_q.size() == 0) begin
            if(act_q.size() > abandon_lock_depth) begin
               `cmn_err(("There are %0d actual items, but none are expected. Abandoning lock.",
                         abandon_lock_depth))
               lock_abandoned = 1;
               return;
            end


            if(!actual_ok_first)
               `cmn_err(("Received item, but none are expected: %s", act_item.convert2string()))
            else
               return;
         end

         act_item = act_q.pop_front();
         exp_item = exp_q.pop_front();
         if(exp_item.compare(act_item, comparer) == 0) begin
            // put those back in case they come around again
            exp_q.push_front(exp_item);
            act_q.push_front(act_item);

            if(must_be_locked)
               `cmn_err(("Miscompare:\n\tEXP: %s\n\tACT: %s",
                         exp_item.convert2string(), act_item.convert2string()))
            else begin
               is_locked = 0;
               `cmn_dbg(200, ("Comparator became unlocked"))
               return;
            end
         end

         -> q_changed;
         `cmn_dbg(200, ("remaining: act_q/exp_q = %0d/%0d", act_q.size(), exp_q.size()))
      end
   endfunction : compare_locked

   ////////////////////////////////////////////
   // func: try_to_lock
   // Attempt to line up the queues until a continuity level is found
   // Algorithm:
   //
   // Travel iteratively through each item in the expected queue, up until a
   // lock is found or we have reached the end (minus the continuity level).
   // For each of these expected items, travel iteratively through the actual
   // queue until N in a row are found to have matched. Break at this point,
   // noting where the pointers in the expected and actual queues are located.
   //
   // Then, remove the top of each queue until these pointers line up. The
   // comparator is now locked.
   virtual function void try_to_lock();
      int eidx, aidx;
      int chk_count;         // the number of successive equivalent checks
      int stop_at = exp_q.size() - continuity;

      `cmn_dbg(200, ("trying to lock with:"))
      print_queues(200);

      // first, check that one or the other queue hasn't overflowed
      check_overflow();
      if(lock_abandoned)
         return;

      // we cannot yet be locked if either queue is smaller than the continuity level
      if(exp_q.size() < continuity || act_q.size() < continuity)
         return;


      for(eidx = 0; eidx <= stop_at; eidx++) begin
         aidx = check_loop(eidx);
         if(aidx >= 0) begin
            is_locked = 1;
            `cmn_dbg(200, ("Achieved lock at exp_q[%0d]/act_q[%0d]",
                           eidx, aidx))
            break;
         end
      end

      // if we cannot lock, then exit now
      // check to see if locking should be abandoned
      if(!is_locked) begin
         `cmn_dbg(200, ("Unable to lock."))
         check_overflow();
         return;
      end

      // now pop from each queue until they are lined up
      `cmn_dbg(200, ("Popping %0d items from exp_q", eidx))
      repeat(eidx)
         exp_q.pop_front();
      `cmn_dbg(200, ("Popping %0d items from act_q", aidx))
      repeat(aidx)
         act_q.pop_front();

      `cmn_dbg(200, ("Locked with:"))
      print_queues(200);
   endfunction : try_to_lock

   ////////////////////////////////////////////
   // func: check_loop
   // Loop through act_q and compare, starting at _eidx, until <continuity> consecutive matches.
   // Otherwise, return -1
   virtual function int check_loop(int _eidx);
      int aidx;  // the outer loop through the actual queue
      int outer_stop = act_q.size() - continuity;
      int chk_count;

      for(aidx = 0; aidx <= outer_stop; aidx++) begin
         chk_count = 0;

         for(int idx = 0; idx < continuity; idx++) begin
            `cmn_dbg(200, ("Checking %0d vs. %0d chk_count=%0d/%0d",
                           _eidx, (aidx+idx), chk_count, continuity))
            if(exp_q[_eidx + idx].compare(act_q[aidx + idx], quiet_comparer)) begin
               chk_count++;
               if(chk_count == continuity)
                  return aidx;
            end else
               break;
         end
      end

      // never locked
      return -1;
   endfunction : check_loop

   ////////////////////////////////////////////
   // func: print_queues
   // Print out the expected and actual queues
   virtual function void print_queues(int _dbg_lvl);
      `cmn_dbg(_dbg_lvl, ("EXP:"))
      foreach(exp_q[idx]) begin
         `cmn_dbg(_dbg_lvl, ("%02d: %s", idx, exp_q[idx].convert2string()))
         if(idx > abandon_lock_depth) begin
            `cmn_dbg(_dbg_lvl, ("...and %0d more...", (exp_q.size()-abandon_lock_depth)))
            break;
         end
      end
      `cmn_dbg(_dbg_lvl, ("ACT:"))
      foreach(act_q[idx]) begin
         `cmn_dbg(_dbg_lvl, ("%02d: %s", idx, act_q[idx].convert2string()))
         if(idx > abandon_lock_depth) begin
            `cmn_dbg(_dbg_lvl, ("...and %0d more...", (act_q.size()-abandon_lock_depth)))
            break;
         end
      end
   endfunction : print_queues

   ////////////////////////////////////////////
   // func: check_overflow
   // Check to see if either queue is above the abandon lock threshold
   virtual function void check_overflow();
      if(exp_q.size() >= abandon_lock_depth || act_q.size() >= abandon_lock_depth) begin
         `cmn_err(("Was unable to lock after %0d expected items.", abandon_lock_depth))
         print_queues(200);
         lock_abandoned = 1;
      end
   endfunction : check_overflow

   ////////////////////////////////////////////
   // func: write_exp
   // Add to the expected queue
   virtual function void write_exp(TYPE _item);
      if(lock_abandoned)
         return;
      exp_q.push_back(_item);
      ->q_changed;
   endfunction : write_exp

   ////////////////////////////////////////////
   // func: write_act
   // Add to the expected queue
   virtual function void write_act(TYPE _item);
      if(lock_abandoned)
         return;
      act_q.push_back(_item);
      ->q_changed;
   endfunction : write_act
endclass : streaming_comparator_c

`endif // __22_STREAMING_COMPARATOR_SV__
