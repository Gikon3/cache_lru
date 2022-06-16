module cache_calc (
    input   logic           i_clk,
    input   logic           i_nreset,

    input   logic           i_en,
    input   logic   [29:0]  i_addr, // [29:8] - tag, [7:5] - block, [4:0] - word
    input   logic           i_ready_wr,
    input   logic           i_change_block,
    output  logic           o_miss_cache,
    output  logic   [7:0]   o_addr
    );

    logic   [21:0]  addr_tag;
    logic   [2:0]   addr_block;
    logic   [4:0]   addr_word;
    logic   [7:0]   addr_reg;
    logic   [2:0]   addr_reg_block;
    logic   [4:0]   addr_reg_word;
    logic   [7:0]   full_blok_bus;
    logic           empty_bloks;
    logic   [2:0]   num_empty_block;
    logic   [7:0]   miss_tag_block_bus;
    logic   [2:0]   num_hit_tag_block;
    logic           miss_tag_block;
    logic           miss_word;
    logic   [7:0]   count_hit_block_full;
    logic   [2:0]   num_count_hit_block_full;
    logic   [24:0]  addr_mem [7:0];
    logic           we_word_dust_mem;
    logic           we_bit_dust_mem;
    logic   [31:0]  dust_mem [7:0];
    logic   [2:0]   count_hit_block_next [7:0];
    logic   [2:0]   count_hit_block [7:0];
    logic   [7:0]   addr_out;
    logic   [7:0]   addr_out_reg;

    assign addr_tag = i_addr[29:8];
    assign addr_block = i_addr[7:5];
    assign addr_word = i_addr[4:0];

    always_ff @(posedge i_clk, negedge i_nreset)
        if (!i_nreset) addr_reg <= 'd0;
        else if (miss_tag_block && !empty_bloks) addr_reg <= {num_count_hit_block_full, addr_word};
        else if (miss_tag_block) addr_reg <= {num_empty_block, addr_word};
        else if (miss_word) addr_reg <= {num_hit_tag_block, addr_word};

    assign addr_reg_block = addr_reg[7:5];
    assign addr_reg_word = addr_reg[4:0];

    always_ff @(posedge i_clk, negedge i_nreset)
        if (!i_nreset) full_blok_bus <= 'd0;
        else if (miss_tag_block) full_blok_bus[num_count_hit_block_full] <= 1'b1;

    assign empty_bloks = !(&full_blok_bus);

    always_comb
        casez (full_blok_bus)
            8'b????_???0: num_empty_block = 3'h0;
            8'b????_??01: num_empty_block = 3'h1;
            8'b????_?011: num_empty_block = 3'h2;
            8'b????_0111: num_empty_block = 3'h3;
            8'b???0_1111: num_empty_block = 3'h4;
            8'b??01_1111: num_empty_block = 3'h5;
            8'b?011_1111: num_empty_block = 3'h6;
            8'b0111_1111: num_empty_block = 3'h7;
            default: num_empty_block = 3'h0;
        endcase

    generate
    genvar i;
    for (i = 0; i < 8; i ++)
        assign miss_tag_block_bus[i] = i_en && addr_mem[i] != {addr_tag, addr_block};
    endgenerate

    always_comb
        case (miss_tag_block_bus)
            8'b0111_1111: num_hit_tag_block = 3'h7;
            8'b1011_1111: num_hit_tag_block = 3'h6;
            8'b1101_1111: num_hit_tag_block = 3'h5;
            8'b1110_1111: num_hit_tag_block = 3'h4;
            8'b1111_0111: num_hit_tag_block = 3'h3;
            8'b1111_1011: num_hit_tag_block = 3'h2;
            8'b1111_1101: num_hit_tag_block = 3'h1;
            8'b1111_1110: num_hit_tag_block = 3'h0;
            default: num_hit_tag_block = 3'h0;
        endcase

    assign miss_tag_block = &miss_tag_block_bus;
    assign miss_word = i_en && dust_mem[num_hit_tag_block][addr_word] != 1'b1;
    assign o_miss_cache = miss_tag_block | miss_word;

    assign count_hit_block_full = {&count_hit_block[7], &count_hit_block[6], &count_hit_block[5], &count_hit_block[4],
                                   &count_hit_block[3], &count_hit_block[2], &count_hit_block[1], &count_hit_block[0]};
    always_comb
        casez (count_hit_block_full)
            8'b????_???1: num_count_hit_block_full = 3'h0;
            8'b????_??10: num_count_hit_block_full = 3'h1;
            8'b????_?100: num_count_hit_block_full = 3'h2;
            8'b????_1000: num_count_hit_block_full = 3'h3;
            8'b???1_0000: num_count_hit_block_full = 3'h4;
            8'b??10_0000: num_count_hit_block_full = 3'h5;
            8'b?100_0000: num_count_hit_block_full = 3'h6;
            8'b1000_0000: num_count_hit_block_full = 3'h7;
            default: num_count_hit_block_full = 3'h0;
        endcase

    always_ff @(posedge i_clk, negedge i_nreset)
     //   if (!i_nreset) addr_mem <= {8{'d0}}; //Galimov 07/07/2020
            if (!i_nreset) for (int j=0;j<8;j++)  addr_mem[j] <= 'd0; //Galimov 07/07/2020
        else if (miss_tag_block && i_change_block && !empty_bloks)
            addr_mem[num_count_hit_block_full] <= {addr_tag, addr_block};
        else if (miss_tag_block && i_change_block)
            addr_mem[num_empty_block] <= {addr_tag, addr_block};

    assign we_word_dust_mem = miss_tag_block;
    assign we_bit_dust_mem = i_ready_wr;
    always_ff @(posedge i_clk, negedge i_nreset)
      //  if (!i_nreset) dust_mem <= {8{'d0}}; //Galimov 07/07/2020
      if (!i_nreset) for (int k=0;k<8;k++) dust_mem[k] <= 'd0; //Galimov 07/07/2020
        else if (we_word_dust_mem && !empty_bloks) dust_mem[num_count_hit_block_full] <= 'd0;
        else if (we_word_dust_mem) dust_mem[num_empty_block] <= 'd0;
        else if (we_bit_dust_mem)
            dust_mem[addr_reg_block] <= dust_mem[addr_reg_block] | ('d1 << addr_reg_word);

    always_comb
        for (int i = 0; i < 8; i ++)
            if ((i == num_hit_tag_block && !miss_tag_block && i_change_block)
                || (i == num_count_hit_block_full && miss_tag_block && i_change_block && !empty_bloks)
                || (i == num_empty_block && miss_tag_block && i_change_block && empty_bloks))
                count_hit_block_next[i] = 3'h0;
            else if (count_hit_block[i] != 3'h7 && i_change_block)
                count_hit_block_next[i] = count_hit_block[i] + 3'h1;
            else
                count_hit_block_next[i] = count_hit_block[i];

    always_ff @(posedge i_clk, negedge i_nreset)
     //   if (!i_nreset) count_hit_block <= {8{3'h7}}; //Galimov 08/07/2020
          if (!i_nreset) for (int m=0;m<8;m++) count_hit_block[m] <= 3'h7; //Galimov 08/07/2020
        else if (i_en && i_change_block) count_hit_block <= count_hit_block_next;

    always_comb
        if (miss_tag_block && !empty_bloks) addr_out = {num_count_hit_block_full, addr_word};
        else if (miss_tag_block) addr_out = {num_empty_block, addr_word};
        else if (i_en) addr_out = {num_hit_tag_block, addr_word};
        else addr_out = addr_out_reg;

    always_ff @(posedge i_clk, negedge i_nreset)
        if (!i_nreset) addr_out_reg <= 'd0;
        else addr_out_reg <= addr_out;

    assign o_addr = !o_miss_cache ? addr_out: addr_out_reg;

endmodule
