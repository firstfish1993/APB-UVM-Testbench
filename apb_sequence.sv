`include "uvm_macros.svh"
package sequences;
import uvm_pkg::*;
import rw_trans::*;

//------------------------
//Base APB sequence derived from uvm_sequence and parameterized with sequence item of type apb_rw
//------------------------
class apb_base_seq extends uvm_sequence#(apb_rw);

  `uvm_object_utils(apb_base_seq)

  function new(string name ="");
    super.new(name);
  endfunction


  //Main Body method that gets executed once sequence is started
  task body();
    apb_rw tx;
    repeat(10000) begin
      tx = apb_rw::type_id::create("tx");
      start_item(tx);
      assert(tx.randomize());
      finish_item(tx);
    end
  endtask
  
endclass

endpackage: sequences
