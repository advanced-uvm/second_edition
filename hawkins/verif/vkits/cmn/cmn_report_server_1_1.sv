
// ***********************************************************************
// File:   cmn_report_server_1_1.sv
// Author: bhunter
/* About:  Basic test extends the base test and starts a training sequence
           on both the RX and TX agent. This is done here to show that
           numerous sequences can be started independently on a chaining
           sequencer.
   Copyright (C) 2015-2016  Cavium, Inc. All rights reserved.
   *************************************************************************/


`ifndef __CMN_REPORT_SERVER_1_1_SV__
   `define __CMN_REPORT_SERVER_1_1_SV__

   //****************************************************************************************
   // class: cmn_report_server
   class report_server_c extends uvm_report_server;
      `uvm_object_utils(cmn_pkg::report_server_c)

      //----------------------------------------------------------------------------------------
      // Fields

      // cached versions of things
      string                               filename_cache[string];
      string                               name_cache[string];

      // field: max_id_len
      // A nuclear bomb.
      int                                  max_id_len;

      // field: max_flen
      // The maximum width of the filename column (0 for off)
      int unsigned                         max_flen;

      // field: full_comp_hier
      // Display the full component hierarchy?
      bit                                  full_comp_hier;

      // field: empty_str
      // Used for filenames that have no filename length at all
      string                               empty_str;

      //----------------------------------------------------------------------------------------
      // Methods
      function new(string name="report_server");
         string                            space_char = " ";
         super.new();

         // turn off report counts by ID
         enable_report_id_count_summary = 0;

         //Don't set dbglen on the command line, please use IDLEN instead
         if(!$value$plusargs("dbglen=%d", max_id_len))
           max_id_len = 30;

         //Don't set filelen on the command-line, pluse use FLEN instead
         if(!$value$plusargs("filelen=%d", max_flen))
            max_flen = 18;
         empty_str = {(max_flen){space_char}};

         if(!$test$plusargs("fullcomphier"))
           full_comp_hier = 0;
         else
           full_comp_hier = 1;
      endfunction : new

      ////////////////////////////////////////////
      virtual function string compose_message(uvm_severity severity,
                                              string name,
                                              string id,
                                              string message,
                                              string filename,
                                              int    line
                                              );

         uvm_severity sv;
         string                                      prefix;    // everything before the message
         string                                      code_str;  // %E-, %I-, %F-, etc.
         string                                      fill_char;
         string                                      file_str;
         string                                      name_str;
         string                                      file_tok;
         string                                      name_tok;
         string                                      time_tok;
         string                                      full_hier_tok;

         ////////////////////////////////////////////
         // format filename
         // truncate filename by removing up to last slash
         // cache the results in a static assoc array
         if(max_flen == 0)
            file_tok = "";
         else begin
            if(filename_cache.exists(filename))
               file_str = filename_cache[filename];
            else begin
      `ifdef CmN_DBG_FILENAME_PATHS
               file_str = filename;
      `else
               if (filename.len() == 0) begin
                  file_str = empty_str;
               end else begin
                  int last_slash = filename.len()-1;
                  int flen;

                  while(filename[last_slash] != "/" && last_slash != 0) begin
                     last_slash--;
                  end
                  if(filename[last_slash] == "/") begin
                     file_str = filename.substr(last_slash+1, filename.len()-1);
                  end
                  else begin
                    file_str = filename;
                  end
                  flen = file_str.len();
                  if(flen > max_flen) begin
                     file_str = file_str.substr((flen - max_flen), flen-1);
                     file_str[0] = "+";
                  end
                  if(flen < max_flen) begin
                     string space_char = " ";
                     file_str = {{(max_flen-flen){space_char}}, file_str};
                  end
               end
      `endif
               filename_cache[filename] = file_str;
            end

            file_tok = $sformatf("(%s:%4d)",file_str, line);
         end

         ////////////////////////////////////////////
         // format name
         if(max_id_len == 0) begin
            //do nothing
         end else if(name_cache.exists(name)) begin
            name_str = name_cache[name];
            name_tok = $sformatf("[%s]",name_str);
         end else begin
            int name_len = name.len();

            // if name starts with uvm_test_top., then remove that
            if(name_len > 13 && name.substr(0,12) == "uvm_test_top.") begin
               name = name.substr(13, name_len-1);
               name_len -= 13;
            end

            if(name_len < max_id_len) begin
               // left-justify the name, and pad on the right with spaces, if the name is smaller
               string space_char = " ";
               name_str = {name, {(max_id_len - name_len){space_char}}};

            end else if(name_len > max_id_len) begin
               // if the name is bigger then take the right-snamee, which is more interesting
               name_str = name.substr(name_len - max_id_len, name_len - 1);
               name_str[0] = "+";

            end else
               name_str = name;

            // save to cache
            name_cache[name] = name_str;

            name_tok = $sformatf("[%s]",name_str);
         end


         time_tok = $sformatf("{%11.3f}",$realtime()/real'(1ns));

         ////////////////////////////////////////////
         // fill character and code string
         // determine fill character
         sv = uvm_severity'(severity);
         case(sv)
            UVM_INFO:    begin code_str = "%I-"; fill_char = " "; end
            UVM_ERROR:   begin code_str = "%E-"; fill_char = "_"; end
            UVM_WARNING: begin code_str = "%W-"; fill_char = "."; end
            UVM_FATAL:   begin code_str = "%F-"; fill_char = "*"; end
            default:     begin code_str = "%?-"; fill_char = "?"; end
         endcase

         ////////////////////////////////////////////
         // create line's prefix (everything up to time)
         prefix = {code_str,file_tok,name_tok,time_tok};
         if(fill_char != " ") begin
            for(int x = 0; x < prefix.len(); x++)
               if(prefix[x] == " ")
                  prefix.putc(x, fill_char);
         end

         if(full_comp_hier == 1) begin
            if(name.substr(0,3) != "vlog") begin
               full_hier_tok = $sformatf(" [%s]",name);
            end
         end

         ////////////////////////////////////////////
         // append message
         return {prefix, " ", message, full_hier_tok};
      endfunction : compose_message

      ////////////////////////////////////////////
      virtual function void report(uvm_severity severity,
                                   string name,
                                   string id,
                                   string message,
                                   int verbosity_level,
                                   string filename,
                                   int line,
                                   uvm_report_object client
                                   );

         // Force fatal, error, and warning reports to have verbosity NONE so they can't get
         // supressed.  The `cmn_err/cmn_fatal macros always set verbosity to NONE,
         // but third-party IP that calls uvm_report_error might not.
         if(severity inside {UVM_ERROR, UVM_FATAL, UVM_WARNING})
            verbosity_level = 0;
         super.report(severity, name, id, message, verbosity_level, filename, line, client);
      endfunction : report

   endclass : report_server_c

`endif // __CMN_REPORT_SERVER_1_1_SV__

