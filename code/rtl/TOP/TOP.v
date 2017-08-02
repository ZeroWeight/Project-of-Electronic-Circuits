`timescale 1us / 1us

module TOP (
    input sys_clk,
    input rst_n,
    input rx_pin,
    output tx_pin,
    output scl, // sccb clock
    inout sda, // sccb data
    output wen, // fifo write enable
    output wrst, // fifo write reset
    input vsync, // frame alignment
    input [7:0] fifo_data, // fifo data
    output rclk, // fifo read clock
    output rrst // fifo read reset
);
    /*-------------------------------------------------
     |                     Clocks                     |
     -------------------------------------------------*/
    parameter SYS_CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115200;
    
    wire clk_uart, clk_100kHz, clk_25MHz;
    CLK_GEN #(SYS_CLK_FREQ, BAUD_RATE) clk_gen_uart(sys_clk, rst_n, clk_uart);
    CLK_GEN #(SYS_CLK_FREQ, 100_000) clk_gen_100kHz(sys_clk, rst_n, clk_100kHz);
    CLK_GEN #(SYS_CLK_FREQ, 25_000_000) clk_gen_25MHz(sys_clk, rst_n, clk_25MHz);
    
    /*-------------------------------------------------
     |                      UART                      |
     -------------------------------------------------*/
    wire rx_error;
    wire rx_finish;
    wire[7:0] rx_data;
    UART_RX rx(clk_uart, rst_n, rx_pin, rx_error, rx_finish, rx_data);
    
    reg tx_start = 1'b0;
    wire tx_finish;
    reg[7:0] tx_data = 8'h00;
    UART_TX tx(clk_uart, rst_n, tx_pin, tx_start, tx_finish, tx_data);
    
    /*-------------------------------------------------
     |                     Camera                     |
     -------------------------------------------------*/
    parameter [7:0] DEVICE_ID = 8'h42;
    
    wire initialized;
    wire new_init_data;
    wire[7:0] init_data;
    OV_INIT #(DEVICE_ID) init(clk_100kHz, rst_n, scl, sda, initialized, new_init_data, init_data);
        
    wire new_frame;
    wire frame_read;
    wire new_frame_data;
    wire[7:0] frame_data;
    OV_STORE ov_s(clk_25MHz, rst_n, initialized, wen, wrst, vsync, new_frame, frame_read);
    OV_READ ov_r(clk_25MHz, rst_n, initialized, fifo_data, rclk, rrst, new_frame, frame_read, new_frame_data, frame_data);
    
    reg[0:2] new_init_data_reg = {3{1'b0}};
    reg[0:2] new_frame_data_reg = {3{1'b0}};
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) begin new_init_data_reg = {3{1'b0}}; new_frame_data_reg = {3{1'b0}}; end
        else if (!initialized) new_init_data_reg = {new_init_data, new_init_data_reg[0:1]};
        else new_frame_data_reg = {new_frame_data, new_frame_data_reg[0:1]};
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) tx_start <= 1'b0;
        else if (tx_start) begin if (!tx_finish) tx_start <= 1'b0; end
        else if (!initialized) begin tx_start <= new_init_data_reg[1] & ~new_init_data_reg[2]; tx_data <= init_data; end
        else begin tx_start <= new_frame_data_reg[1] & ~new_frame_data_reg[2]; tx_data <= frame_data; end
endmodule
