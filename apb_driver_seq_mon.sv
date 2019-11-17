//----------------------------------------------------
// This file contains the APB Driver, Sequencer and Monitor component classes defined
//----------------------------------------------------
`include "uvm_macros.svh"
package DSM;

import uvm_pkg::*;
import coverage::*;
import scoreboard::*;
import sequences::*;
import rw_trans::*;

typedef class apb_config;

//---------------------------------------
// APB Config class
//   -Not really done anything as of now
//---------------------------------------
class apb_config extends uvm_object;

   `uvm_object_utils(apb_config)
   virtual apb_if vif;

  function new(string name="apb_config");
     super.new(name);
  endfunction : new

endclass: apb_config


//---------------------------------------------
// APB master driver Class  
//---------------------------------------------
class apb_master_drv extends uvm_driver#(apb_rw);
  
  `uvm_component_utils(apb_master_drv)
   
   virtual apb_if.master vif;
   apb_config cfg;

   function new(string name,uvm_component parent = null);
      super.new(name,parent);
   endfunction

   //Build Phase
   //Get the virtual interface handle form the agent (parent ) or from config_db
   function void build_phase(uvm_phase phase);
     if(!uvm_config_db #(virtual apb_if)::get(this, "", "vif", vif))begin
       `uvm_fatal("MY_DRIVER", "NO APB_CONFIG")
     end
   endfunction

   //Run Phase
   //Implement the Driver -Sequencer API to get an item
   //Based on if it is Read/Write - drive on APB interface the corresponding pins
   virtual task run_phase(uvm_phase phase);
     forever begin
       apb_rw tx;
       @ (this.vif.master_cb);
       seq_item_port.get_next_item(tx); 
       this.vif.prst = 1; //reset the slave
       @ (this.vif.master_cb); this.vif.prst = 0; //reset finishes
       @ (this.vif.master_cb);
       if(tx.apb_cmd == 1)begin
         drive_write(tx.addr, tx.data);
       end
       else begin
         drive_read(tx.addr, tx.data);
       end
       seq_item_port.item_done();
     end
   endtask: run_phase

   virtual protected task drive_read(input bit [31:0] addr, output logic [31:0] data);
     /*READ WITH NO WAIT*/
     //IDLE STATE
     @ (this.vif.master_cb); 
     this.vif.master_cb.paddr <= addr;
     this.vif.master_cb.pwrite <= 1'b0;
     this.vif.master_cb.psel <= 1'b1;
     //SETUP STATE
     //@ (this.vif.master_cb);
     @ (this.vif.master_cb); 
     this.vif.master_cb.penable <= 1'b1;
     //ACCESS STATE
     @ (posedge this.vif.master_cb.pready);
     data = this.vif.master_cb.prdata;
     this.vif.master_cb.psel    <= 1'b0;
     this.vif.master_cb.penable <= 1'b0;
     //BEGIN WRITE AFTER READ
     @ (this.vif.master_cb); 
     this.vif.master_cb.pwdata  <= data;
     this.vif.master_cb.pwrite  <= 1'b1;
     this.vif.master_cb.psel    <= 1'b1;
     //SETUP STATE
     @ (this.vif.master_cb);
     this.vif.master_cb.penable <= 1'b1;
     //ACCESS STATE
     @ (posedge this.vif.master_cb.pready);
     @ (this.vif.master_cb);
     this.vif.master_cb.psel    <= 1'b0;
     this.vif.master_cb.penable <= 1'b0;
     //BEGIN READ AFTER WRITE AFTER READ
     @ (this.vif.master_cb);
     this.vif.master_cb.pwrite  <= 1'b0;
     this.vif.master_cb.psel    <= 1'b1;
     //SETUP STATE
     @ (this.vif.master_cb);
     this.vif.master_cb.penable <= 1'b1;
     //ACCESS STATE
     @ (posedge this.vif.master_cb.pready);
     @ (this.vif.master_cb);
     this.vif.master_cb.psel    <= 1'b0;
     this.vif.master_cb.penable <= 1'b0;
     data = this.vif.master_cb.prdata;
   endtask: drive_read

   virtual protected task drive_write(input bit [31:0] addr, input bit [31:0] data);
      /*WRITE WITH NO WAIT*/
      //IDLE STATE
      @ (this.vif.master_cb); 
      this.vif.master_cb.paddr   <= addr;
      this.vif.master_cb.pwdata  <= data;
      this.vif.master_cb.pwrite  <= 1'b1;
      this.vif.master_cb.psel    <= 1'b1;
      //SETUP STATE
      @ (this.vif.master_cb);
      this.vif.master_cb.penable <= 1'b1;
      //ACCESS STATE
      @ (posedge this.vif.master_cb.pready);
      @ (this.vif.master_cb);
      this.vif.master_cb.psel    <= 1'b0;
      this.vif.master_cb.penable <= 1'b0;
      //BEGIN READ AFTER WRITE
      @ (this.vif.master_cb);
      this.vif.master_cb.pwrite  <= 1'b0;
      this.vif.master_cb.psel    <= 1'b1;
      //SETUP STATE
      @ (this.vif.master_cb);
      this.vif.master_cb.penable <= 1'b1;
      //ACCESS STATE
      @ (posedge this.vif.master_cb.pready);
      @ (this.vif.master_cb);
      this.vif.master_cb.psel    <= 1'b0;
      this.vif.master_cb.penable <= 1'b0;
      data = this.vif.master_cb.prdata;
   endtask: drive_write

