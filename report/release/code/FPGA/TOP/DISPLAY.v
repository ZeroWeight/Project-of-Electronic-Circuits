`timescale 1us / 1us

module DISPLAY (
    input clk_250Hz,
    input rst_n,
    input [31:0] data,
    output reg[3:0] AN,
    output reg[0:7] Y
);
    always @(posedge clk_250Hz or negedge rst_n)
        if (!rst_n) AN <= 4'b1111;
        else case (AN)
        4'b0111: AN <= 4'b1011;
        4'b1011: AN <= 4'b1101;
        4'b1101: AN <= 4'b1110;
        4'b1110: AN <= 4'b0111;
        default: AN <= 4'b0111;
        endcase
        
    always @(AN or data)
        case (AN)
        4'b0111: Y <= data[31:24];
        4'b1011: Y <= data[23:16];
        4'b1101: Y <= data[15:8];
        4'b1110: Y <= data[7:0];
        default: Y <= 32'hFFFFFFFF;
        endcase
endmodule
