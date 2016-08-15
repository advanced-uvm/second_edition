//
// -------------------------------------------------------------
//    Copyright 2010 Synopsys, Inc.
//    Copyright 2010 Mentor Graphics Corporation
//    Copyright 2010 Cadence Design Systems, Inc.
//    All Rights Reserved Worldwide
//
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
// -------------------------------------------------------------
//


//
// CLASS: uvm_reg_array
// Register array abstraction base class
//
// A register array is a array of registers
// 
// This class can be used to model large arrays of registers
// It optimizes the memory by allocating memory for only
// registers which are actually accessed during simulation
//
virtual class uvm_reg_array extends uvm_reg_file;

   rand local uvm_reg      ral_regs[uvm_reg_addr_t];
   local uvm_reg           m_default_reg;
   local int unsigned      m_size;
   local int               m_inter_register_offset;
   local string            m_hdl_path;
   local bit               m_locked;
   //local uvm_reg_block     parent;
   //local uvm_reg_file   m_rf;
   //local string            default_hdl_path = "RTL";
   //local uvm_object_string_pool #(uvm_queue #(string)) hdl_paths_pool;


   //----------------------
   // Group: Initialization
   //----------------------

   //
   // Function: new
   //
   // Create a new instance
   //
   // Creates an instance of a register array abstraction class
   // with the specified name.
   //
   extern function                  new        (string name="");

   //
   // Function: configure
   // Configure a register array instance
   //
   // Specify the parent block and register file of the register array
   // instance.
   // If the register array is instantiated in a block,
   // ~regfile_parent~ is specified as ~null~.
   // If the register array is instantiated in a register file,
   // ~blk_parent~ must be the block parent of that register file and
   // ~regfile_parent~ is specified as that register file.
   //
   // If the register array corresponds to a hierarchical RTL structure,
   // it's contribution to the HDL path is specified as the ~hdl_path~.
   // Otherwise, the register array does not correspond to a hierarchical RTL
   // structure (e.g. it is physically flattened) and does not contribute
   // to the hierarchical HDL path of any contained registers.
   //
   extern function void     configure  (uvm_reg_block blk_parent,
                                        uvm_reg_file regfile_parent,
                                        uvm_reg default_reg,
                                        int size,
                                        int inter_register_offset=-1,
                                        string hdl_path = "");

   //
   // Function: set_inter_register_offset
   // Specify the offset between two consecutive registers in the array
   //
   extern virtual function void set_inter_register_offset(int offset);

   /*local*/ extern function void   Xlock_modelX;

   //---------------------
   // Group: Introspection
   //---------------------

   //
   // Function: get_size
   // Get the size of the uvm_reg_array
   //
   extern virtual function int get_size();

   //
   // Function: get_reg
   // Return the uvm_reg instance corresponding to the specified index value
   // If no instance exists, one is allocated
   //
   extern virtual function uvm_reg get_reg(int index);

   //
   // Function: get_default_reg
   // Return the uvm_reg instance corresponding to the specified index value
   // If no instance exists, one is allocated
   //
   extern virtual function uvm_reg get_default_reg();


   //--------------
   // Group: Access
   //--------------


   // Function: set
   //
   // Set the desired value of the specified index for this register array
   //
   // Sets the desired value of the fields in the register
   // to the specified value. Does not actually
   // set the value of the register in the design,
   // only the desired value in its corresponding
   // abstraction class in the RegModel model.
   // Use the <uvm_reg_array::update()> method to update the
   // actual register with the mirrored value or
   // the <uvm_reg_array::write()> method to set
   // the actual register and its mirrored value.
   //
   // Unless this method is used, the desired value is equal to
   // the mirrored value.
   //
   // Refer <uvm_reg_field::set()> for more details on the effect
   // of setting mirror values on fields with different
   // access policies.
   //
   // To modify the mirrored field values to a specific value,
   // and thus use the mirrored as a scoreboard for the register values
   // in the DUT, use the <uvm_reg_array::predict()> method. 
   //
   extern virtual function void set (int             index,
                                     uvm_reg_data_t  value,
                                     string          fname = "",
                                     int             lineno = 0);


   // Function: get
   //
   // Return the desired value of the fields of the specified index in the register array.
   //
   // Does not actually read the value
   // of the register in the design, only the desired value
   // in the abstraction class. Unless set to a different value
   // using the <uvm_reg_array::set()>, the desired value
   // and the mirrored value are identical.
   //
   // Use the <uvm_reg_array::read()> or <uvm_reg_array::peek()>
   // method to get the actual register value. 
   //
   // If the register contains write-only fields, the desired/mirrored
   // value for those fields are the value last written and assumed
   // to reside in the bits implementing these fields.
   // Although a physical read operation would something different
   // for these fields,
   // the returned value is the actual content.
   //
   extern virtual function uvm_reg_data_t  get(int     index,
                                               string  fname = "",
                                               int     lineno = 0);


   // Task: write
   //
   // Write the specified value to the specified index in this register array
   //
   // Write ~value~ in the DUT register that corresponds to this
   // abstraction class instance using the specified access
   // ~path~. 
   // If the register is mapped in more than one address map, 
   // an address ~map~ must be
   // specified if a physical access is used (front-door access).
   // If a back-door access path is used, the effect of writing
   // the register through a physical access is mimicked. For
   // example, read-only bits in the registers will not be written.
   //
   // The mirrored value will be updated using the <uvm_reg_array::predict()>
   // method.
   //
   extern virtual task write(output uvm_status_e      status,
                             input  int               index,
                             input  uvm_reg_data_t    value,
                             input  uvm_path_e        path = UVM_DEFAULT_PATH,
                             input  uvm_reg_map       map = null,
                             input  uvm_sequence_base parent = null,
                             input  int               prior = -1,
                             input  uvm_object        extension = null,
                             input  string            fname = "",
                             input  int               lineno = 0);


   // Task: read
   //
   // Read the current value from the specified index in this register array
   //
   // Read and return ~value~ from the DUT register that corresponds to this
   // abstraction class instance using the specified access
   // ~path~. 
   // If the register is mapped in more than one address map, 
   // an address ~map~ must be
   // specified if a physical access is used (front-door access).
   // If a back-door access path is used, the effect of reading
   // the register through a physical access is mimicked. For
   // example, clear-on-read bits in the registers will be set to zero.
   //
   // The mirrored value will be updated using the <uvm_reg_array::predict()>
   // method.
   //
   extern virtual task read(output uvm_status_e      status,
                            input  int               index,
                            output uvm_reg_data_t    value,
                            input  uvm_path_e        path = UVM_DEFAULT_PATH,
                            input  uvm_reg_map       map = null,
                            input  uvm_sequence_base parent = null,
                            input  int               prior = -1,
                            input  uvm_object        extension = null,
                            input  string            fname = "",
                            input  int               lineno = 0);


   // Task: poke
   //
   // Deposit the specified value to the specified index in this register array
   //
   // Deposit the value in the DUT register corresponding to this
   // abstraction class instance, as-is, using a back-door access.
   //
   // Uses the HDL path for the design abstraction specified by ~kind~.
   //
   // The mirrored value will be updated using the <uvm_reg_array::predict()>
   // method.
   //
   extern virtual task poke(output uvm_status_e      status,
                            input  int               index,
                            input  uvm_reg_data_t    value,
                            input  string            kind = "",
                            input  uvm_sequence_base parent = null,
                            input  uvm_object        extension = null,
                            input  string            fname = "",
                            input  int               lineno = 0);


   // Task: peek
   //
   // Read the current value from the specified index in this register array
   //
   // Sample the value in the DUT register corresponding to this
   // absraction class instance using a back-door access.
   // The register value is sampled, not modified.
   //
   // Uses the HDL path for the design abstraction specified by ~kind~.
   //
   // The mirrored value will be updated using the <uvm_reg_array::predict()>
   // method.
   //
   extern virtual task peek(output uvm_status_e      status,
                            input  int               index,
                            output uvm_reg_data_t    value,
                            input  string            kind = "",
                            input  uvm_sequence_base parent = null,
                            input  uvm_object        extension = null,
                            input  string            fname = "",
                            input  int               lineno = 0);


   // Task: update
   //
   // Updates the content of the specified index in the register array
   // in the design to match the desired value
   //
   // This method performs the reverse
   // operation of <uvm_reg_array::mirror()>.
   // Write this register if the DUT register is out-of-date with the
   // desired/mirrored value in the abstraction class, as determined by
   // the <uvm_reg::needs_update()> method.
   //
   // The update can be performed using the using the physical interfaces
   // (frontdoor) or <uvm_reg::poke()> (backdoor) access.
   // If the register is mapped in multiple address maps and physical access
   // is used (front-door), an address ~map~ must be specified.
   //
   extern virtual task update(output uvm_status_e      status,
                              input  int               index,
                              input  uvm_path_e        path = UVM_DEFAULT_PATH,
                              input  uvm_reg_map       map = null,
                              input  uvm_sequence_base parent = null,
                              input  int               prior = -1,
                              input  uvm_object        extension = null,
                              input  string            fname = "",
                              input  int               lineno = 0);


   // Task: mirror
   //
   // If updated mirror value is the same as the reset value, no uvm_reg instance
   // is allocated. If the mirror values change from their default reset value, a
   // new uvm_reg instance is allocated for that register index.
   //
   // Read the register and update/check its mirror value
   //
   // Read the register and optionally compared the readback value
   // with the current mirrored value if ~check~ is <UVM_CHECK>.
   // The mirrored value will be updated using the <uvm_reg_array::predict()>
   // method based on the readback value.
   //
   // The mirroring can be performed using the physical interfaces (frontdoor)
   // or <uvm_reg_array::peek()> (backdoor).
   //
   // If ~check~ is specified as UVM_CHECK,
   // an error message is issued if the current mirrored value
   // does not match the readback value. Any field whose check has been
   // disabled with <uvm_reg_field::set_compare()> will not be considered
   // in the comparison. 
   //
   // If the register is mapped in multiple address maps and physical
   // access is used (front-door access), an address ~map~ must be specified.
   // If the register contains
   // write-only fields, their content is mirrored and optionally
   // checked only if a UVM_BACKDOOR
   // access path is used to read the register. 
   //
   extern virtual task mirror(output uvm_status_e      status,
                              input int                index,
                              input uvm_check_e        check  = UVM_NO_CHECK,
                              input uvm_path_e         path = UVM_DEFAULT_PATH,
                              input uvm_reg_map        map = null,
                              input uvm_sequence_base  parent = null,
                              input int                prior = -1,
                              input  uvm_object        extension = null,
                              input string             fname = "",
                              input int                lineno = 0);


   // Function: predict
   //
   // Update the mirrored value for the specified index in the register array.
   //
   // Predict the mirror value of the fields in the register
   // based on the specified observed ~value~ on a specified adress ~map~,
   // or based on a calculated value.
   // See <uvm_reg_field::predict()> for more details.
   //
   // Returns TRUE if the prediction was succesful for each field in the
   // register.
   //
   extern virtual function bit predict (int               index,
                                        uvm_reg_data_t    value,
                                        uvm_reg_byte_en_t be = -1,
                                        uvm_predict_e     kind = UVM_PREDICT_DIRECT,
                                        uvm_path_e        path = UVM_FRONTDOOR,
                                        uvm_reg_map       map = null,
                                        string            fname = "",
                                        int               lineno = 0);


   extern virtual function void reset(input int index,
                                      string kind = "HARD");


   //--------------------
   // Group: Standard Ops
   //--------------------

   extern virtual function void          do_print (uvm_printer printer);
   extern virtual function string        convert2string();
   extern virtual function uvm_object    clone      ();
   extern virtual function void          do_copy    (uvm_object rhs);
   extern virtual function bit           do_compare (uvm_object  rhs,
                                                     uvm_comparer comparer);
   extern virtual function void          do_pack    (uvm_packer packer);
   extern virtual function void          do_unpack  (uvm_packer packer);


   //-------------------------------
   // Group: Local utility functions
   //-------------------------------

   // Function: Xcheck_indexX
   //
   // Check whether the specified index is within array limits.
   // If not, print the message along with the caller of this function
   //
   extern local function void            Xcheck_indexX (int    index,
                                                        string caller);

   // Function: Xbuild_reg_indexX
   //
   // Check whether the regsiter at specified index is allocated.
   // If not, create a new register of type default_reg
   // Configure the created register
   //   Add the maps in default_reg
   //   Compute the offset and physical addresses and add
   //   uvm_reg_map_info to this register
   //
   extern local function void            Xbuild_reg_indexX (int  index);

