`timescale 1us / 1us

module TOP_DEMO(
    input sys_clk,
    input rst_n,
    input rx_pin,
    output tx_pin
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
    
    // demo: transmit exactly what was received
    always @(posedge sys_clk) begin tx_start <= rx_finish; tx_data <= rx_data; end
endmodule