endclass: apb_master_drv

//---------------------------------------------
// APB Sequencer Class  
//  Derive form uvm_sequencer and parameterize to apb_rw sequence item
//---------------------------------------------
class apb_sequencer extends uvm_sequencer #(apb_rw);

   `uvm_component_utils(apb_sequencer)
 
   function new(input string name, uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

endclass : apb_sequencer

//-----------------------------------------
// APB Monitor class  
//-----------------------------------------
class apb_monitor extends uvm_monitor;

  virtual apb_if.passive vif;

  //Analysis port -parameterized to apb_rw transaction
  //Monitor writes transaction objects to this port once detected on interface
  uvm_analysis_port#(apb_rw) aport;

  //config class handle
  apb_config cfg;

  `uvm_component_utils(apb_monitor)

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    //Create Analysis port here
    aport = new("aport", this);
  endfunction: new

  //Build Phase - Get handle to virtual if from agent/config_db
  virtual function void build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual apb_if)::get(this, "", "vif", vif))begin
       `uvm_fatal("MY_DRIVER", "NO APB_CONFIG")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      apb_rw tx = apb_rw::type_id::create("tx");
      @ (this.vif.monitor_cb);
      tx.sel = this.vif.monitor_cb.psel;
      tx.enable = this.vif.monitor_cb.penable;
      tx.ready = this.vif.monitor_cb.pready;
      aport.write(tx); 
      @ (posedge this.vif.monitor_cb.psel); //Now entering the SETUP State
      tx.sel = this.vif.monitor_cb.psel;
      tx.enable = this.vif.monitor_cb.penable;
      tx.ready = this.vif.monitor_cb.pready;
      tx.addr = this.vif.monitor_cb.paddr;
      tx.apb_cmd = (this.vif.monitor_cb.pwrite) ? 1 : 0;
      aport.write(tx);
      @ (posedge this.vif.monitor_cb.pready); //Now entering the ACCESS State
      tx.sel = this.vif.monitor_cb.psel;
      tx.enable = this.vif.monitor_cb.penable;
      tx.ready = this.vif.monitor_cb.pready;
      tx.data = (tx.apb_cmd == 0) ? this.vif.monitor_cb.prdata : 32'b0;
      tx.data = (tx.apb_cmd == 1) ? this.vif.monitor_cb.pwdata : 32'b0;
      aport.write(tx);
      if(tx.apb_cmd == 1)
        begin
          @ (posedge this.vif.monitor_cb.pready); 
	  if(tx.data == this.vif.monitor_cb.prdata)begin
            `uvm_info("cr","CORRECT4", UVM_MEDIUM);  
            `uvm_info("cr_print", tx.convert2string(), UVM_FULL); 
      	    tx.addr = this.vif.monitor_cb.paddr;
	    tx.data = (tx.apb_cmd == 0) ? this.vif.monitor_cb.prdata : 32'b0;
            tx.data = (tx.apb_cmd == 1) ? this.vif.monitor_cb.pwdata : 32'b0;
            tx.apb_cmd = (this.vif.monitor_cb.pwrite) ? 1 : 0;
            aport.write(tx);
          end 
          else begin
            `uvm_info("wr","WRONG4", UVM_MEDIUM); 
            `uvm_info("wr_print", tx.convert2string(), UVM_MEDIUM); 
          end	
        end      
      else
        begin
          if(tx.data == 32'd0)begin  
            `uvm_info("cr","CORRECT5", UVM_MEDIUM); 
	    tx.addr = this.vif.monitor_cb.paddr;
	    tx.data = (tx.apb_cmd == 0) ? this.vif.monitor_cb.prdata : 32'b0;
            tx.data = (tx.apb_cmd == 1) ? this.vif.monitor_cb.pwdata : 32'b0;
            tx.apb_cmd = (this.vif.monitor_cb.pwrite) ? 1 : 0;
            aport.write(tx); 
          end
          else begin
            `uvm_info("wr","WRONG5", UVM_MEDIUM); 
            `uvm_info("wr_print", tx.convert2string(), UVM_MEDIUM); 
          end
          @ (posedge this.vif.monitor_cb.pready); 
          tx.data = this.vif.monitor_cb.pwdata;
          @ (posedge this.vif.monitor_cb.pready); 
	  if(tx.data == this.vif.monitor_cb.prdata)begin
            `uvm_info("cr","CORRECT6", UVM_MEDIUM);  
            `uvm_info("cr_print", tx.convert2string(), UVM_FULL);
	    tx.addr = this.vif.monitor_cb.paddr;
	    tx.data = (tx.apb_cmd == 0) ? this.vif.monitor_cb.prdata : 32'b0;
            tx.data = (tx.apb_cmd == 1) ? this.vif.monitor_cb.pwdata : 32'b0;
            tx.apb_cmd = (this.vif.monitor_cb.pwrite) ? 1 : 0;
            aport.write(tx);
          end 
          else begin
            `uvm_info("wr","WRONG6", UVM_MEDIUM); 
            `uvm_info("wr_print", tx.convert2string(), UVM_MEDIUM); 
          end	
        end      
     end

  endtask : run_phase

endclass: apb_monitor

endpackage: DSM

