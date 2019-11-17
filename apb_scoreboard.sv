`include "uvm_macros.svh"
package scoreboard; 
import uvm_pkg::*;
import rw_trans::*;

class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)
    //input to the scoreboard, which is the real tx
    uvm_analysis_export #(apb_rw) sb;

    //Then put connect the sb_in and sb_out to the fifos for both input and output
    uvm_tlm_analysis_fifo #(apb_rw) fifo;

    apb_rw tx;
    
    function new(string name, uvm_component parent);
        super.new(name,parent);
        tx=new("tx");
    endfunction: new

    function void build_phase(uvm_phase phase);
        sb = new("sb",this);
        fifo = new("fifo",this);
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        sb.connect(fifo.analysis_export);
    endfunction: connect_phase

    task run();
        forever begin
            fifo.get(tx);
            compare();
        end
    endtask: run

    extern virtual function void compare; 
    extern virtual function string scoreboardPrint;        

endclass: apb_scoreboard

function string apb_scoreboard::scoreboardPrint;
  scoreboardPrint = {$sformatf("command = %b, addr = %h, data = %h, select = %b, enable = %b, ready = %b", tx.apb_cmd, tx.addr, tx.data, tx.sel, tx.enable, tx.ready)};
endfunction: scoreboardPrint

function void apb_scoreboard::compare;
    if(tx.ready == 1'b1)begin
      if(tx.sel == 1'b1 && tx.enable == 1'b1)begin
        `uvm_info("cr","CORRECT1", UVM_MEDIUM);  
        `uvm_info("cr_print",tx.convert2string(), UVM_FULL);
        `uvm_info("getResult",scoreboardPrint(), UVM_HIGH);
      end
      else begin
        `uvm_info("wr","WRONG1",UVM_MEDIUM); 
        //`uvm_info("wr_print",tx.convert2string(), UVM_MEDIUM);
        `uvm_info("getResult",scoreboardPrint(), UVM_HIGH);
      end
    end
    if(tx.enable == 1'b0)begin
      if(tx.ready == 1'b0)begin
        `uvm_info("cr","CORRECT2", UVM_MEDIUM);  
        `uvm_info("cr_print",tx.convert2string(), UVM_FULL);
        `uvm_info("getResult",scoreboardPrint(), UVM_HIGH);
      end
      else begin
        `uvm_info("wr","WRONG2",UVM_MEDIUM); 
        //`uvm_info("wr_print",tx.convert2string(), UVM_MEDIUM);
        `uvm_info("getResult",scoreboardPrint(), UVM_HIGH);
      end
    end
    if(tx.sel == 1'b0)begin
      if(tx.ready == 1'b0 && tx.enable == 1'b0)begin
        `uvm_info("cr","CORRECT3", UVM_MEDIUM);  
        `uvm_info("cr_print",tx.convert2string(), UVM_FULL);
        `uvm_info("getResult",scoreboardPrint(), UVM_HIGH);
      end
      else begin
        `uvm_info("wr","WRONG3",UVM_MEDIUM); 
        //`uvm_info("wr_print",tx.convert2string(), UVM_MEDIUM);
        `uvm_info("getResult",scoreboardPrint(), UVM_HIGH);
      end
    end
    if(tx.enable == 1'b1)begin
      if(tx.sel == 1'b1)begin
        `uvm_info("cr","CORRECT7", UVM_MEDIUM);  
        `uvm_info("cr_print",tx.convert2string(), UVM_FULL);
        `uvm_info("getResult",scoreboardPrint(), UVM_HIGH);
      end
      else begin
        `uvm_info("wr","WRONG7",UVM_MEDIUM); 
        //`uvm_info("wr_print",tx.convert2string(), UVM_MEDIUM);
        `uvm_info("getResult",scoreboardPrint(), UVM_HIGH);
      end
    end

endfunction

endpackage: scoreboard
