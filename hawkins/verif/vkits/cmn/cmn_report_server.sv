
// ***********************************************************************
// File:   cmn_report_server.sv
// Author: bhunter
/* About:  Basic test extends the base test and starts a training sequence
           on both the RX and TX agent. This is done here to show that
           numerous sequences can be started independently on a chaining
           sequencer.
   Copyright (C) 2015-2016  Brian P. Hunter, Cavium
   *************************************************************************/

`ifndef __CMN_REPORT_SERVER_SV__
   `define __CMN_REPORT_SERVER_SV__

`ifdef UVM_MAJOR_VERSION_1_1
   `include "cmn_report_server_1_1.sv"
`endif // UVM_MAJOR_VERSION_1_1

`ifdef UVM_MAJOR_VERSION_1_2
   `include "cmn_report_server_1_2.sv"
`endif // UVM_MAJOR_VERSION_1_2

`endif // __CMN_REPORT_SERVER_SV__
