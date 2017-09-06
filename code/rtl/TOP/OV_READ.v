`timescale 1us / 1us

module OV_READ (
    input clk_24MHz,
    input rst_n,
    input initialized,
    input [7:0] fifo_data,
    output reg rclk = 1'b1,
    output reg rrst = 1'b1,
    input new_frame,
    output reg frame_read = 1'b1,
    output reg new_data = 1'b0,
    output reg[7:0] data
);
    localparam [8:0] cnt_15us = 9'd375;
    reg[8:0] delay_cnt = 1'd0;
    localparam [17:0] frame_bytes = 320 * 240 * 2;
    reg[17:0] bytes_remaining = frame_bytes;
    reg[3:0] state = 4'h0;
    always @(posedge clk_24MHz or negedge rst_n)
        if (!rst_n) begin 
            rclk <= 1'b1; rrst <= 1'b1;
            frame_read = 1'b1;
            state <= 4'h0;
        end else if (delay_cnt) delay_cnt <= delay_cnt - 1'd1;
        else if (initialized)
        case (state)
        4'h0: if (new_frame) begin
            frame_read <= 1'b0;
            bytes_remaining <= frame_bytes;
            state <= 4'h1;
        end
        4'h1: begin rrst <= 1'b0; state <= 4'h2; end
        4'h2: begin rclk <= 1'b0; state <= 4'h3; end
        4'h3: begin rclk <= 1'b1; state <= 4'h4; end
        4'h4: begin rclk <= 1'b0; state <= 4'h5; end
        4'h5: begin rrst <= 1'b1; state <= 4'h6; end
        4'h6: begin rclk <= 1'b1; state <= 4'h7; end
        4'h7: begin rclk <= 1'b0; state <= 4'h8; end
        4'h8: begin
            new_data <= 1'b1; data <= fifo_data;
            bytes_remaining <= bytes_remaining - 1'd1;
            state <= 4'h9;
        end
        4'h9: begin
            rclk <= 1'b1; new_data <= 1'b0;
            delay_cnt <= cnt_15us;
            state <= bytes_remaining ? 4'h7 : 4'hA;
        end
        4'hA: begin new_data <= 1'b1; data <= 8'h0D; state <= 4'hB; end
        4'hB: begin new_data <= 1'b0; delay_cnt <= cnt_15us; state <= 4'hC; end
        4'hC: begin new_data <= 1'b1; data <= 8'h0A; state <= 4'hD; end
        4'hD: begin new_data <= 1'b0; delay_cnt <= cnt_15us; state <= 4'hE; end
        4'hE: begin frame_read <= 1'b1; state <= 4'h0; end
        default: state <= 4'h0;
        endcase
endmodule
