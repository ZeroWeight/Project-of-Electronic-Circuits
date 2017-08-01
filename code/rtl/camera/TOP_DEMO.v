`timescale 1us / 1us

module TOP_DEMO (
    input sys_clk,
    input rst_n,
    output reg scl, // sccb clock
    inout sda, // sccb data
    input d7, d6, d5, d4, d3, d2, d1, d0, // fifo data
    output reg rclk = 1'b1, // fifo read clock
    output reg wen = 1'b1, // fifo write enable
    output reg wrst = 1'b1, // fifo write reset
    output reg rrst = 1'b1, // fifo read reset
    input vsync // frame alignment
);
    parameter SYS_CLK_FREQ = 100_000_000;
    parameter DEVICE_ID = 8'h42;
    
    localparam [11:0] cnt_50us = 12'd2500;
    reg clk_50us = 1'b0;
    reg[11:0] clk_cnt = cnt_50us;
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) clk_cnt <= cnt_50us;
        else if (!clk_cnt) clk_cnt <= cnt_50us;
        else clk_cnt <= clk_cnt - 1'b1;
    always @(posedge sys_clk) if (!clk_cnt) clk_50us <= ~clk_50us;
    
    reg[7:0] conf[0:255];
    initial $readmemh("CONF.hex", conf); // read config file
    
    // camera initialization
    `include "SCCB.vh"
    reg success;
    reg[7:0] addr;
    initial begin
        sccb_write_reg(8'h12, 8'h80, success);
        repeat(400) @(posedge clk_50us);
        for (addr = 8'h00; addr <= 8'hFF; addr = addr + 1'b1)
            sccb_write_reg(addr, conf[addr], success);
    end
    
    // store one frame
    reg[0:2] vsync_reg = 3'b0;
    wire vsync_irq = vsync_reg[1] & ~vsync_reg[2]; // posedge vsync
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) vsync_reg <= 3'b0;
        else vsync_reg <= {vsync, vsync_reg[0:1]};
    reg new_frame = 1'b0; // 0: write allowed
    reg frame_read = 1'b0;
    reg[2:0] store_state = 3'd0; // state machine
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) begin wen <= 1'b0; new_frame <= 1'b0; store_state <= 3'd0; end
        else case (store_state)
        3'd0: if (vsync_irq) if (new_frame) wen <= 1'b0; else store_state <= 3'd1;
        3'd1: begin wrst <= 1'b0; store_state <= 3'd2; end
        3'd2: begin wrst <= 1'b1; wen <= 1'b1; store_state <= 3'd3; end
        3'd3: begin new_frame <= 1'b1; store_state <= 3'd4; end
        3'd4: store_state <= 3'd5;
        3'd5: if (frame_read) begin new_frame <= 1'b0; store_state <= 3'd0; end
        default: store_state <= 3'd0;
        endcase
    
    // read one frame
    wire[7:0] data = {d7, d6, d5, d4, d3, d2, d1, d0};
    localparam [17:0] bytes = 320 * 240 * 2;
    reg[17:0] byte_cnt = bytes;
    reg[2:0] read_state = 3'd0; // state machine
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) read_state <= 3'd0;
        else case (read_state)
        3'd0: if (new_frame) begin frame_read <= 1'b0; byte_cnt <= bytes; read_state <= 3'd1; end
        3'd1: begin rclk <= 1'b0; rrst <= 1'b0; read_state <= 3'd2; end
        3'd2: begin rclk <= 1'b1; read_state <= 3'd3; end
        3'd3: begin rclk <= 1'b0; rrst <= 1'b1; read_state <= 3'd4; end
        3'd4: begin rclk <= 1'b1; read_state <= 3'd5; end
        3'd5: begin rclk <= 1'b0; byte_cnt <= byte_cnt - 1'b1; read_state <= 3'd6; end // read one byte
        3'd6: begin rclk <= 1'b1; read_state <= byte_cnt ? 3'd5 : 3'd7; end
        3'd7: begin frame_read <= 1'b1; read_state <= 3'd0; end
        endcase
endmodule
