`timescale 1us / 1us

module OV_STORE (
    input clk_25MHz,
    input rst_n,
    input initialized,
    output reg wen = 1'b1,
    output reg wrst = 1'b1,
    input vsync,
    output reg new_frame = 1'b0,
    input frame_read
);
    reg[0:2] vsync_reg = {3{1'b0}};
    always @(posedge clk_25MHz or negedge rst_n)
        if (!rst_n) vsync_reg <= {3{1'b0}};
        else if (initialized) vsync_reg <= {vsync, vsync_reg[0:1]};
    wire vsync_irq = vsync_reg[1] & ~vsync_reg[2]; // posedge
    
    reg[2:0] state = 3'd0;
    always @(posedge clk_25MHz or negedge rst_n)
        if (!rst_n) begin
            wen <= 1'b0; wrst <= 1'b0;
            new_frame <= 1'b0;
            state <= 3'd0;
        end else if (initialized)
        case (state)
        3'd0: if (vsync_irq) state <= 3'd1;
        3'd1: begin wrst <= 1'b0; state <= 3'd2; end
        3'd2: begin wen <= 1'b1; wrst <= 1'b1; state <= 3'd3; end
        3'd3: if (vsync_irq) state <= 3'd4;
        3'd4: begin wen <= 1'b0; new_frame <= 1'b1; state <= 3'd5; end
        3'd5: if (!frame_read) state <= 3'd6;
        3'd6: if (frame_read) begin new_frame <= 1'b0; state <= 3'd0; end
        default: state <= 3'd0;
        endcase
endmodule
