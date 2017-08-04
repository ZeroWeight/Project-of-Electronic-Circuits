`timescale 1us / 1us

module OV_STORE (
    input clk_25MHz,
    input rst_n,
    input initialized,
    output reg wen = 1'b0,
    output reg wrst = 1'b1,
    input vsync,
    output reg new_frame = 1'b0,
    input frame_read
);    
    reg[3:0] frame_cnt = 1'd0;
    reg noisy = 1'b1;
    reg[2:0] state = 3'd0;
    always @(posedge clk_25MHz or negedge rst_n)
        if (!rst_n) begin
            wen <= 1'b0; wrst <= 1'b1;
            new_frame <= 1'b0;
            frame_cnt <= 1'd0; noisy <= 1'b1;
            state <= 3'd0;
        end else if (initialized)
        case (state)
        3'd0: if (!vsync) state <= 3'd1; // wait vsync negedge
        3'd1: if (vsync) begin wrst <= 1'b0; state <= 3'd2; end // wait vsync posedge, write reset
        3'd2: begin wrst <= 1'b1; state <= 3'd3; end
        3'd3: begin wen <= 1'b1; state <= 3'd4; end // write enable
        3'd4: if (!vsync) state <= 3'd5; // wait vsync negedge, frame written
        3'd5: if (vsync) begin // wait vsync posedge
            wen <= 1'b0; // write disable
            if (frame_cnt == 4'd10) noisy <= 1'b0; // 不管前10帧稳不稳定反正老子不要了
            if (noisy) begin frame_cnt <= frame_cnt + 1'd1; state <= 3'd0; end
            else begin new_frame <= 1'b1; state <= 3'd6; end
        end
        3'd6: if (!frame_read) state <= 3'd7; // wait read begin
        3'd7: if (frame_read) begin new_frame <= 1'b0; state <= 3'd0; end
        endcase
endmodule
