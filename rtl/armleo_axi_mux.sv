////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (C) 2016-2021, Arman Avetisyan
//
// Purpose:	AXI4 Register slice
// 
// Note for contributors: Dont chase perfomance
//      If somebody decides to improve the perfomance use the same architecture as the pulp's axi mux
//      However we are not planning to do it, as it would require FIFO cell to be designed
//      And we are very area limited, therefore the FIFO usage would be inefficient
//      
//      If you want better perfomance check out pulp's AXI MUX
////////////////////////////////////////////////////////////////////////////////

`include "armleo_axi_defs.svh"
`include "armleo_access_packed.svh"
`default_nettype none
module armleo_axi_mux (
    clk, rst_n,
    
    `AXI_FULL_MODULE_IO_NAMELIST(upstream_axi_),
    `AXI_FULL_MODULE_IO_NAMELIST(downstream_axi_)
);
    parameter HOST_NUMBER = 3;
    localparam HOST_NUMBER_CLOG2 = $clog2(HOST_NUMBER);
    parameter ADDR_WIDTH = 32;  
    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH = 4;

    parameter PASSTHROUGH = 0;

    localparam DATA_STROBES = DATA_WIDTH/8;


    input wire          clk;
    input wire          rst_n;

    `AXI_FULL_IO_HOST     (downstream_axi_, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)
    
    input wire   [HOST_NUMBER-1:0]              upstream_axi_awvalid;
    output logic [HOST_NUMBER-1:0]              upstream_axi_awready;
    input wire   [HOST_NUMBER*ADDR_WIDTH-1:0]   upstream_axi_awaddr;
    input wire   [HOST_NUMBER*8-1:0]            upstream_axi_awlen;
    input wire   [HOST_NUMBER*3-1:0]            upstream_axi_awsize;
    input wire   [HOST_NUMBER*2-1:0]            upstream_axi_awburst;
    input wire   [HOST_NUMBER-1:0]              upstream_axi_awlock;
    input wire   [HOST_NUMBER*ID_WIDTH-1:0]     upstream_axi_awid;
    input wire   [HOST_NUMBER*3-1:0]            upstream_axi_awprot;
    
    input wire   [HOST_NUMBER-1:0]              upstream_axi_wvalid;
    output logic [HOST_NUMBER-1:0]              upstream_axi_wready;
    input wire   [HOST_NUMBER*DATA_WIDTH-1:0]   upstream_axi_wdata;
    input wire   [HOST_NUMBER*DATA_STROBES-1:0] upstream_axi_wstrb;
    input wire   [HOST_NUMBER-1:0]              upstream_axi_wlast;
    
    output logic [HOST_NUMBER-1:0]              upstream_axi_bvalid;
    input wire   [HOST_NUMBER-1:0]              upstream_axi_bready;
    output logic [HOST_NUMBER*2-1:0]            upstream_axi_bresp;
    output logic [HOST_NUMBER*ID_WIDTH-1:0]     upstream_axi_bid;
    
    input wire   [HOST_NUMBER-1:0]              upstream_axi_arvalid;
    output logic [HOST_NUMBER-1:0]              upstream_axi_arready;
    input wire   [HOST_NUMBER*ADDR_WIDTH-1:0]   upstream_axi_araddr;
    input wire   [HOST_NUMBER*8-1:0]            upstream_axi_arlen;
    input wire   [HOST_NUMBER*3-1:0]            upstream_axi_arsize;
    input wire   [HOST_NUMBER*2-1:0]            upstream_axi_arburst;
    input wire   [HOST_NUMBER*ID_WIDTH-1:0]     upstream_axi_arid;
    input wire   [HOST_NUMBER-1:0]              upstream_axi_arlock;
    input wire   [HOST_NUMBER*3-1:0]            upstream_axi_arprot;
    
    output logic [HOST_NUMBER-1:0]              upstream_axi_rvalid;
    input wire   [HOST_NUMBER-1:0]              upstream_axi_rready;
    output logic [HOST_NUMBER*2-1:0]            upstream_axi_rresp;
    output logic [HOST_NUMBER-1:0]              upstream_axi_rlast;
    output logic [HOST_NUMBER*DATA_WIDTH-1:0]   upstream_axi_rdata;
    output logic [HOST_NUMBER*ID_WIDTH-1:0]     upstream_axi_rid;



////////////////////////////////////////////////////////////////////////////////
// 
// 1. AR Arbiter
// 
////////////////////////////////////////////////////////////////////////////////
// When asserted then decision is requested from arbiter
logic ar_arbiter_decision_request; // comb

logic [HOST_NUMBER-1:0] ar_grant; // comb

logic [HOST_NUMBER-1:0] ar_lock; // ff, Contains locked grant signal
logic [HOST_NUMBER-1:0] ar_lock_nxt; // comb, lock ff's D pins

logic [HOST_NUMBER-1:0] ar_select; // comb, used to make the MUX selection
logic [HOST_NUMBER_CLOG2-1:0] ar_select_idx;

armleo_round_robin ar_arbiter (
    .clk(clk),
    .rst_n(rst_n),
    .request({upstream_axi_arvalid} & {HOST_NUMBER{ar_arbiter_decision_request}}),
    .grant(grant)
);


always_ff @(posedge clk) begin
    if(!rst_n) begin
        ar_lock <= 0;
    end else begin
        ar_lock <= ar_lock_nxt;
    end
end

