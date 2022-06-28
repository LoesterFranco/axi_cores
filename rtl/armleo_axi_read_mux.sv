

`include "armleo_axi_defs.svh"
`include "armleo_access_packed.svh"

`default_nettype none
module armleo_axi_read_mux (
    clk, rst_n,
    
    `AXI_FULL_READ_MODULE_IO_NAMELIST(upstream_axi_),
    `AXI_FULL_READ_MODULE_IO_NAMELIST(downstream_axi_)
);
    parameter HOST_NUMBER = 5;
    localparam HOST_NUMBER_CLOG2 = $clog2(HOST_NUMBER);
    parameter ADDR_WIDTH = 32;  
    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH = 4;

    // Future feature: Passthrought / registered downstream interface
    // parameter PASSTHROUGH = 0;

    localparam DATA_STROBES = DATA_WIDTH/8;

    input wire          clk;
    input wire          rst_n;

    `AXI_FULL_READ_IO_HOST     (downstream_axi_, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)
    

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
logic arbiter_decision_request; // comb

logic [HOST_NUMBER-1:0] grant; // comb
logic [HOST_NUMBER_CLOG2-1:0] grant_idx;

logic rr_ack; // comb

logic [HOST_NUMBER-1:0] lock; // ff, Contains locked grant signal
logic [HOST_NUMBER-1:0] lock_nxt; // comb, lock ff's D pins

logic ar_done; // ff, shows that single AR was complete, when raised next AR should not be accepted
logic ar_done_nxt; // comb, ar_done ff's D pin

logic [HOST_NUMBER-1:0] ar_select; // comb, used to make the MUX selection
logic [HOST_NUMBER_CLOG2-1:0] ar_select_idx; // MUX's select pin
logic ar_enable; // Should ARVALID/ARREADY be passed through


logic [HOST_NUMBER-1:0] r_select; // comb, used to make the MUX selection
logic [HOST_NUMBER_CLOG2-1:0] r_select_idx; // MUX's select pin
logic r_enable; // Should RVALID/RREADY be passed through

armleo_round_robin #(.WIDTH(HOST_NUMBER)) ar_arbiter (
    .clk(clk),
    .rst_n(rst_n),
    .request({upstream_axi_arvalid} & {HOST_NUMBER{arbiter_decision_request}}),
    .grant(grant),
    .grant_idx(grant_idx),
    .ack(rr_ack)
);



always_ff @(posedge clk) begin
    if(!rst_n) begin
        lock <= 0;
        ar_done <= 0;
    end else begin
        lock <= lock_nxt;
        ar_done <= ar_done_nxt;
    end
end

always @(*) begin
    `ifndef SYNTHESIS
    #1
    `endif

    ar_done_nxt = ar_done;
    lock_nxt = lock;
    arbiter_decision_request = 0;
    rr_ack = 0;

    r_select = 0;

    ar_select = 0;
    

    if(!(|lock)) begin // No decision has been made yet
        arbiter_decision_request = 1; // Ask arbiter for decision
        lock_nxt = grant; // Save decision
        ar_select = grant; // Passthrough the transaction early
        // As we are only passing through the ar, there is no need to check the R
        if(|upstream_axi_arvalid) begin
            rr_ack = 1;
        end
        if((|lock_nxt) && upstream_axi_arvalid[ar_select_idx] && upstream_axi_arready[ar_select_idx]) begin
            ar_done_nxt = 1; // set ar done
        end else begin
            ar_done_nxt = 0; // Reset ar done
        end
    end else begin // We have a decision
        ar_select = lock & {HOST_NUMBER{!ar_done}};  // Passthrough the transaction, but only if we didnt pass it yet
        
        r_select = lock;
        if(upstream_axi_arvalid[ar_select_idx] && upstream_axi_arready[ar_select_idx]) begin
            ar_done_nxt = 1;
        end
        if(
            (ar_done && downstream_axi_rvalid && downstream_axi_rready && downstream_axi_rlast)
        ) begin // If one transaction is completed
            lock_nxt = 0;
            ar_done_nxt = 0;
        end
    end
