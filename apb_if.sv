interface apb_if(input bit pclk);
   logic [31:0] paddr;
   logic        psel;
   logic        penable;
   logic        pwrite;
   logic [31:0] prdata;
   logic [31:0] pwdata;
   logic pready;
   logic prst;
  
  //Master Clocking block - used for Drivers
  clocking master_cb @(posedge pclk);
    input prdata, pready;
    output psel, penable, paddr, pwrite, pwdata;
  endclocking: master_cb

  //Slave Clocking Block - used for any Slave BFMs
  clocking slave_cb @(posedge pclk);
    input psel, penable, paddr, pwrite, pwdata;
    output prdata, pready;
  endclocking: slave_cb

  //Monitor Clocking block - For sampling by monitor components
  clocking monitor_cb @(posedge pclk);
    input psel, penable, paddr, pwrite, pwdata, prdata, pready;
  endclocking: monitor_cb

  modport master(clocking master_cb, output prst);
  modport slave(clocking slave_cb, input prst, input pclk);
  modport passive(clocking monitor_cb);

endinterface: apb_if
