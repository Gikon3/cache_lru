module cache_mux_ahb (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    input   logic           i_en,

    // AHB-in0 interface
    input   logic           i_hsel0,

    input   logic   [31:0]  i_haddr0,
    input   logic           i_hwrite0,
    input   logic   [ 2:0]  i_hsize0,
    input   logic   [ 2:0]  i_hburst0,
    input   logic   [ 3:0]  i_hprot0,
    input   logic   [ 1:0]  i_htrans0,
    input   logic           i_hmastlock0,
    input   logic           i_hready0_i,
    input   logic   [31:0]  i_hwdata0,

    input   logic           i_hready0_o,
    input   logic           i_hresp0,
    input   logic   [31:0]  i_hrdata0,

    // AHB-in1 interface
    input   logic           i_hsel1,

    input   logic   [31:0]  i_haddr1,
    input   logic           i_hwrite1,
    input   logic   [ 2:0]  i_hsize1,
    input   logic   [ 2:0]  i_hburst1,
    input   logic   [ 3:0]  i_hprot1,
    input   logic   [ 1:0]  i_htrans1,
    input   logic           i_hmastlock1,
    input   logic           i_hready1_i,
    input   logic   [31:0]  i_hwdata1,

    input   logic           i_hready1_o,
    input   logic           i_hresp1,
    input   logic   [31:0]  i_hrdata1,

    // AHB-out interface
    output  logic           o_hsel,

    output  logic   [31:0]  o_haddr,
    output  logic           o_hwrite,
    output  logic   [ 2:0]  o_hsize,
    output  logic   [ 2:0]  o_hburst,
    output  logic   [ 3:0]  o_hprot,
    output  logic   [ 1:0]  o_htrans,
    output  logic           o_hmastlock,
    output  logic           o_hready_i,
    output  logic   [31:0]  o_hwdata,

    output  logic           o_hready_o,
    output  logic           o_hresp,
    output  logic   [31:0]  o_hrdata
    );

    enum logic {IDLE, DATA} state_list;

    logic   state_idle;
    logic   state_data;
    logic   current_state;
    logic   next_state;
    logic   enable1_in;
    logic   enable1_out;

    // State machine
    assign state_idle = current_state == IDLE;
    assign state_data = current_state == DATA;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) current_state <= IDLE;
        else current_state <= next_state;

    always_comb
        case (current_state)
            IDLE:
                if (i_en)
                    next_state = DATA;
                else 
                    next_state = IDLE;
            DATA:
                if (o_hready_o && !i_en)
                    next_state = IDLE;
                else
                    next_state = DATA;
        endcase

    // signals
    assign enable1_in = i_en | (state_data & !o_hready_o);
    assign enable1_out = state_data;

    // Mux Bus
    assign o_hsel = enable1_in ? i_hsel1: i_hsel0;
    assign o_haddr = enable1_in ? i_haddr1: i_haddr0;
    assign o_hwrite = enable1_in ? i_hwrite1: i_hwrite0;
    assign o_hsize = enable1_in ? i_hsize1: i_hsize0;
    assign o_hburst = enable1_in ? i_hburst1: i_hburst0;
    assign o_hprot = enable1_in ? i_hprot1: i_hprot0;
    assign o_htrans = enable1_in ? i_htrans1: i_htrans0;
    assign o_hmastlock = enable1_in ? i_hmastlock1: i_hmastlock0;
    assign o_hready_i = enable1_in ? i_hready1_i: i_hready0_i;
    assign o_hwdata = enable1_in ? i_hwdata1: i_hwdata0;

    assign o_hready_o = enable1_out ? i_hready1_o: i_hready0_o;
    assign o_hresp = enable1_out ? i_hresp1: i_hresp0;
    assign o_hrdata = enable1_out ? i_hrdata1: i_hrdata0;

endmodule
