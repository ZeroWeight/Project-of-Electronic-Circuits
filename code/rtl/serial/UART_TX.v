`timescale 1us / 1us

module UART_TX (
    input clk,
    input rst_n,
    output reg pin,
    input start,
    output reg finish,
    input [7:0] data
);
    localparam IDLE = 1'b0, BUSY = 1'b1;
    reg[1:0] state = IDLE;
    reg[3:0] bits_remaining = 4'd0;
    reg[7:0] data_reg;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            pin <= 1'b1;
            finish <= 1'b0;
            state <= IDLE;
            bits_remaining <= 4'd0;
        end else 
        case (state)
        IDLE: begin
            pin <= 1'b1;
            finish <= 1'b1;
            if (start) begin
                pin <= 1'b0; // start bit
                finish <= 1'b0;
                state <= BUSY;
                bits_remaining <= 4'd9; // 8 data bits + 1 stop bit
                data_reg <= data;
            end
        end
        BUSY: begin
            if (bits_remaining == 1'd1) begin
                pin <= 1'b1; // stop bit
                finish <= 1'b1;
                state <= IDLE;
            end else {data_reg, pin} <= {1'b0, data_reg};
            bits_remaining <= bits_remaining - 1'd1;
        end
        endcase
endmodule