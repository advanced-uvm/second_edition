
// ***********************************************************************
// File:   hawk_phy_train_seq.sv
// Author: bhunter
/* About:  Sends in training sequences every 2 us. Uses grab/ungrab
           because these run at the highest priority and must be
           consecutive.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_PHY_TRAIN_SEQ_SV__
   `define __HAWK_PHY_TRAIN_SEQ_SV__

`include "hawk_types.sv"
`include "hawk_phy_item.sv"

class phy_train_seq_c extends uvm_sequence #(phy_item_c, phy_item_c);
   `uvm_object_utils(hawk_pkg::phy_train_seq_c)

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="phy_train_seq");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   virtual task body();
      phy_item_c train_item;

      forever begin
         #(2us);
         `cmn_info(("Sending Training Sequence"))
         repeat(4) begin
            `uvm_do_pri_with(train_item, TRAIN_PRI, {
               valid == 0;
               data == TRAIN;
            })
         end
      end
   endtask : body
endclass : phy_train_seq_c

`endif // __HAWK_PHY_TRAIN_SEQ_SV__

