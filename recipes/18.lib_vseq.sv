// class: lib_vseq_c
class lib_vseq_c extends uvm_sequence;
   `uvm_object_utils(cmn_pkg::lib_vseq_c)

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: cfg
   // The cfg class for an exer_vseq
   lib_vseq_cfg_c cfg;

   // var: curr_cnt
   // The number of vseqs currently outstanding
   int unsigned curr_cnt;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="lib_vseq");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   virtual task body();
      string type_name;

      `cmn_seq_raise
      `cmn_info(("Launching %0d vseqs.", cfg.vseqs_to_send))

      for(int num_sent = 0; num_sent < cfg.vseqs_to_send; num_sent++) begin
         automatic uvm_sequence vseq;

         // wait until the number outstanding is less than the maximum that are outstanding
         if(curr_cnt >= cfg.max_outstanding) begin
            `cmn_info(("Blocking until at least 1 sequence completes."))
            wait(curr_cnt < cfg.max_outstanding);
         end

         // get the sequence type to send by getting the name of its type
         type_name = cfg.get_next_vseq();

         // create the sequence based on the string.
         if(!$cast(vseq, uvm_factory::get().create_object_by_name(type_name,
                                                                  get_full_name(), type_name)))
            `cmn_fatal(("Unable to create a sequence of type %s", type_name))

         // Set the sequence’s sequencer to be the one this sequence is operating on
         vseq.set_item_context(this, m_sequencer);

         // Randomize
         assert(vseq.randomize()) else begin
            `cmn_err(("Randomization of %s failed.", type_name))
            continue;
         end

         `cmn_info(("Launching a sequence of type %s", type_name))

         // The fork..join_none is what allows this code to send multiple sequences at once
         curr_cnt++;
         fork
            begin
               `uvm_send(vseq)
               curr_cnt--;
            end
         join_none
      end

      // ensure that all sequences complete before exiting.
      wait(curr_cnt == 0);
      `cmn_info(("Exerciser complete after %0d sequences.", cfg.vseqs_to_send))

      // drop objection
      `cmn_seq_drop
   endtask : body
endclass : lib_vseq_c
