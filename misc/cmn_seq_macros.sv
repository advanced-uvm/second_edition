////////////////////////////////////////////
// macro: `cmn_seq_raise
// Handy macro to ensure that all sequences raise the phase's objection if they are the default phase.
`ifdef UVM_MAJOR_VERSION_1_1
   `define cmn_seq_raise                                \
      begin                                             \
         if(starting_phase)                             \
            starting_phase.raise_objection(this);       \
      end
`endif

`ifdef UVM_MAJOR_VERSION_1_2
   `define cmn_seq_raise                                \
      begin                                             \
         if(get_starting_phase())                       \
            get_starting_phase().raise_objection(this); \
      end
`endif

////////////////////////////////////////////
// macro: `cmn_seq_drop
// Handy macro to ensure that all sequences drop the phase's objection if they are the default phase.
`ifdef UVM_MAJOR_VERSION_1_1
   `define cmn_seq_drop                                 \
      begin                                             \
         if(starting_phase)                             \
            starting_phase.drop_objection(this);        \
      end
`endif

`ifdef UVM_MAJOR_VERSION_1_2
   `define cmn_seq_drop                                 \
      begin                                             \
         if(get_starting_phase())                       \
            get_starting_phase().drop_objection(this);  \
      end
`endif
