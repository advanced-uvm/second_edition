// typedefs for arrays
typedef byte unsigned      ubyte_t;
typedef byte               byte_arr_t[];
typedef byte unsigned      ubyte_arr_t[];
typedef int                int_arr_t[];
typedef int unsigned       uint_arr_t[];

// typedefs for queues. want more? add more.
typedef byte unsigned      ubyteq_t[$];
typedef byte               byteq_t[$];
typedef int                intq_t[$];
typedef int unsigned       uintq_t[$];

//****************************************************************************************
// class: arr_sprinter_c
class arr_sprinter_c #(type TYPE=byte_arr_t);
   ////////////////////////////////////////////
   // func: sprint
   // Returns an array as a pretty string
   function automatic string sprint_array(ref TYPE _arr);
      sprint_array = $sformatf("\n[%0d bytes]\n", _arr.size());

      foreach(_arr[idx]) begin
         if((idx % 8) == 0)
            sprint_array = $sformatf("%s.%03d  ", sprint_array, idx);
         sprint_array = $sformatf("%s %02X", sprint_array, _arr[idx]);
         if(((idx+1) % 8 == 0))
            sprint_array = {sprint_array, "\n"};
      end
      sprint_array = {sprint_array, "\n"};
   endfunction : sprint
endclass : arr_sprinter_c

////////////////////////////////////////////
// Convenient static singletons
static arr_sprinter_c#(byte_arr_t)    byte_arr_sprinter_c    = new();
static arr_sprinter_c#(ubyte_arr_t)   ubyte_arr_sprinter_c   = new();
static arr_sprinter_c#(bit8_arr_t)    bit8_arr_sprinter_c    = new();
static arr_sprinter_c#(bit16_arr_t)   bit16_arr_sprinter_c   = new();
static arr_sprinter_c#(int_arr_t)     int_arr_sprinter_c     = new();
static arr_sprinter_c#(uint_arr_t)    uint_arr_sprinter_c    = new();
static arr_sprinter_c#(ubyteq_t)      ubyteq_sprinter_c      = new();
static arr_sprinter_c#(byteq_t)       byteq_sprinter_c       = new();
static arr_sprinter_c#(bit16q_t)      bit16q_sprinter_c      = new();
static arr_sprinter_c#(intq_t)        intq_sprinter_c        = new();
static arr_sprinter_c#(uintq_t)       uintq_sprinter_c       = new();

////////////////////////////////////////////
// Macros for all to use
`define cmn_byte_arr_sprint(DATA)     cmn_pkg::byte_arr_sprinter_c::sprint_array(DATA)
`define cmn_ubyte_arr_sprint(DATA)    cmn_pkg::ubyte_arr_sprinter_c::sprint_array(DATA)
`define cmn_bit8_arr_sprint(DATA)     cmn_pkg::bit8_arr_sprinter_c::sprint_array(DATA)
`define cmn_bit16_arr_sprint(DATA)    cmn_pkg::bit16_arr_sprinter_c::sprint_array(DATA)
`define cmn_int_arr_sprint(DATA)      cmn_pkg::int_arr_sprinter_c::sprint_array(DATA)
`define cmn_uint_arr_sprint(DATA)     cmn_pkg::uint_arr_sprinter_c::sprint_array(DATA)
`define cmn_ubyteq_sprint(DATA)       cmn_pkg::ubyteq_sprinter_c::sprint_array(DATA)
`define cmn_byteq_sprint(DATA)        cmn_pkg::byteq_sprinter_c::sprint_array(DATA)
`define cmn_bit16q_sprint(DATA)       cmn_pkg::bit16q_sprinter_c::sprint_array(DATA)
`define cmn_intq_sprint(DATA)         cmn_pkg::intq_sprinter_c::sprint_array(DATA)
`define cmn_uintq_sprint(DATA)        cmn_pkg::uintq_sprinter_c::sprint_array(DATA)