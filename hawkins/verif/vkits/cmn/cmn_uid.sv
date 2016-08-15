// ***********************************************************************
// File:   cmn_uid.sv
// Author: bhunter
/* About:  Unique Identifiers
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __CMN_UID_SV__
   `define __CMN_UID_SV__

// class: uid_c
class uid_c extends uvm_object;
   `uvm_object_utils(cmn_pkg::uid_c)

   //----------------------------------------------------------------------------------------
   // Group: Fields
   // var: next_id_num
   // The next number for the given identifier
   static int unsigned next_id_num[string];

   // var: prefix
   // The identifying string
   string prefix;

   // var: my_id
   // The UID for this instance
   int unsigned my_id;

   // var: parent
   // When set, this UID is a sub-id
   uid_c parent;

   //----------------------------------------------------------------------------------------
   // Group: Methods
   // func: new
   // Create a unique ID and assign its ID
   function new(string name="uid");
      super.new(name);
      prefix = name;
      if(next_id_num.exists(prefix))
         next_id_num[prefix] += 1;
      else
         next_id_num[prefix] = 0;
      my_id = next_id_num[prefix];
   endfunction : new

   ////////////////////////////////////////////
   // func: new_subid
   // Used as a sub-identifier of another unique id
   virtual function uid_c new_subid(string _prefix="");
      string new_name = $sformatf("%s.%s", convert2string(), _prefix);
      new_subid = new(new_name);
      new_subid.parent = this;
      return new_subid;
   endfunction : new_subid

   ////////////////////////////////////////////
   // func: convert2string
   // Return this unique ID as a string
   virtual function string convert2string();
      return ($sformatf("%s:%06d", prefix, my_id));
   endfunction : convert2string
endclass : uid_c

`endif // __CMN_UID_SV__
