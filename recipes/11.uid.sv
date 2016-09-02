// ***********************************************************************
// File:   11.uid.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
 *************************************************************************/

`ifndef __11_UID_SV__
   `define __11_UID_SV__

class uid_c extends uvm_object;
   `uvm_object_utils(cmn_pkg::uid_c)
   //----------------------------------------------------------------------------------------
   // Group: Fields
   // var: next_id_num
   // The next number for the given identifier
   static int unsigned next_id_num[string];

   // var: my_id
   // The UID for this instance
   int unsigned my_id;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   // func: new
   // Create a unique ID and assign its ID
   function new(string name="uid");
      super.new(name);
      if(next_id_num.exists(name))
         next_id_num[name] += 1;
      else
         next_id_num[name] = 0;
      my_id = next_id_num[name];
   endfunction : new

   ////////////////////////////////////////////
   // func: convert2string
   // Return this unique ID as a string
   virtual function string convert2string();
      convert2string = $sformatf("%s:%05d", get_name(), my_id);
   endfunction : convert2string
endclass : uid_c

`endif // __11_UID_SV__
