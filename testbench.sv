//-------------------------------------------
// Top level Test module
//  Includes all env component and sequences files 
//-------------------------------------------
`include "uvm_macros.svh"
import uvm_pkg::*;
import coverage::*;
import scoreboard::*;
import sequences::*;
import rw_trans::*;
import DSM::*;
import CAE::*;
import tests::*;

module dut(apb_if _in);
  apbslave iDUT(
    .pclk(_in.pclk), 
    .prst(_in.prst), 
    .PWRITE(_in.slave_cb.pwrite), 
    .PSEL(_in.slave_cb.psel), 
    .PENABLE(_in.slave_cb.penable), 
    .PWDATA(_in.slave_cb.pwdata), 
    .PRDATA(_in.slave_cb.prdata), 
    .PREADY(_in.slave_cb.pready), 
    .PADDR(_in.slave_cb.paddr));   
endmodule
//--------------------------------------------------------
//Top level module that instantiates  just a physical apb interface
//No real DUT or APB slave as of now
//--------------------------------------------------------
module top;
  
   logic pclk;

    initial begin
     pclk = 0;
   end
 
    //Generate a clock
   always begin
      #10 pclk = ~pclk;
   end
 
  //Instantiate a physical interface for APB interface here and connect the pclk input
  apb_if apb_if(.pclk(pclk));
  dut iDUT(._in(apb_if.slave)); 
 
  initial begin
    //Pass above physical interface to test top
    //(which will further pass it down to env->agent->drv/sqr/mon
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top", "vif", apb_if);
    //Call the run_test - but passing run_test argument as test class name
    run_test("apb_base_test");
  end
  
  
endmodule


