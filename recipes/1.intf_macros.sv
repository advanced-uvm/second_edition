`define cmn_set_intf(TYPE, RSRC, NAME, INSTANCE)                                     \
   begin uvm_resource_db#(TYPE)::set(RSRC, NAME, INSTANCE); end

`define cmn_get_intf(TYPE, RSRC, NAME, VARIABLE)                                     \
   begin                                                                             \
      if(!uvm_resource_db#(TYPE)::read_by_name(RSRC, NAME, VARIABLE))                \
         `cmn_err(("%s.%s interface not found in resource database.", RSRC, NAME));  \
   end
