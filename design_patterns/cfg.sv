// class: cfg_c
class cfg_c extends uvm_object;
   `uvm_object_utils_begin(foo_pkg::cfg_c)
      `uvm_field_int(coverage_enable, UVM_ALL_ON)
      `uvm_field_object(reg_block,    UVM_REFERENCE)
      `uvm_field_object(child_cfg,    UVM_ALL_ON)
   `uvm_object_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Fields
   // var: coverage_enable
   // Is functional coverage collection enabled?
   bit coverage_enable;

   // var: reg_block
   // Register block for this environment
   rand reg_block_c reg_block;

   // var: child_cfg
   // A lower-level CFG class
   child_cfg_c child_cfg;

   //----------------------------------------------------------------------------------------
   // Group: Constraints

   //----------------------------------------------------------------------------------------
   // Group: Methods
   // Create the child_cfg class, and provide to it the full path name of this class.
   // Determine coverage enable by reading from the resource database. This must be done
   // in order to new the covergroup in the new function, which is a SystemVerilog requirement.
   function new(string name="cfg");
      super.new(name);
      child_cfg = new({name, ".child_cfg"});
      uvm_resource_db#(int)::read_by_name("uvm_root", "coverage_enable", coverage_enable, this);
      if(coverage_enable)
         cg = new();
   endfunction : new

   ////////////////////////////////////////////
   // func: sample_cg
   // Sample covergroups when called
   virtual function void sample_cg();
      if(cg)
         cg.sample();
      child_cfg.sample_cg();
   endfunction : sample_cg

   //----------------------------------------------------------------------------------------
   // Group: Functional Coverage
   // All functional covergroups go here
   covergroup cg;
   endgroup : cg
endclass : cfg_c