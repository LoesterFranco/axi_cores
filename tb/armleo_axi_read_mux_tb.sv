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


//-------------AW---------------
/*
task upstream_aw_noop;
input [HOST_NUMBER_CLOG2-1:0] host_num;
begin
    upstream_aw_op = 0;
	upstream_axi_awvalid[host_num] = 0;
end endtask

task downstream_aw_op;
input awready;
begin
    downstream_axi_awready = awready;
end endtask

task expect_downstream_aw;
input [HOST_NUMBER_CLOG2-1:0] host_num;
begin
    `assert_equal((upstream_axi_awaddr  [`ACCESS_PACKED(host_num, ADDR_WIDTH)])   , (downstream_axi_awaddr));
    `assert_equal((upstream_axi_awlen   [`ACCESS_PACKED(host_num, 8)])            , (downstream_axi_awlen));
    `assert_equal((upstream_axi_awsize  [`ACCESS_PACKED(host_num, 3)])            , (downstream_axi_awsize));
    `assert_equal((upstream_axi_awburst [`ACCESS_PACKED(host_num, 2)])            , (downstream_axi_awburst));
    `assert_equal((upstream_axi_awid    [`ACCESS_PACKED(host_num, ID_WIDTH)])     , (downstream_axi_awid));
    `assert_equal((upstream_axi_awlock  [`ACCESS_PACKED(host_num, 1)])            , (downstream_axi_awlock));
    `assert_equal((upstream_axi_awprot  [`ACCESS_PACKED(host_num, 3)])            , (downstream_axi_awprot));
end endtask

task upstream_aw_op;
input [HOST_NUMBER_CLOG2-1:0] host_num;
input [ADDR_WIDTH-1:0] addr;
input [7:0] len;
input [2:0] size;
input [1:0] burst;
input [ID_WIDTH-1:0] id;
input [0:0] lock;
input [2:0] prot;
begin
	upstream_axi_awvalid[host_num] = 1;

	upstream_axi_awaddr  [`ACCESS_PACKED(host_num, ADDR_WIDTH)]  = $urandom & ({ADDR_WIDTH{1'b1}});
	upstream_axi_awlen   [`ACCESS_PACKED(host_num, 8)]           = $urandom & ({8{1'b1}});
	upstream_axi_awsize  [`ACCESS_PACKED(host_num, 3)]           = $urandom & ({3{1'b1}});
	upstream_axi_awburst [`ACCESS_PACKED(host_num, 2)]           = $urandom & ({2{1'b1}});
	upstream_axi_awid    [`ACCESS_PACKED(host_num, ID_WIDTH)]    = $urandom & ({ID_WIDTH{1'b1}});
    upstream_axi_awlock  [`ACCESS_PACKED(host_num, 1)]           = $urandom & ({1{1'b1}});
    upstream_axi_awprot  [`ACCESS_PACKED(host_num, 3)]           = $urandom & ({3{1'b1}});
end endtask


task upstream_aw_expect;
input [HOST_NUMBER_CLOG2-1:0] host_num;
input awready;
begin
	`assert_equal(upstream_axi_awready[`ACCESS_PACKED(host_num, 1)], awready);
end endtask




//-------------W---------------
task w_noop; begin
	axi_wvalid = 0;
end endtask

task w_op;
input [DATA_WIDTH-1:0] wdata;
input [DATA_STROBES-1:0] wstrb;
begin
	axi_wvalid = 1;
	axi_wdata = wdata;
	axi_wstrb = wstrb;
	axi_wlast = 1;
end endtask

task w_expect;
input wready;
begin
	`assert_equal(axi_wready, wready)
end endtask

//-------------B---------------
task b_noop; begin
	axi_bready = 0;
end endtask

task b_expect;
input valid;
input [1:0] resp;
input [ID_WIDTH-1:0] id;
begin
	`assert_equal(axi_bvalid, valid)
	if(valid) begin
		`assert_equal(axi_bresp, resp)
		`assert_equal(axi_bid, id)
	end
end endtask
*/


