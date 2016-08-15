// class: dist_chooser_c
// Create an instance of this type, parameterized to the objects to be
// pulled out. Call add_item() for each of the different values to be
// pulled, along with the distribution weight. Once all weights have
// been set, call configure.
// Thereafter, when a new value is required, call get_next(), and a
// value of the parameter type will be chosen randomly.
class dist_chooser_c#(type TYPE=int) extends uvm_object;
   `uvm_object_utils(cmn_pkg::dist_chooser_c#(TYPE))

   //----------------------------------------------------------------------------------------
   // Group: Fields

   // var: weights
   // All weights must be an integer, key is the TYPE
   int unsigned weights[TYPE];

   // var: values
   // The list of TYPE from which to choose
   TYPE values[$];

   // var: all_weights
   // All weights, as a list
   int unsigned all_weights[$];

   //----------------------------------------------------------------------------------------
   // Group: Methods
   // func: new
   function new(string name="dist_chooser");
      super.new(name);
   endfunction : new

   ////////////////////////////////////////////
   // func: add_item
   // Merely adds to the weights variable
   virtual function void add_item(int _weight,
                                  TYPE _typ);
      weights[_typ] = _weight;
      all_weights.push_back(_weight);
   endfunction : add_item

   ////////////////////////////////////////////
   // func: configure
   // Create the values list from which to choose
   virtual function void configure();
      int unsigned gcf = find_gcf_list(all_weights);
      values.delete();
      foreach(weights[idx]) begin
         int unsigned rnum = weights[idx] / gcf;
         repeat(rnum)
            values.push_back(idx);
      end
   endfunction : configure

   ////////////////////////////////////////////
   // func: find_gcf_list
   // Find the gcf of a list of values. Do so via recursion, noting that
   //   gcf(a, b, c) = gcf(a, gcf(b, c))
   // NOTE: This could be moved to a math_pkg
   virtual function int unsigned find_gcf_list(ref int unsigned _list[$]);
      case(_list.size())
         0 : return 1;
         1 : return _list[0];
         2 : return find_gcf(_list[0], _list[1]);
         default: begin
            int unsigned rest_of_list[$] = _list[1:$];
            return find_gcf(_list[0], find_gcf_list(rest_of_list));
         end
      endcase
   endfunction : find_gcf_list

   ////////////////////////////////////////////
   // func: find_gcf
   // Find the gcf between two numbers
   // NOTE: This could be moved to a math_pkg
   virtual function int unsigned find_gcf(int unsigned _alpha,
                                          int unsigned _beta);
      int unsigned div = _alpha;
      int unsigned rem = _beta;
      int unsigned prev_rem;
      while(rem != 0) begin
         prev_rem = rem;
         rem = div % rem;
         div = prev_rem;
      end
      return prev_rem;
   endfunction : find_gcf

   ////////////////////////////////////////////
   // func: is_configured
   // Returns true if the values queue has at least something in it
   virtual function bit is_configured();
      return(values.size() > 0);
   endfunction : is_configured

   ////////////////////////////////////////////
   // func: get_next
   // Return a random choice based on the weights.
   virtual function TYPE get_next();
      int unsigned rand_idx;
      assert(is_configured()) else
         `cmn_fatal(("There is nothing to choose from."))
      rand_idx = $urandom_range(values.size()-1);
      return(values[rand_idx]);
   endfunction : get_next
endclass : dist_chooser_c
