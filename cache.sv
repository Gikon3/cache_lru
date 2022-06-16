module cache (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    // AHB-Mem interface
    input   logic           i_hsel_m,

    input   logic   [31:0]  i_haddr_m,
    input   logic           i_hwrite_m,
    input   logic   [ 2:0]  i_hsize_m,
    input   logic   [ 2:0]  i_hburst_m,
    input   logic   [ 3:0]  i_hprot_m,
    input   logic   [ 1:0]  i_htrans_m,
    input   logic           i_hmastlock_m,
    input   logic           i_hready_m,
    input   logic   [31:0]  i_hwdata_m,

    output  logic           o_hready_m,
    output  logic           o_hresp_m,
    output  logic   [31:0]  o_hrdata_m,

    // Cache config signals
    input   logic           i_nbypass,
    input   logic   [31:0]  i_climit,
    input   logic           i_prefetch_dis,
    input   logic           i_d_cache_en,

    // AHB-out intrface
    output  logic           o_hsel_sl,
    output  logic           o_hready_i_sl,
    output  logic   [31:0]  o_haddr_sl,
    output  logic           o_hwrite_sl,
    output  logic   [2:0]   o_hsize_sl,
    output  logic   [2:0]   o_hburst_sl,
    output  logic   [3:0]   o_hprot_sl,
    output  logic   [1:0]   o_htrans_sl,
    output  logic           o_hmastlock_sl,
    output  logic   [31:0]  o_hwdata_sl,
    input   logic   [31:0]  i_hrdata_sl,
    input   logic           i_hready_o_sl,
    input   logic           i_hresp_sl
    );

    logic           miss_cache;
    logic           calc_en;
    logic           calc_change_block;
    logic   [31:0]  mem_rdata;
    logic           mem_en;
    logic           mem_we;
    logic   [7:0]   mem_addr;
    logic           through_ahb;
    logic           prefetch_en;
    logic   [29:0]  prefetch_addr;
    logic   [29:0]  calc_addr;

    logic           slave_sel;
    logic   [29:0]  slave_addr;
    logic   [31:0]  slave_rdata;
    logic           slave_ready;

    logic           hsel_mux;
    logic   [31:0]  haddr_mux;
    logic           hwrite_mux;
    logic   [2:0]   hsize_mux;
    logic   [2:0]   hburst_mux;
    logic   [3:0]   hprot_mux;
    logic   [1:0]   htrans_mux;
    logic           hmastlock_mux;
    logic           hready_i_mux;
    logic   [31:0]  hwdata_mux;
    logic           hready_o_ahbc;
    logic           hresp_ahbc;
    logic   [31:0]  hrdata_ahbc;

    logic           hsel_sl;
    logic   [31:0]  haddr_sl;
    logic           hwrite_sl;
    logic   [2:0]   hsize_sl;
    logic   [2:0]   hburst_sl;
    logic   [3:0]   hprot_sl;
    logic   [1:0]   htrans_sl;
    logic           hmastlock_sl;
    logic   [31:0]  hwdata_sl;
    logic           hready_o_sl;

    cache_ahb_ctrl_mem cache_ahb_ctrl_mem (
        .i_hclk (i_hclk),
        .i_hnreset (i_hnreset),

        .i_hsel (i_hsel_m),
        .i_haddr (i_haddr_m),
        .i_hwrite (i_hwrite_m),
        .i_hsize (i_hsize_m),
        .i_hburst (i_hburst_m),
        .i_hprot (i_hprot_m),
        .i_htrans (i_htrans_m),
        .i_hmastlock (i_hmastlock_m),
        .i_hready (i_hready_m),
        .i_hwdata (i_hwdata_m),
        .o_hready (hready_o_ahbc),
        .o_hresp (hresp_ahbc),
        .o_hrdata (hrdata_ahbc),

        .i_nbypass (i_nbypass),
        .i_d_cache_en (i_d_cache_en),
        .i_climit (i_climit),
        .i_prefetch_dis (i_prefetch_dis),

        .i_miss_cache (miss_cache),
        .o_calc_en (calc_en),
        .o_calc_ch_bl (calc_change_block),

        .i_sl_ready (slave_ready),
        .i_sl_rdata (slave_rdata),
        .o_sl_en (slave_sel),
        .o_sl_addr (slave_addr),

        .i_mem_rdata (mem_rdata),
        .o_mem_en (mem_en),
        .o_mem_we (mem_we),

        .o_through_ahb (through_ahb),
        .o_prftch_en (prefetch_en),
        .o_prftch_addr (prefetch_addr)
        );

    assign calc_addr = prefetch_en ? prefetch_addr: i_haddr_m[31:2];
    cache_calc cache_calc (
        .i_clk (i_hclk),
        .i_nreset (i_hnreset),

        .i_en (calc_en),
        .i_addr (calc_addr),
        .i_ready_wr (mem_we),
        .i_change_block (calc_change_block),
        .o_miss_cache (miss_cache),
        .o_addr (mem_addr)
        );

    cache_mem cache_mem(
        .i_clk (i_hclk),
        .i_nreset (i_hnreset),

        .i_enable (mem_en),
        .i_write (mem_we),
        .i_addr (mem_addr),
        .i_data (i_hrdata_sl),
        .o_data (mem_rdata)
        );

    cache_ahb_ctrl_out cache_ahb_ctrl_out (
        .i_hclk (i_hclk),
        .i_hnreset (i_hnreset),

        .i_sel (slave_sel),
        .i_addr (slave_addr),
        .o_rdata (slave_rdata),
        .o_ready (slave_ready),

        .o_hsel (hsel_sl),
        .o_haddr (haddr_sl),
        .o_hwrite (hwrite_sl),
        .o_hsize (hsize_sl),
        .o_hburst (hburst_sl),
        .o_hprot (hprot_sl),
        .o_htrans (htrans_sl),
        .o_hmastlock (hmastlock_sl),
        .o_hready (hready_o_sl),
        .o_hwdata (hwdata_sl),
        .i_hready (i_hready_o_sl),
        .i_hresp (i_hresp_sl),
        .i_hrdata (i_hrdata_sl)
        );

    cache_mux_ahb cache_mux_ahb (
        .i_hclk (i_hclk),
        .i_hnreset (i_hnreset),

        .i_en (through_ahb),

        .i_hsel0 (hsel_sl),
        .i_haddr0 (haddr_sl),
        .i_hwrite0 (hwrite_sl),
        .i_hsize0 (hsize_sl),
        .i_hburst0 (hburst_sl),
        .i_hprot0 (hprot_sl),
        .i_htrans0 (htrans_sl),
        .i_hmastlock0 (hmastlock_sl),
        .i_hready0_i (i_hready_o_sl),
        .i_hwdata0 (hwdata_sl),
        .i_hready0_o (hready_o_ahbc),
        .i_hresp0 (hresp_ahbc),
        .i_hrdata0 (hrdata_ahbc),

        .i_hsel1 (i_hsel_m),
        .i_haddr1 (i_haddr_m),
        .i_hwrite1 (i_hwrite_m),
        .i_hsize1 (i_hsize_m),
        .i_hburst1 (i_hburst_m),
        .i_hprot1 (i_hprot_m),
        .i_htrans1 (i_htrans_m),
        .i_hmastlock1 (i_hmastlock_m),
        .i_hready1_i (i_hready_m),
        .i_hwdata1 (i_hwdata_m),
        .i_hready1_o (hready_o_sl),
        .i_hresp1 (i_hresp_sl),
        .i_hrdata1 (i_hrdata_sl),

        .o_hsel (hsel_mux),
        .o_haddr (haddr_mux),
        .o_hwrite (hwrite_mux),
        .o_hsize (hsize_mux),
        .o_hburst (hburst_mux),
        .o_hprot (hprot_mux),
        .o_htrans (htrans_mux),
        .o_hmastlock (hmastlock_mux),
        .o_hready_i (hready_i_mux),
        .o_hwdata (hwdata_mux),
        .o_hready_o (o_hready_m),
        .o_hresp (o_hresp_m),
        .o_hrdata (o_hrdata_m)
        );

    assign o_hsel_sl = hsel_mux;
    assign o_hready_i_sl = hready_i_mux;
    assign o_haddr_sl = haddr_mux;
    assign o_hwrite_sl = hwrite_mux;
    assign o_hsize_sl = hsize_mux;
    assign o_hburst_sl = hburst_mux;
    assign o_hprot_sl = hprot_mux;
    assign o_htrans_sl = htrans_mux;
    assign o_hmastlock_sl = hmastlock_mux;
    assign o_hwdata_sl = hwdata_mux;

endmodule