task upstream_ar_op;
input [HOST_NUMBER_CLOG2-1:0] host_num;
begin
	upstream_axi_arvalid[host_num] = 1;

	upstream_axi_araddr  [`ACCESS_PACKED(host_num, ADDR_WIDTH)]  = $urandom & ({ADDR_WIDTH{1'b1}});
	upstream_axi_arlen   [`ACCESS_PACKED(host_num, 8)]           = $urandom & ({8{1'b1}});
	upstream_axi_arsize  [`ACCESS_PACKED(host_num, 3)]           = $urandom & ({3{1'b1}});
	upstream_axi_arburst [`ACCESS_PACKED(host_num, 2)]           = $urandom & ({2{1'b1}});
	upstream_axi_arid    [`ACCESS_PACKED(host_num, ID_WIDTH)]    = $urandom & ({ID_WIDTH{1'b1}});
    upstream_axi_arlock  [`ACCESS_PACKED(host_num, 1)]           = $urandom & ({1{1'b1}});
    upstream_axi_arprot  [`ACCESS_PACKED(host_num, 3)]           = $urandom & ({3{1'b1}});
end endtask


task upstream_ar_noop;
input [HOST_NUMBER_CLOG2-1:0] host_num;
begin
    upstream_ar_op(host_num);
    upstream_axi_arvalid[host_num] = 0;
end
endtask

task downstream_ar_op;
input arready;
begin
    downstream_axi_arready = arready;
end endtask

task expect_downstream_ar;
input [HOST_NUMBER_CLOG2-1:0] host_num;
begin
    `assert_equal((upstream_axi_araddr  [`ACCESS_PACKED(host_num, ADDR_WIDTH)])   , (downstream_axi_araddr));
    `assert_equal((upstream_axi_arlen   [`ACCESS_PACKED(host_num, 8)])            , (downstream_axi_arlen));
    `assert_equal((upstream_axi_arsize  [`ACCESS_PACKED(host_num, 3)])            , (downstream_axi_arsize));
    `assert_equal((upstream_axi_arburst [`ACCESS_PACKED(host_num, 2)])            , (downstream_axi_arburst));
    `assert_equal((upstream_axi_arid    [`ACCESS_PACKED(host_num, ID_WIDTH)])     , (downstream_axi_arid));
    `assert_equal((upstream_axi_arlock  [`ACCESS_PACKED(host_num, 1)])            , (downstream_axi_arlock));
    `assert_equal((upstream_axi_arprot  [`ACCESS_PACKED(host_num, 3)])            , (downstream_axi_arprot));
end endtask

task upstream_ar_expect;
input [HOST_NUMBER_CLOG2-1:0] host_num;
input [0:0] ready;
begin
    `assert_equal((upstream_axi_arready  [`ACCESS_PACKED(host_num, 1)]), ready);
end endtask

/*
//-------------R---------------
task r_noop; begin
	axi_rready = 0;
end endtask

task r_expect;
input valid;
input [1:0] resp;
input [DATA_WIDTH-1:0] data;
input [ID_WIDTH-1:0] id;
input last;
begin
	`assert_equal(axi_rvalid, valid)
	if(valid) begin
		`assert_equal(axi_rresp, resp)
		if(resp <= 2'b01)
			`assert_equal(axi_rdata, data)
		`assert_equal(axi_rid, id)
		`assert_equal(axi_rlast, last)
	end
end endtask


//-------------Others---------------
task poke_all;
input aw;
input w;
input b;

input ar;
input r; begin
	if(aw === 1)
		aw_noop();
	if(w === 1)
		w_noop();
	if(b === 1)
		b_noop();
	if(ar === 1)
		ar_noop();
	if(r === 1)
		r_noop();
end endtask

task expect_all;
input aw;
input w;
input b;

input ar;
input r; begin
	if(aw === 1)
		aw_expect(0);
	if(w === 1)
		w_expect(0);
	if(b === 1)
		b_expect(0, 2'bZZ, 4'bZZZZ);
	if(ar === 1)
		ar_expect(0);
	if(r === 1)
		r_expect(0, 2'bZZ, 32'hZZZZ_ZZZZ, 2'bZZ, 1'bZ);
end endtask
*/

initial begin
    integer i;
    integer word;
    @(posedge rst_n);

    for(i = 0; i < HOST_NUMBER; i = i + 1) begin
        upstream_ar_noop(i);
        
    end
    downstream_ar_op(0);
    #5
    for(i = 0; i < HOST_NUMBER; i = i + 1) begin
        upstream_ar_expect(i, 0);
    end
    @(negedge clk);
    

    @(negedge clk);
    
    @(negedge clk);
    @(negedge clk);

    `assert_finish;
end


endmodule