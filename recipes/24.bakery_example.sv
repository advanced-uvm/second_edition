// ***********************************************************************
// File:   24.bakery_example.sv
// Author: bhunter
/* About:
   Copyright (C) 2015-2016  Brian P. Hunter
 *************************************************************************/

`ifndef __24_BAKERY_EXAMPLE_SV__
   `define __24_BAKERY_EXAMPLE_SV__

localparam NUM_BAKERS = 4;
localparam NUM_CUSTOMERS = 50;

// enum: doughnut_phases_e
// Customers make requests, bakers hand out bags, and orders get completed
typedef enum {
    REQ_START, ORDER_STARTED, ORDER_COMPLETE
} doughnut_phases_e;

//****************************************************************************************
class doughnut_c extends uvm_object;
   `uvm_object_utils(doughnut_c)

   // enum: doughnut_type_e
   typedef enum {
       POWDERED, CHOCOLATE, PINK_FROSTED
   } doughnut_type_e;

   // var: doughnut_type
   // What type of doughnut this is
   rand doughnut_type_e doughnut_type;

   ////////////////////////////////////////////
   // func: new
   // Create this doughnut
   function new(string name="doughnut");
      super.new(name);
   endfunction : new
endclass : doughnut_c

//****************************************************************************************
// class: doughnut_req_c
// A request for doughnuts, and all of the yummy doughnuts once fulfilled
class doughnut_req_c extends uvm_object;
   `uvm_object_utils(doughnut_req_c)

   // var: customer_id
   // A customer_id to match orders
   int unsigned customer_id = 0;

   // var: req_count
   rand byte unsigned req_count;

   // constraint: req_count_cnstr
   // Keep it below 20
   constraint req_count_cnstr {
      req_count inside {[1:20]};
   }

   // var: doughnuts
   // An queue of doughnuts
   doughnut_c doughnuts[$];

   function new(string name="item");
      super.new(name);
   endfunction : new
endclass : doughnut_req_c

