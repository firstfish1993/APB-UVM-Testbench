`include "uvm_macros.svh"
//-----------------------------
// This file contains apb config, apb_agent and apb_env class components
//-----------------------------
package CAE;

import uvm_pkg::*;
import coverage::*;
import scoreboard::*;
import sequences::*;
import rw_trans::*;
import DSM::*;

//---------------------------------------
// APB Agent class
//---------------------------------------
class apb_agent extends uvm_agent;

   //Agent will have the sequencer, driver and monitor components for the APB interface
   apb_sequencer sqr;
   apb_master_drv drv;
   apb_monitor mon;

   virtual apb_if  vif;

   uvm_analysis_port #(apb_rw) aport;
  
   `uvm_component_utils(apb_agent)
      
   function new(string name, uvm_component parent = null);
      super.new(name, parent);
   endfunction

   //Build phase of agent - construct sequencer, driver and monitor
   //get handle to virtual interface from env (parent) config_db
   //and pass handle down to srq/driver/monitor
   virtual function void build_phase(uvm_phase phase);
     aport = new("aport", this);
     sqr = apb_sequencer::type_id::create("sqr", this);
     drv = apb_master_drv::type_id::create("drv", this);
     mon = apb_monitor::type_id::create("mon", this);
     if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
         `uvm_fatal("APB/AGT/NOVIF", "No virtual interface specified for this agent instance")
      end
     uvm_config_db#(virtual apb_if)::set( this, "sqr", "vif", vif);
     uvm_config_db#(virtual apb_if)::set( this, "drv", "vif", vif);
     uvm_config_db#(virtual apb_if)::set( this, "mon", "vif", vif);
   endfunction: build_phase

   //Connect - driver and sequencer port to export
   virtual function void connect_phase(uvm_phase phase);
     uvm_report_info("apb_agent::", "connect_phase, Connected driver to sequencer");
     drv.seq_item_port.connect(sqr.seq_item_export);
     mon.aport.connect(aport);
   endfunction
endclass: apb_agent

//----------------------------------------------
// APB Env class
//----------------------------------------------
class apb_env  extends uvm_env;
 
   `uvm_component_utils(apb_env);

   //ENV class will have agent, subscriber (for coverage) and scoreboard as its sub component
   apb_agent  agt;
   apb_subscriber subsc;
   apb_scoreboard score;
   
   //virtual interface for APB interface
   virtual apb_if  vif;

   function new(string name, uvm_component parent = null);
      super.new(name, parent);
   endfunction

   //Build phase - Construct agent and get virtual interface handle from test  and pass it down to agent
   function void build_phase(uvm_phase phase);
     agt = apb_agent::type_id::create("agt", this);
     subsc = apb_subscriber::type_id::create("subsc", this);
     score = apb_scoreboard::type_id::create("score", this);
     if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
         `uvm_fatal("APB/AGT/NOVIF", "No virtual interface specified for this env instance")
     end
     uvm_config_db#(virtual apb_if)::set( this, "agt", "vif", vif);
   endfunction
  
  function void connect_phase(uvm_phase phase);
    agt.aport.connect(subsc.analysis_export);
    agt.aport.connect(score.sb);
  endfunction
  
  function void start_of_simulation_phase(uvm_phase phase);
    uvm_top.set_report_verbosity_level_hier(UVM_HIGH);
  endfunction
endclass : apb_env  
  
endpackage: CAE
