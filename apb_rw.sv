//------------------------------------
// Basic APB  Read/Write Transaction class definition
//  This transaction will be used by Sequences, Drivers and Monitors
//------------------------------------
`include "uvm_macros.svh"
package rw_trans;
import uvm_pkg::*;

//apb_rw sequence item derived from base uvm_sequence_item
class apb_rw extends uvm_sequence_item;
   //Register with factory for dynamic creation
   `uvm_object_utils(apb_rw)
  
   //typedef for READ/Write transaction type
   rand bit   [31:0] addr;     //Address
   rand logic [31:0] data;     //Data - For write or read response
   rand logic apb_cmd;         //command type
   rand logic sel;
   rand logic enable; 
   rand logic ready;
  
  //(TODO) This part should be modified and improved
   constraint addr_or_data_range
  {
    $countones(data) <= 1 || $countones(data) == 32;
    addr >= 0;
    addr <= 15;
  }
  
   function new (string name = "apb_rw");
      super.new(name);
   endfunction

   function string convert2string();
     string s;
     s = super.convert2string();
     $sformat(s, "apb_cmd_kind: %b, addr = %b, data = %b\n", apb_cmd, addr, data);
     return s;
   endfunction

endclass: apb_rw

endpackage: rw_trans
