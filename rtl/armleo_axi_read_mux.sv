

`include "armleo_axi_defs.svh"
`include "armleo_access_packed.svh"

`default_nettype none
module armleo_axi_read_mux (
    clk, rst_n,
    
    `AXI_FULL_READ_MODULE_IO_NAMELIST(upstream_axi_),
    `AXI_FULL_READ_MODULE_IO_NAMELIST(downstream_axi_)
);