endclass: uvm_reg_array


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

// new

function uvm_reg_array::new(string name="");
   super.new(name);
   //hdl_paths_pool = new("hdl_paths");
   m_locked = 0;
endfunction: new


// configure

function void uvm_reg_array::configure(uvm_reg_block blk_parent, uvm_reg_file regfile_parent, uvm_reg default_reg, int size, int inter_register_offset=-1, string hdl_path = "");
   `uvm_info("uvm_reg_array","configure started...",UVM_HIGH); 
   if(!m_locked) begin
      super.configure(blk_parent,regfile_parent,hdl_path);
      blk_parent.add_reg_array(this);
      this.m_default_reg = default_reg;
      this.m_size = size;
      this.m_inter_register_offset = inter_register_offset;
      this.m_hdl_path = hdl_path;
   end
endfunction: configure


// set_inter_register_offset

function void uvm_reg_array::set_inter_register_offset(int offset);
   if(!m_locked)
      m_inter_register_offset = offset;
endfunction: set_inter_register_offset


// Xlock_modelX

function void uvm_reg_array::Xlock_modelX();
   if (m_locked)
     return;
   m_locked = 1;
endfunction


// get_size

function int uvm_reg_array::get_size();
   return m_size;
endfunction: get_size


// get_reg

function uvm_reg uvm_reg_array::get_reg(int index);

   `uvm_info("uvm_reg_array",$sformatf("get_reg on index %0d called...",index),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"get_reg");
   
   // check whether the register needs to be built
   if(ral_regs[index] == null)
      Xbuild_reg_indexX(index);

   return ral_regs[index];