always_comb begin
    ar_lock_nxt = ar_lock;
    ar_arbiter_decision_request = 0;
    if(!(|ar_lock)) begin // No decision has been made yet
        ar_arbiter_decision_request = 1; // Ask arbiter for decision
        ar_lock_nxt = ar_grant; // Save decision
        ar_select = ar_grant; // Passthrough the transaction early
    end else begin // We have a decision
        ar_select = ar_lock;  // Passthrough the transaction, even if it's last transaction
        if(
            (downstream_axi_rvalid && downstream_axi_rready && downstream_axi_rlast)
        ) begin // If one transaction is completed
            ar_lock_nxt = 0;
        end
    end
end

always_comb begin
    ar_select_idx = 0;
    for (int i = 0; i < HOST_NUMBER; i++) begin
        if (ar_select[i]) begin
            ar_select_idx = i[HOST_NUMBER_CLOG2-1:0];
        end
    end
end


////////////////////////////////////////////////////////////////////////////////
// 
// 2. AW Arbiter
// 
////////////////////////////////////////////////////////////////////////////////

// When asserted then decision is requested from arbiter
logic aw_arbiter_decision_request; // comb

logic [HOST_NUMBER-1:0] aw_grant; // comb

logic [HOST_NUMBER-1:0] aw_lock; // ff, Contains locked grant signal
logic [HOST_NUMBER-1:0] aw_lock_nxt; // comb, lock ff's D pins

logic [HOST_NUMBER-1:0] aw_select; // comb, used to make the MUX selection
logic [HOST_NUMBER_CLOG2-1:0] aw_select_idx;

armleo_round_robin aw_arbiter (
    .clk(clk),
    .rst_n(rst_n),
    .request({upstream_axi_awvalid} & {HOST_NUMBER{aw_arbiter_decision_request}}),
    .grant(grant)
);


always_ff @(posedge clk) begin
    if(!rst_n) begin
        aw_lock <= 0;
    end else begin
        aw_lock <= aw_lock_nxt;
    end
end

always_comb begin
    aw_lock_nxt = aw_lock;
    aw_arbiter_decision_request = 0;
    if(!(|aw_lock)) begin // No decision has been made yet
        aw_arbiter_decision_request = 1; // Ask arbiter for decision
        aw_lock_nxt = aw_grant; // Save decision
        aw_select = aw_grant; // Passthrough the transaction early
    end else begin // We have a decision
        aw_select = aw_lock;  // Passthrough the transaction, even if it's last transaction
        if(
            (downstream_axi_bvalid && downstream_axi_bready)
        ) begin // If one transaction is completed
            aw_lock_nxt = 0; // Forget that we made a decision; Arbiter will decide the next transaction
        end
    end
end


always_comb begin
    aw_select_idx = 0;
    for (int i = 0; i < HOST_NUMBER; i++) begin
        if (aw_select[i]) begin
            aw_select_idx = i[HOST_NUMBER_CLOG2-1:0];
        end
    end
end

////////////////////////////////////////////////////////////////////////////////
// 
// 3. AR MUX
// 
////////////////////////////////////////////////////////////////////////////////

always_comb begin
    upstream_axi_arready = 0;
    upstream_axi_arready[`ACCESS_PACKED(ar_select_idx, 1)]    = downstream_axi_arready;
    
    downstream_axi_arvalid  = upstream_axi_arvalid  [`ACCESS_PACKED(ar_select_idx, 1)];
    downstream_axi_araddr   = upstream_axi_araddr   [`ACCESS_PACKED(ar_select_idx, ADDR_WIDTH)];
    downstream_axi_arlen    = upstream_axi_arlen    [`ACCESS_PACKED(ar_select_idx, 8)];
    downstream_axi_arsize   = upstream_axi_arsize   [`ACCESS_PACKED(ar_select_idx, 3)];
    downstream_axi_arburst  = upstream_axi_arburst  [`ACCESS_PACKED(ar_select_idx, 2)];
    downstream_axi_arid     = upstream_axi_arid     [`ACCESS_PACKED(ar_select_idx, ID_WIDTH)];
    downstream_axi_arlock   = upstream_axi_arlock   [`ACCESS_PACKED(ar_select_idx, 1)];
    downstream_axi_arprot   = upstream_axi_arprot   [`ACCESS_PACKED(ar_select_idx, 3)];
end

always_comb begin
    //downstream_axi_rready = 0;
    upstream_axi_rvalid = 0;
    //upstream_axi_rresp = 0;
    //upstream_axi_rlast = 0;
    //upstream_axi_rdata = 0;
    //upstream_axi_rid = 0;

    downstream_axi_rready   = upstream_axi_rready[`ACCESS_PACKED(ar_select_idx, 1)];
    upstream_axi_rvalid     [`ACCESS_PACKED(ar_select_idx, 1)]          = downstream_axi_rvalid;

    upstream_axi_rresp = {HOST_NUMBER{downstream_axi_rresp}};
    upstream_axi_rlast = {HOST_NUMBER{downstream_axi_rlast}};
    upstream_axi_rdata = {HOST_NUMBER{downstream_axi_rdata}};
    upstream_axi_rid   = {HOST_NUMBER{downstream_axi_rid}};


    //  Maybe output the data regardless of select, since valid is only raised for one host
    
    //upstream_axi_rresp      [`ACCESS_PACKED(ar_select_idx, 2)]          = downstream_axi_rresp;
    //upstream_axi_rlast      [`ACCESS_PACKED(ar_select_idx, 1)]          = downstream_axi_rlast;
    //upstream_axi_rdata      [`ACCESS_PACKED(ar_select_idx, DATA_WIDTH)] = downstream_axi_rdata;
    //upstream_axi_rid        [`ACCESS_PACKED(ar_select_idx, ID_WIDTH)]   = downstream_axi_rid;
end


endmodule

`default_nettype wire
