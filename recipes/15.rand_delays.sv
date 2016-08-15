class rand_delays_c extends uvm_object;
   //----------------------------------------------------------------------------------------
   // Group: Types

   // enum: traffic_type_e
   // Allows for a variety of delay types
   typedef enum {
      FAST_AS_YOU_CAN,
      REGULAR,
      BURSTY
   } traffic_type_e;

   typedef int unsigned delay_t;

   `uvm_object_utils_begin(cmn_pkg::rand_delays_c)
      `uvm_field_enum(traffic_type_e, traffic_type,UVM_DEFAULT)
      `uvm_field_int(min_delay,                    UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(max_delay,                    UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(burst_on_min,                 UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(burst_on_max,                 UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(burst_off_min,                UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(burst_off_max,                UVM_DEFAULT | UVM_DEC)
      `uvm_field_int(wait_timescale,               UVM_DEFAULT | UVM_DEC)
   `uvm_object_utils_end

   //----------------------------------------------------------------------------------------
   // Group: Random Fields

   // var: traffic_type
   rand traffic_type_e traffic_type;

   // var: min_delay, max_delay
   // Delays used for REGULAR traffic types
   rand delay_t min_delay, max_delay;

   // var: burst_on_min, burst_on_max
   // Knobs that control the random length of bursty traffic
   rand delay_t burst_on_min, burst_on_max;

   // var: burst_off_min, burst_off_max
   // Knobs that control how long a burst will be off
   rand delay_t burst_off_min, burst_off_max;

   // var: wait_timescale
   // The timescale to use when wait_next_delay is called
   time wait_timescale = 1ns;

   //----------------------------------------------------------------------------------------
   // Group: Local Fields

   // var: burst_on_time
   // When non-zero, currently burst mode is on for this many more calls
   delay_t burst_on_time = 1;

   //----------------------------------------------------------------------------------------
   // Group: Constraints

   // constraint: delay_L0_cnstr
   // Level 0: Keep min knobs <= max knobs
   constraint delay_L0_cnstr {
      traffic_type == REGULAR -> (min_delay <= max_delay);
      traffic_type == BURSTY -> (burst_on_min <= burst_on_max) && (burst_off_min <= burst_off_max);
   }

   // constraint: delay_L1_cnstr
   // Level 1: Safe delays
   constraint delay_L1_cnstr {
      max_delay <= 500;
      burst_on_max <= 500;
      burst_off_max <= 500;
   }

   //----------------------------------------------------------------------------------------
   // Group: Methods

   ////////////////////////////////////////////
   // func: new
   function new(string name="rand_delay");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: get_next_delay
   // Return the length of the next delay
   virtual function delay_t get_next_delay();
      case(traffic_type)
         FAST_AS_YOU_CAN: get_next_delay = 0;
         REGULAR: begin
            std::randomize(get_next_delay) with {
               get_next_delay inside {[min_delay:max_delay]};
            };
         end
         BURSTY: begin
            if(burst_on_time) begin
               burst_on_time -= 1;
               get_next_delay = 0;
            end else begin
               std::randomize(get_next_delay) with {
                  get_next_delay inside {[burst_off_min:burst_off_max]};
               };
               std::randomize(burst_on_time) with {
                  burst_on_time inside {[burst_on_min:burst_on_max]};
               };
            end
         end
      endcase
   endfunction : get_next_delay

   ////////////////////////////////////////////
   // func: wait_next_delay
   // Wait for the next random period of time, based on the timescale provided
   virtual task wait_next_delay();
      delay_t delay = get_next_delay();
      #(delay * wait_timescale);
   endtask : wait_next_delay
endclass : rand_delays_c