//****************************************************************************************
// class: hungry_customers_c
// Sends in 50 separate orders to the bakery and waits for all the yummy doughnuts
class hungry_customers_c extends uvm_agent;
   `uvm_component_utils(hungry_customers_c)

   // var: requests
   // All of the outstanding requests
   doughnut_req_c requests[int unsigned];

   // var: socket
   // request doughnuts
   uvm_tlm_nb_initiator_socket#(hungry_customers_c, doughnut_req_c, doughnut_phases_e) socket;

   // var: request_completed
   // Emitted once baker has provided all doughnuts requested
   event request_completed;

   //----------------------------------------------------------------------------------------
   // Group: Functions
   function new(string name="hungry_customers",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new
   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      socket = new("socket", this);
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: main_phase
   // send items out b_port
   virtual task main_phase(uvm_phase phase);
      phase.raise_objection(this);

      for(int customer_id=0; customer_id < NUM_CUSTOMERS; customer_id++)
         make_request(customer_id);

      // wait for all requests to be fulfilled
      wait(requests.size() == 0);
      phase.drop_objection(this);
   endtask : main_phase

   ////////////////////////////////////////////
   // func: make_request
   // Make a request for a random number of donuts
   virtual function void make_request(int unsigned _customer_id);
      uvm_tlm_sync_e status;
      doughnut_phases_e d_phase = REQ_START;
      uvm_tlm_time delay = new();
      doughnut_req_c d_req = new("d_req");
      d_req.customer_id = _customer_id;
      d_req.randomize();
      `cmn_info(("Customer #%0d Requesting: %0d", _customer_id, d_req.req_count))
      status = socket.nb_transport_fw(d_req, d_phase, delay);
      requests[_customer_id] = d_req;
   endfunction : make_request

   ////////////////////////////////////////////
   // func: request_complete
   // Eat doughnuts, remove request
   virtual function void request_complete(int unsigned _customer_id);
      doughnut_req_c request = requests[_customer_id];
      foreach(request.doughnuts[dnum])
         `cmn_info(("Customer #%0d Yummy! I'm eating a %s.", _customer_id,
                   request.doughnuts[dnum].doughnut_type))
      requests.delete(_customer_id);
   endfunction : request_complete

   ////////////////////////////////////////////
   // func: nb_transport_bw
   // Receives the item back
   virtual function uvm_tlm_sync_e nb_transport_bw(doughnut_req_c _d_req,
                                                   doughnut_phases_e _phase,
                                                   uvm_tlm_time _delay);
      if(_phase == ORDER_COMPLETE) begin
         if(_d_req.doughnuts.size() != _d_req.req_count)
            `cmn_err(("Customer #%0d: Hey! You still owe me!", _d_req.customer_id))
         else
            request_complete(_d_req.customer_id);
         return UVM_TLM_COMPLETED;
      end else begin
         `cmn_info(("Customer #%0d: I've only got %0d/%0d doughnuts so far.",
            _d_req.customer_id, _d_req.doughnuts.size(), _d_req.req_count))
         return UVM_TLM_ACCEPTED;
      end
   endfunction : nb_transport_bw
endclass : hungry_customers_c

//****************************************************************************************
// class: bakery_c
// A bakery has NUM_BAKERS, each of which takes orders for doughnuts and makes them.
// Sending as many as 6 at a time.
class bakery_c extends uvm_agent;
   `uvm_component_utils(bakery_c)

   // var: socket
   // Receives doughnut requests
   uvm_tlm_nb_target_socket#(bakery_c, doughnut_req_c, doughnut_phases_e) socket;

   // var: orders
   // All doughnut orders per baker
   mailbox#(doughnut_req_c) orders[NUM_BAKERS];

   //----------------------------------------------------------------------------------------
   // Group: Functions
   function new(string name="baker",
                uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

   ////////////////////////////////////////////
   // func: build_phase
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      socket = new("socket", this);
      foreach(orders[baker_num])
         orders[baker_num] = new();
   endfunction : build_phase

   ////////////////////////////////////////////
   // func: run_phase
   // Making doughnuts!
   virtual task run_phase(uvm_phase phase);
      fork
         foreach(orders[baker_num]) begin
            automatic int _baker_num = baker_num;
            fork
               baker(_baker_num);
            join_none
         end
      join
   endtask : run_phase

   ////////////////////////////////////////////
   // func: baker
   // Maker of doughnuts
   virtual task baker(int _baker_num);
      doughnut_phases_e d_phase;
      uvm_tlm_time delay = new();
      uvm_tlm_sync_e status;
      doughnut_req_c current_order;
      byte unsigned req_count;
      bit done_baking;
      byte unsigned made_so_far;

      forever begin
         orders[_baker_num].get(current_order);
         `cmn_info(("Baker #%0d making %0d doughnuts.", _baker_num, current_order.req_count))

         req_count = current_order.req_count;
         repeat(req_count) begin
            doughnut_c doughnut = new("doughnut");
            #(5ns); // wow! that's a fast oven!
            doughnut.randomize();
            current_order.doughnuts.push_back(doughnut);
            made_so_far = current_order.doughnuts.size();
            done_baking = made_so_far == req_count;
            // send full bags or the last bag of doughnuts
            // each bag can hold up to 6
            if(done_baking || (made_so_far % 6 == 0)) begin
               d_phase = done_baking? ORDER_COMPLETE : ORDER_STARTED;
               `cmn_info(("Baker #%0d sending %0d doughnuts", _baker_num, made_so_far))
               status = socket.nb_transport_bw(current_order, d_phase, delay);
            end
         end
      end
   endtask : baker

   ////////////////////////////////////////////
   // func: nb_transport_fw
   // Receives the doughnut requests, and sends them to a random baker
   virtual function uvm_tlm_sync_e nb_transport_fw(doughnut_req_c _d_req,
                                                   doughnut_phases_e _phase,
                                                   uvm_tlm_time _delay);
      int b_num;
      // pick a random baker
      std::randomize(b_num) with { b_num inside {[0:NUM_BAKERS-1]}; };
      `cmn_info(("Received an order for %0d doughnuts. Sending to Baker #%0d",
                _d_req.req_count, b_num))
      orders[b_num].try_put(_d_req);
      return UVM_TLM_ACCEPTED;
   endfunction : nb_transport_fw
endclass : bakery_c

`endif // __24_BAKERY_EXAMPLE_SV__
