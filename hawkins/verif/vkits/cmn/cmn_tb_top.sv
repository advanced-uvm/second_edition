
// ***********************************************************************
// File:   cmn_tb_top.sv
// Author: bhunter
/* About:  `include this file into your tb_top
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

   initial begin : fsdb_setup
      if($test$plusargs("fsdb_trace")) begin
         string fsdb_outfile = "sim.fsdb";
         int fsdb_depth=0;
         $value$plusargs("fsdb_outfile=%s", fsdb_outfile);
         $value$plusargs("fsdb_depth=%d", fsdb_depth);
         $fsdbDumpvars(fsdb_depth, $root.tb_top, "+all", $sformatf("+fsdbfile+%s", fsdb_outfile));
      end
   end : fsdb_setup

   /////////////////////////////////////////////////////////////////////////////
   // 1. replace the UVM report server with our cavium one.
   //    and set the timeformat
   // 2. call pre_run_test(). testbenches MUST override this with any functionality
   //    that should occur before run_test.
   // 3. call run_test.
   /////////////////////////////////////////////////////////////////////////////
   initial begin : start_uvm
      cmn_pkg::report_server_c       report_server;

      // all "%t" shall print out in ns format with 9 digits and 3 decimal places
      $timeformat(-9,3,"ns",13);

      report_server = cmn_pkg::report_server_c::type_id::create();
      uvm_pkg::uvm_report_server::set_server(report_server);

      // testbenches must create this zero-time function
      pre_run_test();
      run_test();
   end : start_uvm

   ////////////////////////////////////////////
   // Needed for UVM 1.1c
   // turn these warnings off: UVM/FLD/SET/BSY
   ////////////////////////////////////////////
   initial begin
      #(1ps);
      uvm_root::get().set_report_severity_id_action_hier(UVM_WARNING, "UVM/FLD/SET/BSY", UVM_NO_ACTION);
      uvm_root::get().set_report_severity_id_action_hier(UVM_WARNING, "Connection Warning", UVM_NO_ACTION);
      uvm_root::get().set_report_severity_id_action_hier(UVM_ERROR, "SEQREQZMB", UVM_NO_ACTION);
   end

