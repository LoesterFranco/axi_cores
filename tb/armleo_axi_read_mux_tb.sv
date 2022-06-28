////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (C) 2016-2021, Arman Avetisyan
// 
////////////////////////////////////////////////////////////////////////////////

`define TIMEOUT 1000000
`define SYNC_RST
`define CLK_HALF_PERIOD 10
`define TOP armleo_axi_read_mux
`define TOP_TB armleo_axi_read_mux_tb


`define MAXIMUM_ERRORS 20
`include "armleo_template.svh"
`include "armleo_axi_defs.svh"
`include "armleo_access_packed.svh"


localparam ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;
localparam DATA_STROBES = DATA_WIDTH/8;
localparam ID_WIDTH = 4;
localparam HOST_NUMBER = 5;
localparam HOST_NUMBER_CLOG2 = $clog2(HOST_NUMBER);

`AXI_FULL_READ_SIGNALS(downstream_axi_, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)
/*

    logic   [HOST_NUMBER-1:0]              	upstream_axi_awvalid;
    logic   [HOST_NUMBER-1:0]               upstream_axi_awready;
    logic   [HOST_NUMBER*ADDR_WIDTH-1:0]   	upstream_axi_awaddr;
    logic   [HOST_NUMBER*8-1:0]            	upstream_axi_awlen;
    logic   [HOST_NUMBER*3-1:0]            	upstream_axi_awsize;
    logic   [HOST_NUMBER*2-1:0]            	upstream_axi_awburst;
    logic   [HOST_NUMBER-1:0]              	upstream_axi_awlock;
    logic   [HOST_NUMBER*ID_WIDTH-1:0]     	upstream_axi_awid;
    logic   [HOST_NUMBER*3-1:0]            	upstream_axi_awprot;
    
    logic   [HOST_NUMBER-1:0]              	upstream_axi_wvalid;
    logic   [HOST_NUMBER-1:0]              	upstream_axi_wready;
    logic   [HOST_NUMBER*DATA_WIDTH-1:0]   	upstream_axi_wdata;
    logic   [HOST_NUMBER*DATA_STROBES-1:0] 	upstream_axi_wstrb;
    logic   [HOST_NUMBER-1:0]              	upstream_axi_wlast;
    
    logic   [HOST_NUMBER-1:0]              	upstream_axi_bvalid;
    logic   [HOST_NUMBER-1:0]              	upstream_axi_bready;
    logic   [HOST_NUMBER*2-1:0]            	upstream_axi_bresp;
    logic   [HOST_NUMBER*ID_WIDTH-1:0]     	upstream_axi_bid;
    */
    logic   [HOST_NUMBER-1:0]              	upstream_axi_arvalid;
    logic   [HOST_NUMBER-1:0]              	upstream_axi_arready;
    logic   [HOST_NUMBER*ADDR_WIDTH-1:0]   	upstream_axi_araddr;
    logic   [HOST_NUMBER*8-1:0]            	upstream_axi_arlen;
    logic   [HOST_NUMBER*3-1:0]            	upstream_axi_arsize;
    logic   [HOST_NUMBER*2-1:0]            	upstream_axi_arburst;
    logic   [HOST_NUMBER*ID_WIDTH-1:0]     	upstream_axi_arid;
    logic   [HOST_NUMBER-1:0]              	upstream_axi_arlock;
    logic   [HOST_NUMBER*3-1:0]            	upstream_axi_arprot;
    
    logic   [HOST_NUMBER-1:0]              	upstream_axi_rvalid;
    logic   [HOST_NUMBER-1:0]              	upstream_axi_rready;
    logic   [HOST_NUMBER*2-1:0]            	upstream_axi_rresp;
    logic   [HOST_NUMBER-1:0]              	upstream_axi_rlast;
    logic   [HOST_NUMBER*DATA_WIDTH-1:0]   	upstream_axi_rdata;
    logic   [HOST_NUMBER*ID_WIDTH-1:0]     	upstream_axi_rid;

`TOP #(
    .HOST_NUMBER(HOST_NUMBER),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH)
) mux (
    .*
);


task downstream_ar_op;
input arready;
begin
    downstream_axi_arready = arready;
end endtask

task downstream_ar_expect;
input [HOST_NUMBER_CLOG2-1:0] host_num;
input valid;
begin
    `assert_equal((downstream_axi_arvalid)                                        , (valid));
    if(valid) begin
    `assert_equal((upstream_axi_araddr  [`ACCESS_PACKED(host_num, ADDR_WIDTH)])   , (downstream_axi_araddr));
    `assert_equal((upstream_axi_arlen   [`ACCESS_PACKED(host_num, 8)])            , (downstream_axi_arlen));
    `assert_equal((upstream_axi_arsize  [`ACCESS_PACKED(host_num, 3)])            , (downstream_axi_arsize));
    `assert_equal((upstream_axi_arburst [`ACCESS_PACKED(host_num, 2)])            , (downstream_axi_arburst));
    `assert_equal((upstream_axi_arid    [`ACCESS_PACKED(host_num, ID_WIDTH)])     , (downstream_axi_arid));
    `assert_equal((upstream_axi_arlock  [`ACCESS_PACKED(host_num, 1)])            , (downstream_axi_arlock));
    `assert_equal((upstream_axi_arprot  [`ACCESS_PACKED(host_num, 3)])            , (downstream_axi_arprot));
    end
