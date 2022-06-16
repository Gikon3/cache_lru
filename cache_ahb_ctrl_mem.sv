module cache_ahb_ctrl_mem (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    // AHB interface
    input   logic           i_hsel,

    input   logic   [31:0]  i_haddr,
    input   logic           i_hwrite,
    input   logic   [ 2:0]  i_hsize,
    input   logic   [ 2:0]  i_hburst,
    input   logic   [ 3:0]  i_hprot,
    input   logic   [ 1:0]  i_htrans,
    input   logic           i_hmastlock,
    input   logic           i_hready,
    input   logic   [31:0]  i_hwdata,

    output  logic           o_hready,
    output  logic           o_hresp,
    output  logic   [31:0]  o_hrdata,

    // Cache config signals
    input   logic           i_nbypass,
    input   logic           i_d_cache_en,
    input   logic   [31:0]  i_climit,
    input   logic           i_prefetch_dis,

    // Calc signals
    input   logic           i_miss_cache,
    output  logic           o_calc_en,
    output  logic           o_calc_ch_bl,   // o_calc_change_block

    // Slave signals
    input   logic           i_sl_ready,
    input   logic   [31:0]  i_sl_rdata,
    output  logic           o_sl_en,
    output  logic   [29:0]  o_sl_addr,

    // Mem signals
    input   logic   [31:0]  i_mem_rdata,
    output  logic           o_mem_en,
    output  logic           o_mem_we,

    // Mux signals
    output  logic           o_through_ahb,
    output  logic           o_prftch_en,
    output  logic   [29:0]  o_prftch_addr
    );

    enum logic [2:0] {IDLE, READ_CACHE, READ_FLASH, POST_FLASH, PREF_ADDR, PREF_DATA, THROUGH} state_list;

    logic           cache_area;
    logic           cache_en;

    logic           request;
    logic           request_read;
    logic           request_read_ready;
    logic           first_request;
    logic   [31:0]  haddr;

    logic           pref_haddr_full;
    logic           prefetch_en;
    logic           prefetch_inc_en;
    logic   [29:0]  prefetch_addr;
    logic           prefetch_full;
    logic           prefetch_full_reg_en;
    logic           prefetch_full_reg;

    logic           state_idle;
    logic           state_read_cache;
    logic           state_read_flash;
    logic           state_post_flash;
    logic           state_pref_addr;
    logic           state_pref_data;
    logic           state_through;
    logic           switch_read_cache;
    logic           switch_read_flash;
    logic           switch_pref_addr;
    logic           switch_pref_data;
    logic           switch_through;
    logic   [2:0]   current_state;
    logic   [2:0]   next_state;

    logic           pref_calc_addr_en;
    logic           pref_sl_addr_en;

    // signals
    assign cache_area = i_haddr < i_climit;
    assign cache_en = i_nbypass & cache_area & (!i_hprot[0] | (i_hprot[0] & i_d_cache_en));

    // AHB-Control
    assign request = i_hsel & i_htrans[1] & i_hready;
    assign request_read = request & !i_hwrite & cache_en;
    assign request_read_ready = request_read & o_hready;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) first_request <= 'd0;
        else if(request_read_ready) first_request <= 1'b1;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) haddr <= 'd0;
        else if (request_read_ready) haddr <= i_haddr;

    assign o_hready = !state_read_flash;
    assign o_hresp = 1'b0;
    assign o_hrdata = state_read_cache || state_post_flash ? i_mem_rdata: 'd0;

    // prefetch
    assign pref_haddr_full = haddr[6:2] == 5'h1F;
    assign prefetch_en = state_idle & !request_read_ready & !i_miss_cache & first_request
                         & !prefetch_full_reg & !i_prefetch_dis & !pref_haddr_full;
    assign prefetch_inc_en = (state_pref_addr | (state_pref_data & i_sl_ready)) & !prefetch_full;
    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) prefetch_addr <= 'd0;
        else if (prefetch_en) prefetch_addr <= haddr[31:2] + 30'h1;
        else if (prefetch_inc_en) prefetch_addr <= prefetch_addr + 30'h1;

    assign prefetch_full = prefetch_addr[4:0] == 5'h1F;
    assign prefetch_full_reg_en = (state_pref_addr | state_pref_data) & i_sl_ready & prefetch_full;
    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) prefetch_full_reg <= 'd0;
        else if (prefetch_full_reg_en) prefetch_full_reg <= 1'b1;
        else if (request_read_ready) prefetch_full_reg <= 'd0;

    // State machine
    assign state_idle = current_state == IDLE;
    assign state_read_cache = current_state == READ_CACHE;
    assign state_read_flash = current_state == READ_FLASH;
    assign state_post_flash = current_state == POST_FLASH;
    assign state_pref_addr = current_state == PREF_ADDR;
    assign state_pref_data = current_state == PREF_DATA;
    assign state_through = current_state == THROUGH;

    assign switch_read_cache = request_read_ready & !i_miss_cache;
    assign switch_read_flash = request_read_ready & i_miss_cache;
    assign switch_pref_addr = i_sl_ready & !request & !i_prefetch_dis & !prefetch_full_reg & first_request;
    assign switch_pref_data = !request & !i_hwrite & i_miss_cache & !i_prefetch_dis;
    assign switch_through = request & !request_read;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) current_state <= IDLE;
        else current_state <= next_state;

    always_comb
        case (current_state)
            IDLE:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (switch_pref_addr)
                    next_state = PREF_ADDR;
                else
                    next_state = IDLE;
            READ_CACHE:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (!request_read_ready)
                    next_state = IDLE;
                else
                    next_state = READ_CACHE;
            READ_FLASH:
                if (i_sl_ready)
                    next_state = POST_FLASH;
                else
                    next_state = READ_FLASH;
            POST_FLASH:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (!request_read_ready)
                    next_state = IDLE;
                else
                    next_state = READ_FLASH;
            PREF_ADDR:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (i_prefetch_dis)
                    next_state = IDLE;
                else if (switch_pref_data)
                    next_state = PREF_DATA;
                else
                    next_state = PREF_ADDR;
            PREF_DATA:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (i_prefetch_dis)
                    next_state = IDLE;
                else if (switch_pref_addr && !i_miss_cache)
                    next_state = PREF_ADDR;
                else
                    next_state = PREF_DATA;
            THROUGH:
                if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (i_sl_ready && !request)
                    next_state = IDLE;
                else
                    next_state = THROUGH;
            default:
                next_state = IDLE;
        endcase

    // signals
    assign pref_calc_addr_en = state_pref_addr | (state_pref_data & i_sl_ready & !prefetch_full_reg);
    assign pref_sl_addr_en = pref_calc_addr_en & i_miss_cache;

    // Mem-Slave Control signals
    assign o_calc_en = request_read_ready | pref_calc_addr_en;
    assign o_calc_ch_bl = request_read_ready && i_haddr[31:7] != haddr[31:7];
    assign o_sl_en = switch_read_flash | pref_sl_addr_en;
    assign o_sl_addr = pref_sl_addr_en && !request_read ? prefetch_addr:
                       request_read ? i_haddr[31:2]: haddr[31:2];
    assign o_mem_en = switch_read_cache | o_mem_we;
    assign o_mem_we = (state_read_flash | state_pref_data) & i_sl_ready;
    assign o_through_ahb = (request & !request_read) | (state_through & !request_read_ready);
    assign o_prftch_en = pref_calc_addr_en & !request_read;
    assign o_prftch_addr = prefetch_addr;

endmodule