end

`ifdef ARMLEO_AXI_READ_MUX_DEBUG
always @(posedge clk) begin
    if(!rst_n) begin

    end else begin
        if(!(|lock)) begin
            if(lock_nxt) begin
                $display("[%d] [ARMLEO_AXI_READ_MUX_DEBUG] Found request, selected=%d; ar_done_nxt = %d", $time, ar_select_idx, ar_done_nxt);
            end
        end else begin
            if(upstream_axi_arvalid[ar_select_idx] && upstream_axi_arready[ar_select_idx]) begin
                $display("[%d] [ARMLEO_AXI_READ_MUX_DEBUG] ar_done_nxt = %d", $time, ar_done_nxt);
            end

            if(
                (ar_done && downstream_axi_rvalid && downstream_axi_rready && downstream_axi_rlast)
            ) begin
                $display("[%d] [ARMLEO_AXI_READ_MUX_DEBUG] One transaction done r_select = %d", $time, r_select);
            end
        end
    end
end
`endif

////////////////////////////////////////////////////////////////////////////////
// 
// AR MUX
// 
////////////////////////////////////////////////////////////////////////////////


always @(*) begin
    `ifndef SYNTHESIS
    #1
    `endif

    ar_select_idx = 0;
    for (int i = 0; i < HOST_NUMBER; i++) begin
        if (ar_select[i]) begin
            ar_select_idx = i[HOST_NUMBER_CLOG2-1:0];
        end
    end

    upstream_axi_arready = 0;
    ar_enable = (|ar_select);
    upstream_axi_arready[`ACCESS_PACKED(ar_select_idx, 1)]    = downstream_axi_arready & ar_enable;
    downstream_axi_arvalid  = upstream_axi_arvalid  [`ACCESS_PACKED(ar_select_idx, 1)] & ar_enable;

    downstream_axi_araddr   = upstream_axi_araddr   [`ACCESS_PACKED(ar_select_idx, ADDR_WIDTH)];
    downstream_axi_arlen    = upstream_axi_arlen    [`ACCESS_PACKED(ar_select_idx, 8)];
    downstream_axi_arsize   = upstream_axi_arsize   [`ACCESS_PACKED(ar_select_idx, 3)];
    downstream_axi_arburst  = upstream_axi_arburst  [`ACCESS_PACKED(ar_select_idx, 2)];
    downstream_axi_arid     = upstream_axi_arid     [`ACCESS_PACKED(ar_select_idx, ID_WIDTH)];
    downstream_axi_arlock   = upstream_axi_arlock   [`ACCESS_PACKED(ar_select_idx, 1)];
    downstream_axi_arprot   = upstream_axi_arprot   [`ACCESS_PACKED(ar_select_idx, 3)];
end


////////////////////////////////////////////////////////////////////////////////
// 
// R MUX
// 
////////////////////////////////////////////////////////////////////////////////

always @(*) begin
    `ifndef SYNTHESIS
    #1
    `endif

    r_select_idx = 0;
    for (int i = 0; i < HOST_NUMBER; i++) begin
        if (r_select[i]) begin
            r_select_idx = i[HOST_NUMBER_CLOG2-1:0];
        end
    end
    r_enable = |r_select;
    upstream_axi_rvalid = 0;

    downstream_axi_rready   = upstream_axi_rready[`ACCESS_PACKED(r_select_idx, 1)] & r_enable;
    upstream_axi_rvalid     [`ACCESS_PACKED(r_select_idx, 1)]          = downstream_axi_rvalid & r_enable;

    upstream_axi_rresp = {HOST_NUMBER{downstream_axi_rresp}};
    upstream_axi_rlast = {HOST_NUMBER{downstream_axi_rlast}};
    upstream_axi_rdata = {HOST_NUMBER{downstream_axi_rdata}};
    upstream_axi_rid   = {HOST_NUMBER{downstream_axi_rid}};
end


endmodule

`default_nettype wire
