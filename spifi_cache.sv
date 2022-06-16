module spifi_cache (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    // AHB-Spifi interface
    input   logic           i_hsel_spifi,

    input   logic   [31:0]  i_haddr_spifi,
    input   logic           i_hwrite_spifi,
    input   logic   [ 2:0]  i_hsize_spifi,
    input   logic   [ 2:0]  i_hburst_spifi,
    input   logic   [ 3:0]  i_hprot_spifi,
    input   logic   [ 1:0]  i_htrans_spifi,
    input   logic           i_hmastlock_spifi,
    input   logic           i_hready_spifi,
    input   logic   [31:0]  i_hwdata_spifi,

    output  logic           o_hready_spifi,
    output  logic           o_hresp_spifi,
    output  logic   [31:0]  o_hrdata_spifi,

    output  logic           o_irq_spifi,
    output  logic           o_drqw_spifi,
    output  logic           o_drqr_spifi,

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

    // SPIFI-Flash interface
    input   logic           i_spifi_sck,
    input   logic   [ 3:0]  i_spifi_si,
    output  logic           o_spifi_sck,
    output  logic   [ 3:0]  o_spifi_so,
    output  logic   [ 3:0]  o_spifi_soen,
    output  logic           o_spifi_cs,
    output  logic           o_spifi_tri
    );

    logic           nbypass;
    logic   [31:0]  climit;
    logic           prefetch_dis;
    logic           d_cache_dis;

    logic           hsel_sl;
    logic           hready_i_sl;
    logic   [31:0]  haddr_sl;
    logic           hwrite_sl;
    logic   [2:0]   hsize_sl;
    logic   [2:0]   hburst_sl;
    logic   [3:0]   hprot_sl;
    logic   [1:0]   htrans_sl;
    logic           hmastlock_sl;
    logic   [31:0]  hwdata_sl;
    logic   [31:0]  hrdata_sl;
    logic           hready_o_sl;
    logic           hresp_sl;

    cache cache (
        .i_hclk (i_hclk),
        .i_hnreset (i_hnreset),

        .i_hsel_m (i_hsel_m),
        .i_haddr_m (i_haddr_m),
        .i_hwrite_m (i_hwrite_m),
        .i_hsize_m (i_hsize_m),
        .i_hburst_m (i_hburst_m),
        .i_hprot_m (i_hprot_m),
        .i_htrans_m (i_htrans_m),
        .i_hmastlock_m (i_hmastlock_m),
        .i_hready_m (i_hready_m),
        .i_hwdata_m (i_hwdata_m),
        .o_hready_m (o_hready_m),
        .o_hresp_m (o_hresp_m),
        .o_hrdata_m (o_hrdata_m),

        .i_nbypass (nbypass),
        .i_climit (climit),
        .i_prefetch_dis (prefetch_dis),
        .i_d_cache_en (~d_cache_dis),

        .o_hsel_sl (hsel_sl),
        .o_hready_i_sl (hready_i_sl),
        .o_haddr_sl (haddr_sl),
        .o_hwrite_sl (hwrite_sl),
        .o_hsize_sl (hsize_sl),
        .o_hburst_sl (hburst_sl),
        .o_hprot_sl (hprot_sl),
        .o_htrans_sl (htrans_sl),
        .o_hmastlock_sl (hmastlock_sl),
        .o_hwdata_sl (hwdata_sl),
        .i_hrdata_sl (hrdata_sl),
        .i_hready_o_sl (hready_o_sl),
        .i_hresp_sl (hresp_sl)
        );

    spifi_top spifi_to_cache (
        .IRQ_o (o_irq_spifi),
        .DRQw_o (o_drqw_spifi),
        .DRQr_o (o_drqr_spifi),
        // Cache control
        .CACHE_EN_o (nbypass),
        .PRFTCH_DIS_o (prefetch_dis),
        .D_PRFTCH_DIS_o (d_cache_dis),
        .CLimit_o (climit),
        // AHB Lite bus
        .HCLK (i_hclk),
        .HRESETn (i_hnreset),
        .HSEL_i (i_hsel_spifi),
        .HREADY_i (i_hready_spifi),
        .HADDR_i (i_haddr_spifi),
        .HWRITE_i (i_hwrite_spifi),
        .HSIZE_i (i_hsize_spifi),
        .HBURST_i (i_hburst_spifi),
        .HPROT_i (i_hprot_spifi),
        .HTRANS_i (i_htrans_spifi),
        .HMASTLOCK_i (i_hmastlock_spifi),
        .HWDATA_i (i_hwdata_spifi),
        .HRDATA_o (o_hrdata_spifi),
        .HREADY_o (o_hready_spifi),
        .HRESP_o (o_hresp_spifi),
        // AHB Memory bus
        .HSEL_im (hsel_sl),
        .HREADY_im (hready_i_sl),
        .HADDR_im (haddr_sl),
        .HWRITE_im (hwrite_sl),
        .HSIZE_im (hsize_sl),
        .HBURST_im (hburst_sl),
        .HPROT_im (hprot_sl),
        .HTRANS_im (htrans_sl),
        .HMASTLOCK_im (hmastlock_sl),
        .HWDATA_im (hwdata_sl),
        .HRDATA_om (hrdata_sl),
        .HREADY_om (hready_o_sl),
        .HRESP_om (hresp_sl),
        // SPIFI Signals
        .SPIFI_CS_o (o_spifi_cs),
        .SPIFI_SCK_o (o_spifi_sck),
        .SPIFI_SCK_i (i_spifi_sck),
        .SPIFI_SI_i (i_spifi_si),
        .SPIFI_SO_o (o_spifi_so),
        .SPIFI_SO_oe (o_spifi_soen),
        .Tri_o (o_spifi_tri)
        );

endmodule
