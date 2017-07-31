wire sda_in = sda;
reg sda_out = 1'b1;
reg en_sda_out = 1'b1;
assign sda = en_sda_out ? sda_out : 1'bZ;
    
task sccb_start;
begin
    sda_out = 1'b1;
    scl = 1'b1;
    @(posedge clk_50us);
    sda_out = 1'b0;
    @(posedge clk_50us);
    scl = 1'b0;
end
endtask

task sccb_stop;
begin
    sda_out = 1'b0;
    @(posedge clk_50us);
    scl = 1'b1;
    @(posedge clk_50us);
    sda_out = 1'b1;
    @(posedge clk_50us);
end
endtask

task sccb_nack;
begin
    @(posedge clk_50us);
    sda_out = 1'b1;
    scl = 1'b1;
    @(posedge clk_50us);
    scl = 1'b0;
    @(posedge clk_50us);
    sda_out = 1'b0;
    @(posedge clk_50us);
end
endtask

task sccb_write_byte;
input [7:0] data;
output reg success;
begin
    sda_out = data[7]; @(posedge clk_50us); scl = 1'b1; @(posedge clk_50us); scl = 1'b0;
    sda_out = data[6]; @(posedge clk_50us); scl = 1'b1; @(posedge clk_50us); scl = 1'b0;
    sda_out = data[5]; @(posedge clk_50us); scl = 1'b1; @(posedge clk_50us); scl = 1'b0;
    sda_out = data[4]; @(posedge clk_50us); scl = 1'b1; @(posedge clk_50us); scl = 1'b0;
    sda_out = data[3]; @(posedge clk_50us); scl = 1'b1; @(posedge clk_50us); scl = 1'b0;
    sda_out = data[2]; @(posedge clk_50us); scl = 1'b1; @(posedge clk_50us); scl = 1'b0;
    sda_out = data[1]; @(posedge clk_50us); scl = 1'b1; @(posedge clk_50us); scl = 1'b0;
    sda_out = data[0]; @(posedge clk_50us); scl = 1'b1; @(posedge clk_50us); scl = 1'b0;
    en_sda_out = 1'b0;
    @(posedge clk_50us);
    scl = 1'b1;
    @(posedge clk_50us);
    success = sda_in;
    scl = 1'b0;
    en_sda_out = 1'b1;
end
endtask

task sccb_read_byte;
output reg[7:0] data;
begin
    en_sda_out = 1'b0;
    @(posedge clk_50us); scl = 1'b1; data[7] = sda_in; @(posedge clk_50us); scl = 1'b0;
    @(posedge clk_50us); scl = 1'b1; data[6] = sda_in; @(posedge clk_50us); scl = 1'b0;
    @(posedge clk_50us); scl = 1'b1; data[5] = sda_in; @(posedge clk_50us); scl = 1'b0;
    @(posedge clk_50us); scl = 1'b1; data[4] = sda_in; @(posedge clk_50us); scl = 1'b0;
    @(posedge clk_50us); scl = 1'b1; data[3] = sda_in; @(posedge clk_50us); scl = 1'b0;
    @(posedge clk_50us); scl = 1'b1; data[2] = sda_in; @(posedge clk_50us); scl = 1'b0;
    @(posedge clk_50us); scl = 1'b1; data[1] = sda_in; @(posedge clk_50us); scl = 1'b0;
    @(posedge clk_50us); scl = 1'b1; data[0] = sda_in; @(posedge clk_50us); scl = 1'b0;
    en_sda_out = 1'b1;
end
endtask

task sccb_write_reg;
input [7:0] addr;
input [7:0] data;
output reg success;
reg write_byte_success;
begin
    success = 1'b1;
    sccb_start;
    sccb_write_byte(DEVICE_ID, write_byte_success);
    success = success & write_byte_success;
    @(posedge clk_50us); @(posedge clk_50us);
    sccb_write_byte(addr, write_byte_success);
    success = success & write_byte_success;
    @(posedge clk_50us); @(posedge clk_50us);
    sccb_write_byte(data, write_byte_success);
    success = success & write_byte_success;
    sccb_stop;
end
endtask

task sccb_read_reg;
input [7:0] addr;
output reg[7:0] data;
reg write_byte_success;
begin
    sccb_start;
    sccb_write_byte(DEVICE_ID, write_byte_success);
    @(posedge clk_50us); @(posedge clk_50us);
    sccb_write_byte(addr, write_byte_success);
    @(posedge clk_50us); @(posedge clk_50us);
    sccb_stop;
    @(posedge clk_50us); @(posedge clk_50us);
    sccb_start;
    sccb_write_byte(DEVICE_ID | 1'b1, write_byte_success);
    @(posedge clk_50us); @(posedge clk_50us);
    sccb_read_byte(data);
    sccb_nack;
    sccb_stop;
end
endtask
