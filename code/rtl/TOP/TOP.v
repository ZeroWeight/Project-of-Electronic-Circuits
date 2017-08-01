`timescale 1us / 1us

module TOP (
    input sys_clk,
    input rst_n,
    input rx_pin,
    output tx_pin,
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
    parameter BAUD_RATE = 115200;
    
    wire clk;
    CLK_GEN #(SYS_CLK_FREQ, BAUD_RATE) clk_gen(sys_clk, rst_n, clk);
    
    wire rx_error;
    wire rx_finish;
    wire[7:0] rx_data;
    UART_RX rx(clk, rst_n, rx_pin, rx_error, rx_finish, rx_data);
    
    reg tx_start = 1'b0;
    wire tx_finish;
    reg[7:0] tx_data = 8'h00;
    UART_TX tx(clk, rst_n, tx_pin, tx_start, tx_finish, tx_data);
    
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
            if (conf[addr] != 8'hXX) sccb_write_reg(addr, conf[addr], success);
    end
    
    // store one frame
    reg[0:2] vsync_reg = 3'b0;
    wire vsync_irq = vsync_reg[1] & ~vsync_reg[2]; // posedge vsync
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) vsync_reg <= 3'b0;
        else vsync_reg <= {vsync, vsync_reg[0:1]};
    reg new_frame = 1'b0; // 0: write allowed
    reg frame_read = 1'b0;
    reg[2:0] store_state = 3'h0; // state machine
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) begin wen <= 1'b0; new_frame <= 1'b0; store_state <= 3'h0; end
        else case (store_state)
        3'h0: if (vsync_irq) if (new_frame) wen <= 1'b0; else store_state <= 3'h1;
        3'h1: begin wrst <= 1'b0; store_state <= 3'h2; end
        3'h2: begin wrst <= 1'b1; wen <= 1'b1; store_state <= 3'h3; end
        3'h3: begin new_frame <= 1'b1; store_state <= 3'h4; end
        3'h4: store_state <= 3'h5;
        3'h5: if (frame_read) begin new_frame <= 1'b0; store_state <= 3'h0; end
        default: store_state <= 3'h0;
        endcase
    
    // read one frame
    wire[7:0] frame_data = {d7, d6, d5, d4, d3, d2, d1, d0};
    localparam [17:0] frame_bytes = 320 * 240 * 2;
    reg[17:0] byte_cnt = frame_bytes;
    reg[3:0] read_state = 4'h0; // state machine
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) read_state <= 4'h0;
        else case (read_state)
        4'h0: if (new_frame) begin frame_read <= 1'b0; byte_cnt <= frame_bytes; read_state <= 4'h1; end
        4'h1: begin rclk <= 1'b0; rrst <= 1'b0; read_state <= 4'h2; end
        4'h2: begin rclk <= 1'b1; read_state <= 4'h3; end
        4'h3: begin rclk <= 1'b0; rrst <= 1'b1; read_state <= 4'h4; end
        4'h4: begin rclk <= 1'b1; read_state <= 4'h5; end
        4'h5: if (tx_finish) begin rclk <= 1'b0; read_state <= 4'h6; end
        4'h6: begin tx_start <= 1'b1; tx_data <= frame_data; byte_cnt <= byte_cnt - 1'b1; read_state <= 4'h7; end
        4'h7: if (!tx_finish) begin rclk <= 1'b1; tx_start <= 1'b0; read_state <= byte_cnt ? 4'h5 : 4'h8; end
        4'h8: if (tx_finish) begin tx_start <= 1'b1; tx_data <= 8'h0D; read_state <= 4'h9; end
        4'h9: if (!tx_finish) begin tx_start <= 1'b0; read_state <= 4'hA; end
        4'hA: if (tx_finish) begin tx_start <= 1'b1; tx_data <= 8'h0A; read_state <= 4'hB; end
        4'hB: if (!tx_finish) begin tx_start <= 1'b0; frame_read <= 1'b1; read_state <= 4'h0; end
        default: read_state <= 4'h0;
        endcase
endmodule
