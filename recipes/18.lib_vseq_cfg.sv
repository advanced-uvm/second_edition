// class: lib_vseq_cfg_c
class lib_vseq_cfg_c extends uvm_object;
   `uvm_object_utils_begin(cmn_pkg::lib_vseq_cfg_c)
      `uvm_field_int(vseqs_to_send,              UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(max_outstanding,            UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end
   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: vseqs_to_send
   // The number of virtual sequences that will be sent
   rand int unsigned vseqs_to_send;

   // var: max_outstanding
   // The number of virtual sequences outstanding at a time
   int unsigned max_outstanding = 5;

   //----------------------------------------------------------------------------------------
   // Group: Constraints

   // constraint: vseqs_to_send_L0_cnstr
   // Keep less than 1000
   constraint vseqs_to_send_L0_cnstr {
      vseqs_to_send inside {[1:1000]};
   }

   // constraint: vseqs_to_send_L1_cnstr
   // Keep less than 10 (for testbenches just getting started)
   constraint vseqs_to_send_L1_cnstr {
      vseqs_to_send inside {[1:10]};
   }

   //----------------------------------------------------------------------------------------
   // Group: Local Fields

   // var: dist_chooser
   // A distribution chooser (see Recipe 10.14)
   cmn_pkg::dist_chooser_c#(string) dist_chooser;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="exer_vseq_cfg");
      super.new(name);
      dist_chooser = cmn_pkg::dist_chooser_c#(string)::type_id::create("dist_chooser");
   endfunction : new

   ////////////////////////////////////////////
   // func: post_randomize
   // Ensure that sequences have been added
   function void post_randomize();
      assert(dist_chooser.is_configured()) else
         `cmn_fatal(("No virtual sequences were added to this policy class."))
   endfunction : post_randomize

   ////////////////////////////////////////////
   // func: add_vseq
   // Add a sequence to the library, with a given distribution weight
   virtual function void add_vseq(string _vseq_name,
                                  int unsigned _weight);
      if(_weight) begin
         dist_chooser.add_item(_weight, _vseq_name);
         dist_chooser.configure();
      end
   endfunction : add_vseq

   ////////////////////////////////////////////
   // func: get_next_vseq
   // Returns the string of the next sequence to send
   virtual function string get_next_vseq();
      return(dist_chooser.get_next());
   endfunction : get_next_vseq
endclass : lib_vseq_cfg_c