endfunction: get_reg


// get_default_reg

function uvm_reg uvm_reg_array::get_default_reg();

   `uvm_info("uvm_reg_array",$sformatf("get_default_reg called..."),UVM_HIGH);

   return m_default_reg;

endfunction: get_default_reg


//---------
// ACCESS
//---------


// set

function void uvm_reg_array::set(int             index,
                                 uvm_reg_data_t  value,
                                 string          fname = "",
                                 int             lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Setting index %0d with value %0h at %0t",index,value,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"set");
   
   // If the value is same as reset value, deallocate this index
   if(value == m_default_reg.get())
      ral_regs[index] = null;
   else begin
      // check whether the register needs to be built
      if(ral_regs[index] == null)
         Xbuild_reg_indexX(index);

      ral_regs[index].set(value, fname, lineno);    
   end

endfunction: set


// get

function uvm_reg_data_t uvm_reg_array::get(int     index,
                                           string  fname = "",
                                           int     lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Getting index %0d at %0t",index,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"get");
   
   // return reset value if the register is not built
   if(ral_regs[index] == null)
      return m_default_reg.get(fname, lineno);
   else
      return ral_regs[index].get(fname, lineno);    

endfunction: get


// predict

function bit uvm_reg_array::predict (int               index,
                                     uvm_reg_data_t    value,
                                     uvm_reg_byte_en_t be = -1,
                                     uvm_predict_e     kind = UVM_PREDICT_DIRECT,
                                     uvm_path_e        path = UVM_FRONTDOOR,
                                     uvm_reg_map       map = null,
                                     string            fname = "",
                                     int               lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Predict to index %0d with value %0h at %0t",index,value,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"predict");
   
   // check whether the register needs to be built
   if(ral_regs[index] == null)
      Xbuild_reg_indexX(index);

   ral_regs[index].predict(value, be, kind, path, map, fname, lineno);    

endfunction: predict


//-----------
// BUS ACCESS
//-----------

// write

task uvm_reg_array::write(output uvm_status_e      status,
                          input  int               index,
                          input  uvm_reg_data_t    value,
                          input  uvm_path_e        path = UVM_DEFAULT_PATH,
                          input  uvm_reg_map       map = null,
                          input  uvm_sequence_base parent = null,
                          input  int               prior = -1,
                          input  uvm_object        extension = null,
                          input  string            fname = "",
                          input  int               lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Writing to index %0d with value %0h at %0t",index,value,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"write");
   
   // check whether the register needs to be built
   if(ral_regs[index] == null)
      Xbuild_reg_indexX(index);

   ral_regs[index].write(status, value, path, map, parent, prior, extension, fname, lineno);    

endtask: write


// read

task uvm_reg_array::read(output uvm_status_e      status,
                         input  int               index,
                         output uvm_reg_data_t    value,
                         input  uvm_path_e        path = UVM_DEFAULT_PATH,
                         input  uvm_reg_map       map = null,
                         input  uvm_sequence_base parent = null,
                         input  int               prior = -1,
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Reading from index %0d at %0t",index,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"read");
   
   // check whether the register needs to be built
   if(ral_regs[index] == null)
      Xbuild_reg_indexX(index);

   ral_regs[index].read(status, value, path, map, parent, prior, extension, fname, lineno);    

   // If the read value is same as reset value, deallocate the register
   if (value == m_default_reg.get())
      ral_regs[index] = null;

endtask: read


// poke

task uvm_reg_array::poke(output uvm_status_e      status,
                         input  int               index,
                         input  uvm_reg_data_t    value,
                         input  string            kind = "",
                         input  uvm_sequence_base parent = null,
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Writing to index %0d with value %0h using poke at %0t",index,value,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"poke");
   
   // check whether the register needs to be built
   if(ral_regs[index] == null)
      Xbuild_reg_indexX(index);

   ral_regs[index].poke(status, value, kind, parent, extension, fname, lineno);    

endtask: poke


// peek

task uvm_reg_array::peek(output uvm_status_e      status,
                         input  int               index,
                         output uvm_reg_data_t    value,
                         input  string            kind = "",
                         input  uvm_sequence_base parent = null,
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Reading from index %0d using peek at %0t",index,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"peek");
   
   // check whether the register needs to be built
   if(ral_regs[index] == null)
      Xbuild_reg_indexX(index);

   ral_regs[index].peek(status, value, kind, parent, extension, fname, lineno);    

   // If the peek value is same as reset value, deallocate the register
   if (value == m_default_reg.get())
      ral_regs[index] = null;

endtask: peek


// mirror

task uvm_reg_array::mirror(output uvm_status_e       status,
                           input  int                index,
                           input  uvm_check_e        check = UVM_NO_CHECK,
                           input  uvm_path_e         path = UVM_DEFAULT_PATH,
                           input  uvm_reg_map        map = null,
                           input  uvm_sequence_base  parent = null,
                           input  int                prior = -1,
                           input  uvm_object         extension = null,
                           input  string             fname = "",
                           input  int                lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Mirroring index %0d at %0t",index,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"mirror");
   
   // If the register index is null, allocate, call mirror and deallocate
   // If it is not null, call mirror
   if(ral_regs[index] == null) begin
      Xbuild_reg_indexX(index);
      ral_regs[index].mirror(status, check, path, map, parent, prior, extension, fname, lineno);    
      ral_regs[index] = null;
   end else
      ral_regs[index].mirror(status, check, path, map, parent, prior, extension, fname, lineno);    

endtask: mirror


//update

task uvm_reg_array::update(output uvm_status_e      status,
                           input  int               index,
                           input  uvm_path_e        path = UVM_DEFAULT_PATH,
                           input  uvm_reg_map       map = null,
                           input  uvm_sequence_base parent = null,
                           input  int               prior = -1,
                           input  uvm_object        extension = null,
                           input  string            fname = "",
                           input  int               lineno = 0);

   `uvm_info("uvm_reg_array",$sformatf("Updating index %0d at %0t",index,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"update");
   
   // check whether the register needs to be built
   // If updated value is the same as reset value, allocate, call update and deallocate
   // TODO : This seems a bit expensive. When set is called with reset value of the register
   // we do deallocation, now we again do allocation and deallocation. allocation is an expensive
   // mechanism.
   if(ral_regs[index] == null) begin
      Xbuild_reg_indexX(index);

      ral_regs[index].update(status, path, map, parent, prior, extension, fname, lineno);    

      ral_regs[index] = null;
   end else
      ral_regs[index].update(status, path, map, parent, prior, extension, fname, lineno);    
   
endtask: update


// reset

function void uvm_reg_array::reset(input int index, string kind = "HARD");

   `uvm_info("uvm_reg_array",$sformatf("Resetting index %0d at %0t",index,$realtime),UVM_HIGH);

   // check whether the index is a valid array index
   Xcheck_indexX(index,"reset");
   
   // If the register is allocated, deallocate
   // If the register is not allocated, ignore
   ral_regs[index] = null;

endfunction: reset


//-------------
// STANDARD OPS
//-------------

// convert2string

function string uvm_reg_array::convert2string();
  `uvm_fatal("RegModel","RegModel register arrays cannot be converted to strings")
   return "";
endfunction: convert2string


// do_print

function void uvm_reg_array::do_print (uvm_printer printer);
  super.do_print(printer);
endfunction



// clone

function uvm_object uvm_reg_array::clone();
  `uvm_fatal("RegModel","RegModel register arrays cannot be cloned")
  return null;
endfunction

// do_copy

function void uvm_reg_array::do_copy(uvm_object rhs);
  `uvm_fatal("RegModel","RegModel register arrays cannot be copied")
endfunction


// do_compare

function bit uvm_reg_array::do_compare (uvm_object  rhs,
                                        uvm_comparer comparer);
  `uvm_warning("RegModel","RegModel register arrays cannot be compared")
  return 0;
endfunction


// do_pack

function void uvm_reg_array::do_pack (uvm_packer packer);
  `uvm_warning("RegModel","RegModel register arrays cannot be packed")
endfunction


// do_unpack

function void uvm_reg_array::do_unpack (uvm_packer packer);
  `uvm_warning("RegModel","RegModel register arrays cannot be unpacked")
endfunction


//----------------
// LOCAL FUNCTIONS
//----------------

// Xcheck_indexX

function void uvm_reg_array::Xcheck_indexX (int  index,
                                            string caller);
   if(index >= m_size)
       `uvm_fatal("RegModel",$sformatf("Invalid index '%0d' passed to '%s.%s'. Indices 0 - %0d are valid",index,this.get_full_name(),caller,m_size-1));
endfunction


// Xbuild_reg_indexX

function void uvm_reg_array::Xbuild_reg_indexX (int  index);
      uvm_reg_map maps[$];
      `uvm_info("uvm_reg_array",$sformatf("Creating index %0d as it is found to be null",index),UVM_HIGH);                      
      //ral_regs[index] = new($sformatf("ral_regs[%0d]",index),4,0);
      //ral_regs[0].copy(ral_regs[index]);
      ral_regs[index] = m_default_reg.allocate();
      //*JB* You should make a copy of the default register instance, not create a new one as we don’t know the type in the base class.
      `uvm_info("uvm_reg_array","Configuring the new created reg",UVM_HIGH);                      
      ral_regs[index].set_reg_array_parent(this.get_parent(),this);
      m_default_reg.get_maps(maps);
      for(int i = 0; i < maps.size ; i++) begin
         int unsigned bus_width;
         //int multiplier,reg_size,addr_unit_size;
	 // CAVM prevent wrapping
	 uvm_reg_addr_t multiplier,reg_size,addr_unit_size;
         uvm_reg_map top_map;
         uvm_reg_addr_t addrs[];
         uvm_reg_map_info info;
         uvm_reg_map_info temp;
         `uvm_info("uvm_reg_array",$sformatf("maps[%0d]=%s",i,maps[i].get_name()),UVM_HIGH);
         top_map = maps[i].get_root_map();
         ral_regs[index].add_map(maps[i]);
         temp = maps[i].get_reg_array_map_info(this);
         info = new;
         reg_size = m_default_reg.get_n_bytes();
         addr_unit_size = top_map.get_addr_unit_bytes();
         multiplier = (addr_unit_size >= reg_size) ? 1 : (reg_size-1)/addr_unit_size + 1;
         `uvm_info("uvm_reg_array",$sformatf("reg_size=%0d, addr_unit_size=%0d, multiplier=%0d, base_offset=%0d, incr=%0d",reg_size,addr_unit_size,multiplier,temp.offset,m_inter_register_offset),UVM_HIGH);
         if(m_inter_register_offset != -1) begin
            if(m_inter_register_offset < multiplier) begin
               `uvm_info("uvm_reg_array","inter-register offset ingored",UVM_MEDIUM);
               info.offset   = temp.offset + index * multiplier;
            end else   
               info.offset   = temp.offset + index * m_inter_register_offset;
         end else
            info.offset      = temp.offset + index * multiplier;
         `uvm_info("uvm_reg_array",$sformatf("Computed offset for index %0d is %0d",index,info.offset),UVM_HIGH);
         info.rights         = temp.rights;
         info.unmapped       = temp.unmapped;
         info.frontdoor      = temp.frontdoor;
         info.is_initialized = 1;
         `uvm_info("uvm_reg_map",$sformatf("top_map = %s",top_map.get_name()),UVM_HIGH);
         bus_width = top_map.get_physical_addresses(info.offset,0,ral_regs[index].get_n_bytes(),addrs);
         info.addr = addrs;
         maps[i].set_reg_map_info(ral_regs[index],info);
	 // CAVM need to register offset so get_reg_from_offset works
	 maps[i].m_set_reg_offset(ral_regs[index],info.offset,0);
      end
      begin
         uvm_hdl_path_concat paths[$];
         uvm_hdl_path_slice temp_slices[];
         m_default_reg.get_hdl_path(paths);
         foreach(paths[i]) begin
            temp_slices = paths[i].slices;
            foreach(temp_slices[k])
               temp_slices[k].path = {temp_slices[k].path,$sformatf("[%0d]",index)};
            ral_regs[index].add_hdl_path(temp_slices);
         end
         paths.delete();
      end
      begin   
         uvm_reg_backdoor urb,new_urb;
         urb = m_default_reg.get_backdoor();
         // check whether urb is null. If null, don't allocate and set_backdoor
         if(urb != null) begin
            `uvm_info("uvm_reg_array","backdoor exists",UVM_HIGH);
            new_urb = urb.allocate(index);
            ral_regs[index].set_backdoor(new_urb);
         end
      end
      ral_regs[index].reset();
      `uvm_info("uvm_reg_array",$sformatf("%p",ral_regs[index]),UVM_FULL);
endfunction


