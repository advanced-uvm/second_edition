
// ***********************************************************************
// File:   hawk_phy_idle_seq.sv
// Author: bhunter
/* About:  Sends in training sequences every 2 us. Uses grab/ungrab
           because these run at the highest priority and must be
           consecutive.
   Copyright (C) 2015-2016  Brian P. Hunter
   *************************************************************************/

`ifndef __HAWK_PHY_IDLE_SEQ_SV__
   `define __HAWK_PHY_IDLE_SEQ_SV__

`include "hawk_types.sv"
`include "hawk_phy_item.sv"

class phy_idle_seq_c extends uvm_sequence #(phy_item_c, phy_item_c);
   `uvm_object_utils(hawk_pkg::phy_idle_seq_c)

   //----------------------------------------------------------------------------------------
   // Group: Methods
   function new(string name="phy_train_seq");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: body
   virtual task body();
      byte unsigned idle_cnt = 0;
      phy_item_c idle_item;

      forever begin
         `uvm_do_pri_with(idle_item, IDLE_PRI, {
             valid == 0;
             data == idle_cnt;
         })
         idle_cnt = (idle_cnt == 'hF0)? 0 : idle_cnt + 1;
      end
   endtask : body
endclass : phy_idle_seq_c

`endif // __HAWK_PHY_IDLE_SEQ_SV__

