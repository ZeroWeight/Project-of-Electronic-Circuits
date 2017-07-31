`timescale 1us / 1us

module TOP_DEMO(
    input sys_clk,
    input rst_n,
    output reg scl,
    inout sda
);
    parameter SYS_CLK_FREQ = 100_000_000;
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
    initial $readmemh("CONF.hex", conf);
    
    `include "SCCB.vh"
    reg success;
    reg[7:0] addr;
    initial begin
        sccb_write_reg(8'h12, 8'h80, success);
        for (addr = 8'h00; addr <= 8'hFF; addr = addr + 1'b1)
            sccb_write_reg(addr, conf[addr], success);
    end
endmodule
