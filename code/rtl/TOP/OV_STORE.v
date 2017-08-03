`timescale 1us / 1us

module OV_STORE (
    input clk_25MHz,
    input rst_n,
    output reg wen = 1'b1,
    output reg wrst = 1'b1,
    input vsync,
    output reg new_frame = 1'b0,
    input frame_read
);
endmodule
