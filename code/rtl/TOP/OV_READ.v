`timescale 1us / 1us

module OV_READ (
    input clk_25MHz,
    input rst_n,
    input [7:0] fifo_data,
    output reg rclk = 1'b1,
    output reg rrst = 1'b1,
    input new_frame,
    output reg frame_read = 1'b0
);
endmodule