end endtask

task upstream_ar_op;
input [HOST_NUMBER_CLOG2-1:0] host_num;
input valid;
begin
	upstream_axi_arvalid[host_num] = valid;

	upstream_axi_araddr  [`ACCESS_PACKED(host_num, ADDR_WIDTH)]  = $urandom & ({ADDR_WIDTH{1'b1}});
	upstream_axi_arlen   [`ACCESS_PACKED(host_num, 8)]           = $urandom & ({8{1'b1}});
	upstream_axi_arsize  [`ACCESS_PACKED(host_num, 3)]           = $urandom & ({3{1'b1}});
	upstream_axi_arburst [`ACCESS_PACKED(host_num, 2)]           = $urandom & ({2{1'b1}});
	upstream_axi_arid    [`ACCESS_PACKED(host_num, ID_WIDTH)]    = $urandom & ({ID_WIDTH{1'b1}});
    upstream_axi_arlock  [`ACCESS_PACKED(host_num, 1)]           = $urandom & ({1{1'b1}});
    upstream_axi_arprot  [`ACCESS_PACKED(host_num, 3)]           = $urandom & ({3{1'b1}});
end endtask


task upstream_ar_expect;
input [HOST_NUMBER_CLOG2-1:0] host_num;
input [0:0] ready;
begin
    `assert_equal((upstream_axi_arready  [`ACCESS_PACKED(host_num, 1)]), ready);
end endtask

    // --------------------------
    // R channel
    // --------------------------

task downstream_r_op;
input valid;
input last;
begin
	downstream_axi_rvalid = valid;
    downstream_axi_rlast = last;

	downstream_axi_rdata = $urandom & ({DATA_WIDTH{1'b1}});
    downstream_axi_rresp = $urandom & ({2{1'b1}});
    downstream_axi_rid = $urandom & ({ID_WIDTH{1'b1}});
    
end endtask

task upstream_r_op;
input [HOST_NUMBER_CLOG2-1:0] host_num;
input ready;
begin
	upstream_axi_rready[host_num] = ready;
end endtask


task upstream_r_expect;
input [HOST_NUMBER_CLOG2-1:0] host_num;
input valid;
begin
    `assert_equal((upstream_axi_rvalid [`ACCESS_PACKED(host_num, 1)])            , (valid));
    if(valid) begin
    `assert_equal((upstream_axi_rdata  [`ACCESS_PACKED(host_num, DATA_WIDTH)])   , (downstream_axi_rdata));
    `assert_equal((upstream_axi_rresp  [`ACCESS_PACKED(host_num, 2)])            , (downstream_axi_rresp));
    `assert_equal((upstream_axi_rid    [`ACCESS_PACKED(host_num, ID_WIDTH)])     , (downstream_axi_rid));
    `assert_equal((upstream_axi_rlast  [`ACCESS_PACKED(host_num, 1)])            , (downstream_axi_rlast));
    end
end endtask

task downstream_r_expect;
input ready;
begin
    `assert_equal(downstream_axi_rready, ready);
end endtask

logic [HOST_NUMBER_CLOG2-1:0] last_host_num;

logic [HOST_NUMBER_CLOG2-1:0] host_num;

logic found_priority_host;

integer i;
integer cycle_counter;
integer r_transaction_counter;



task find_priority_request;
input [HOST_NUMBER-1:0] requests;
begin
    found_priority_host = 0;

    for(i = last_host_num + 1; i < HOST_NUMBER; i = i + 1) begin
        if (!found_priority_host && requests[i]) begin
            found_priority_host = 1;
            host_num = i;
            
        end
    end

    for(i = 0; i < last_host_num + 1; i = i + 1) begin
        if (!found_priority_host && requests[i]) begin
            found_priority_host = 1;
            host_num = i;
        end
    end

    last_host_num = host_num;
end endtask

task test_case;
input [HOST_NUMBER-1:0] requests;
input [31:0] ar_wait;
input [31:0] r_wait;
input [31:0] r_transactions;
begin
    find_priority_request(requests);

    $display("requests = %b; host_num = %d; ar_wait = %d; r_wait = %d; r_transactions = %d", requests, host_num, ar_wait, r_wait, r_transactions);

    for(cycle_counter = 0; cycle_counter < ar_wait; cycle_counter = cycle_counter + 1) begin
        // ------------------------------------------------------------------------------
        $display("AR wait");
        // ------------------------------------------------------------------------------
        
        for(i = 0; i < HOST_NUMBER; i = i + 1) begin
            upstream_ar_op(i, /*arvalid=*/requests[i]);
        end
        downstream_ar_op(/*arready=*/0); // If cycle, overwise zero

        #5
        for(i = 0; i < HOST_NUMBER; i = i + 1) begin
            upstream_ar_expect(/*host_num=*/i, /*ready=*/0);
            upstream_r_expect (/*host_num=*/i, /*valid=*/0);
        end
        downstream_ar_expect(/*host_num=*/host_num, /*valid=*/1);
        downstream_r_expect(0);
        @(negedge clk);
    end



    // ------------------------------------------------------------------------------
    $display("AR cycle");
    // ------------------------------------------------------------------------------
    for(i = 0; i < HOST_NUMBER; i = i + 1) begin
        upstream_ar_op(i, /*arvalid=*/requests[i]);
    end
    downstream_ar_op(/*arready=*/1); // If cycle, overwise zero
    #5
    $display("arready=%b, expected = %b", upstream_axi_arready, 1 << host_num);
    for(i = 0; i < HOST_NUMBER; i = i + 1) begin
        upstream_ar_expect(/*host_num=*/i, /*ready=*/i == host_num ? 1 : 0);
        upstream_r_expect (/*host_num=*/i, /*valid=*/0);
    end
    downstream_ar_expect(/*host_num=*/host_num, /*valid=*/1);
    downstream_r_expect(0);
    @(negedge clk);

    for (r_transaction_counter = 0; r_transaction_counter < r_transactions; r_transaction_counter = r_transaction_counter + 1) begin
        for(cycle_counter = 0; cycle_counter < r_wait; cycle_counter = cycle_counter + 1) begin
            // ------------------------------------------------------------------------------
            $display("R wait");
            // ------------------------------------------------------------------------------
            upstream_ar_op(host_num, /*arvalid=*/0);
            downstream_ar_op(/*arready=*/0);
            downstream_r_op(/*rvalid=*/1, /*rlast=*/r_transaction_counter == r_transactions - 1);
            upstream_r_op(host_num, /*rready=*/0);

            #5
            for(i = 0; i < HOST_NUMBER; i = i + 1) begin
                upstream_ar_expect(/*host_num=*/i, /*ready=*/0);
                upstream_r_expect (/*host_num=*/i, /*valid=*/i == host_num ? 1 : 0);
            end
            downstream_ar_expect(/*host_num=*/host_num, /*valid=*/0);
            downstream_r_expect(0);
        end


        @(negedge clk);
        // ------------------------------------------------------------------------------
        $display("R cycle");
        // ------------------------------------------------------------------------------
        upstream_ar_op(host_num, /*arvalid=*/0);
        downstream_ar_op(/*arready=*/0);
        downstream_r_op(/*rvalid=*/1, /*rlast=*/r_transaction_counter == r_transactions - 1);
        upstream_r_op(host_num, /*rready=*/1);

        #5
        for(i = 0; i < HOST_NUMBER; i = i + 1) begin
            upstream_ar_expect(/*host_num=*/i, /*ready=*/0);
            upstream_r_expect (/*host_num=*/i, /*valid=*/i == host_num ? 1 : 0);
        end
        downstream_ar_expect(/*host_num=*/host_num, /*valid=*/0);
        downstream_r_expect(1);

        @(negedge clk);

        upstream_ar_op(host_num, /*arvalid=*/0);
        downstream_ar_op(/*arready=*/0);
        upstream_r_op(host_num, /*rready=*/0);
        downstream_r_op(/*rvalid=*/0, /*rlast=*/r_transaction_counter == r_transactions - 1);
    end
end endtask

initial begin
    last_host_num = 0;
    @(posedge rst_n);
    // --------------------------
    // No operation at all:
    // --------------------------

    // poke ar channel
    for(i = 0; i < HOST_NUMBER; i = i + 1) begin
        upstream_ar_op(i, /*arvalid=*/0);
        
    end
    downstream_ar_op(/*arready=*/0);
    // poke R channel
    downstream_r_op(/*valid=*/0, /*last=*/0);
    for(i = 0; i < HOST_NUMBER; i = i + 1) begin
        upstream_r_op(i, /*ready=*/0);
    end
    
    #5
    for(i = 0; i < HOST_NUMBER; i = i + 1) begin
        upstream_ar_expect(/*host_num=*/i, /*ready=*/0);
        upstream_r_expect (/*host_num=*/i, /*valid=*/0);
    end
    downstream_ar_expect(/*host_num=*/0, /*valid=*/0);
    downstream_r_expect(0);


     // ------------------------------------------------------------------------------
     $display("Testing find_priority_request");
     // ------------------------------------------------------------------------------

    find_priority_request(1 << 1);
    $display("host_num = %d; found_priority_host = %d", host_num, found_priority_host);
    `assert_equal(host_num, 1)
    `assert_equal(found_priority_host, 1)

    find_priority_request(1 << 1);
    $display("host_num = %d; found_priority_host = %d", host_num, found_priority_host);
    `assert_equal(host_num, 1)
    `assert_equal(found_priority_host, 1)

    find_priority_request((1 << 1) | (1 << 2));
    $display("host_num = %d; found_priority_host = %d", host_num, found_priority_host);
    `assert_equal(host_num, 2)
    `assert_equal(found_priority_host, 1)

    find_priority_request((1 << 2) | (1 << 1));
    $display("host_num = %d; found_priority_host = %d", host_num, found_priority_host);
    `assert_equal(host_num, 1)
    `assert_equal(found_priority_host, 1)


    test_case(1 << 1, /*arwait=*/1, /*rwait*/1, /*r_transactions*/1);
    test_case((1 << 1) | (1 << 2), /*arwait=*/1, /*rwait*/1, /*r_transactions*/1);
    test_case((1 << 1) | (1 << 2), /*arwait=*/1, /*rwait*/1, /*r_transactions*/1);
    test_case(1 << 1, /*arwait=*/1, /*rwait*/2, /*r_transactions*/2);
    $display("First sections done");
    test_case((1 << 1) | (1 << 2), /*arwait=*/2, /*rwait*/2, /*r_transactions*/2);
    test_case((1 << 1) | (1 << 2), /*arwait=*/2, /*rwait*/2, /*r_transactions*/2);
    $display("Second sections done");
    test_case((1 << 1) | (1 << 2) | (1 << 3), /*arwait=*/0, /*rwait*/0, /*r_transactions*/1);
    test_case((1 << 1) | (1 << 2) | (1 << 3), /*arwait=*/0, /*rwait*/0, /*r_transactions*/2);
    $display("Third sections done");
    // @(negedge clk);
    // test_case(1 << ($urandom % HOST_NUMBER), )
    // // ------------------------------------------------------------------------------
    // // 
    // $display("1. Test case. AR wait, AR cycle, R wait, R cycle last=0, R wait, R cycle last = 1");
    // //
    // // ------------------------------------------------------------------------------

    


    // // ------------------------------------------------------------------------------
    // // 
    // $display("2. Test case. AR cycle, R cycle last=1");
    // //
    // // ------------------------------------------------------------------------------

    // host_num = $urandom % HOST_NUMBER;
    // upstream_ar_op(host_num, /*arvalid=*/1);
    // downstream_ar_op(/*arready=*/1);
    // downstream_r_op(/*rvalid=*/0, /*rlast=*/1);

    // #5
    // for(i = 0; i < HOST_NUMBER; i = i + 1) begin
    //     upstream_ar_expect(/*host_num=*/i, /*ready=*/i == host_num ? 1 : 0);
    //     upstream_r_expect (/*host_num=*/i, /*valid=*/0);
    // end
    // downstream_ar_expect(/*host_num=*/host_num, /*valid=*/1);
    // downstream_r_expect(0);
    // @(negedge clk);



    // upstream_ar_op(host_num, /*arvalid=*/0);
    // downstream_ar_op(/*arready=*/0);
    // downstream_r_op(/*rvalid=*/1, /*rlast=*/0);
    // upstream_r_op(host_num, /*rready=*/1);

    // #5
    // for(i = 0; i < HOST_NUMBER; i = i + 1) begin
    //     upstream_ar_expect(/*host_num=*/i, /*ready=*/0);
    //     upstream_r_expect (/*host_num=*/i, /*valid=*/i == host_num ? 1 : 0);
    // end
    // downstream_ar_expect(/*host_num=*/host_num, /*valid=*/0);
    // downstream_r_expect(1);
    // @(negedge clk);
    // // ------------------------------------------------------------------------------
    // // 
    // // $display("TODO: 3. Test case. AR cycle on two buses, R cycle last=1");
    // //
    // // ------------------------------------------------------------------------------


    // // ------------------------------------------------------------------------------
    // // 
    // // $display("TODO: 4. Test case. AR cycle on two buses, R cycle ready on many buses last=1");
    // //
    // // ------------------------------------------------------------------------------






    @(negedge clk);

    `assert_finish;
end


endmodule