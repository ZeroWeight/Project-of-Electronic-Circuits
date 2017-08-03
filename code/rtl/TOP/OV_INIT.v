`timescale 1us / 1us

module OV_INIT #(
    parameter [7:0] DEVICE_ID = 8'h42
)(
    input clk_100kHz,
    input rst_n,
    output reg scl = 1'b1,
    inout sda,
    output reg initialized = 1'b0,
    output reg new_data = 1'b0,
    output reg[7:0] data
);
    wire sda_in = sda;
    reg sda_out = 1'b1;
    reg sda_oe = 1'b1;
    assign sda = sda_oe ? sda_out : 1'bZ;
    pullup(sda);
    
    localparam [7:0] conf_cnt = 8'd210;
    localparam [7:0] conf[0:conf_cnt-1] = {
        8'h11, 8'h80, 8'h92, 8'h7F, 8'h93, 8'h00, 8'h9D, 8'h9E, 8'h3B, 8'h0A, 8'h13, 8'hF2, 8'h10, 8'h00,
        8'h00, 8'h00, 8'h01, 8'h80, 8'h02, 8'h80, 8'h13, 8'hD7, 8'h12, 8'h14, 8'h04, 8'h00, 8'h18, 8'h4B,
        8'h17, 8'h23, 8'h32, 8'hBF, 8'h19, 8'h02, 8'h1A, 8'h7A, 8'h03, 8'h00, 8'h0E, 8'h84, 8'h0F, 8'h62,
        8'h15, 8'h02, 8'h16, 8'h02, 8'h1B, 8'h01, 8'h1E, 8'h01, 8'h29, 8'h3C, 8'h33, 8'h00, 8'h34, 8'h07,
        8'h35, 8'h84, 8'h36, 8'h00, 8'h38, 8'h13, 8'h39, 8'h43, 8'h3A, 8'h00, 8'h3C, 8'h6C, 8'h3D, 8'h90,
        8'h3F, 8'h29, 8'h40, 8'hD1, 8'h41, 8'h20, 8'h6B, 8'h0A, 8'hA1, 8'hC8, 8'h69, 8'h80, 8'h43, 8'hF0,
        8'h44, 8'h10, 8'h45, 8'h78, 8'h46, 8'hA8, 8'h47, 8'h60, 8'h48, 8'h80, 8'h59, 8'hBA, 8'h5A, 8'h9A,
        8'h5B, 8'h22, 8'h5C, 8'hB9, 8'h5D, 8'h9B, 8'h5E, 8'h10, 8'h5F, 8'hE0, 8'h60, 8'h85, 8'h61, 8'h60,
        8'h9F, 8'h9D, 8'hA0, 8'hA0, 8'h4F, 8'hAE, 8'h50, 8'h26, 8'h51, 8'h08, 8'h52, 8'h1A, 8'h53, 8'hA9,
        8'h54, 8'h0F, 8'h55, 8'h05, 8'h56, 8'h46, 8'h57, 8'hCB, 8'h58, 8'h77, 8'h8B, 8'hCC, 8'h8C, 8'hCC,
        8'h8D, 8'hCF, 8'h6C, 8'h40, 8'h6D, 8'h30, 8'h6E, 8'h4B, 8'h6F, 8'h60, 8'h70, 8'h70, 8'h71, 8'h70,
        8'h72, 8'h70, 8'h73, 8'h70, 8'h74, 8'h60, 8'h75, 8'h60, 8'h76, 8'h50, 8'h77, 8'h48, 8'h78, 8'h3A,
        8'h79, 8'h2E, 8'h7A, 8'h28, 8'h7B, 8'h22, 8'h7C, 8'h04, 8'h7D, 8'h07, 8'h7E, 8'h10, 8'h7F, 8'h28,
        8'h80, 8'h36, 8'h81, 8'h44, 8'h82, 8'h52, 8'h83, 8'h60, 8'h84, 8'h6C, 8'h85, 8'h78, 8'h86, 8'h8C,
        8'h87, 8'h9E, 8'h88, 8'hBB, 8'h89, 8'hD2, 8'h8A, 8'hE6, 8'h14, 8'h2E, 8'h24, 8'hB8, 8'h25, 8'hA8
    };
    
    localparam [8:0] cnt_50us = 9'd50_0;
    localparam [9:0] cnt_100us = 10'd100_0;
    localparam [14:0] cnt_2ms = 15'd2_000_0;
    localparam [18:0] cnt_50ms = 19'd50_000_0;
    reg[18:0] delay_cnt = 1'd0;
    reg[2:0] bit_cnt = 1'd0;
    reg[7:0] reg_data = 8'h00;
    reg[7:0] idx = 1'd0;
    reg[7:0] state = 8'h00; // state machine
    always @(posedge clk_100kHz or negedge rst_n)
        if (!rst_n) begin
            scl <= 1'b1; sda_out <= 1'b1; sda_oe <= 1'b1;
//            initialized <= 1'b0;
            delay_cnt <= 1'd0; state <= 8'h00;
        end else if (delay_cnt) delay_cnt <= delay_cnt - 1'd1;
        else if (!initialized)
        case (state)
        // write_reg(0x12, 0x80)
        // start
        8'h00: begin sda_out <= 1'b1; state <= 8'h01; end
        8'h01: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h02; end
        8'h02: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h03; end
        8'h03: begin scl <= 1'b0; state <= 8'h04; end
        // write_byte(DEVICE_ID)
        8'h04: begin bit_cnt <= 3'd7; reg_data <= DEVICE_ID; state <= 8'h05; end
        8'h05: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h06; end
        8'h06: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h07; end
        8'h07: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h05 : 8'h08; end
        8'h08: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h09; end
        8'h09: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h0A; end
        8'h0A: begin new_data <= 1'b1; data <= sda_in; state <= 8'h0B; end // TX: 00 - success
        8'h0B: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h0C; end
        // write_byte(0x12)
        8'h0C: begin bit_cnt <= 3'd7; reg_data <= 8'h12; state <= 8'h0D; end
        8'h0D: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h0E; end
        8'h0E: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h0F; end
        8'h0F: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h0D : 8'h10; end
        8'h10: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h11; end
        8'h11: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h12; end
        8'h12: begin new_data <= 1'b1; data <= sda_in; state <= 8'h13; end // TX: 00 - success
        8'h13: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h14; end
        // write_byte(0x80)
        8'h14: begin bit_cnt <= 3'd7; reg_data <= 8'h80; state <= 8'h15; end
        8'h15: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h16; end
        8'h16: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h17; end
        8'h17: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h15 : 8'h18; end
        8'h18: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h19; end
        8'h19: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h1A; end
        8'h1A: begin new_data <= 1'b1; data <= sda_in; state <= 8'h1B; end // TX: 00 - success
        8'h1B: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; state <= 8'h1C; end
        // stop
        8'h1C: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h1D; end
        8'h1D: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h1E; end
        8'h1E: begin sda_out <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h1F; end
        
        // delay 50ms
        8'h1F: begin delay_cnt <= cnt_50ms; state <= 8'h20; end
        
        // read_reg(0x0B)
        // start
        8'h20: begin sda_out <= 1'b1; state <= 8'h21; end
        8'h21: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h22; end
        8'h22: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h23; end
        8'h23: begin scl <= 1'b0; state <= 8'h24; end
        // write_byte(DEVICE_ID)
        8'h24: begin bit_cnt <= 3'd7; reg_data <= DEVICE_ID; state <= 8'h25; end
        8'h25: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h26; end
        8'h26: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h27; end
        8'h27: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h25 : 8'h28; end
        8'h28: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h29; end
        8'h29: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h2A; end
        8'h2A: begin new_data <= 1'b1; data <= sda_in; state <= 8'h2B; end // TX: 00 - success
        8'h2B: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h2C; end
        // write_byte(0x0B)
        8'h2C: begin bit_cnt <= 3'd7; reg_data <= 8'h0B; state <= 8'h2D; end
        8'h2D: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h2E; end
        8'h2E: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h2F; end
        8'h2F: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h2D : 8'h30; end
        8'h30: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h31; end
        8'h31: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h32; end
        8'h32: begin new_data <= 1'b1; data <= sda_in; state <= 8'h33; end // TX: 00 - success
        8'h33: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h34; end
        // stop
        8'h34: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h35; end
        8'h35: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h36; end
        8'h36: begin sda_out <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h37; end
        8'h37: begin delay_cnt <= cnt_100us; state <= 8'h38; end
        // start
        8'h38: begin sda_out <= 1'b1; state <= 8'h39; end
        8'h39: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h3A; end
        8'h3A: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h3B; end
        8'h3B: begin scl <= 1'b0; state <= 8'h3C; end
        // write_byte(DEVICE_ID | 0x01)
        8'h3C: begin bit_cnt <= 3'd7; reg_data <= DEVICE_ID | 1'b1; state <= 8'h3D; end
        8'h3D: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h3E; end
        8'h3E: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h3F; end
        8'h3F: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h3D : 8'h40; end
        8'h40: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h41; end
        8'h41: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h42; end
        8'h42: begin new_data <= 1'b1; data <= sda_in; state <= 8'h43; end // TX: 00 - success
        8'h43: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h44; end
        // read_byte
        8'h44: begin sda_oe <= 1'b0; bit_cnt <= 3'd7; delay_cnt <= cnt_50us; state <= 8'h45; end
        8'h45: begin scl <= 1'b1; data[bit_cnt] <= sda_in; delay_cnt <= cnt_50us; state <= 8'h46; end
        8'h46: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h47 : 8'h48; end
        8'h47: begin delay_cnt <= cnt_50us; state <= 8'h45; end
        8'h48: begin sda_oe <= 1'b1; state <= 8'h49; end
        8'h49: begin new_data <= 1'b1; state <= 8'h4A; end // TX: 73 - success
        8'h4A: begin new_data <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h4B; end
        // nack
        8'h4B: begin sda_out <= 1'b1; state <= 8'h4C; end
        8'h4C: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h4D; end
        8'h4D: begin scl <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h4E; end
        8'h4E: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h4F; end
        // stop
        8'h4F: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h51; end
        8'h51: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h52; end
        8'h52: begin sda_out <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h53; end
        8'h53: begin delay_cnt <= cnt_100us; state <= 8'h54; end
        
        // read_reg(0x0A)
        // start
        8'h54: begin sda_out <= 1'b1; state <= 8'h55; end
        8'h55: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h56; end
        8'h56: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h57; end
        8'h57: begin scl <= 1'b0; state <= 8'h58; end
        // write_byte(DEVICE_ID)
        8'h58: begin bit_cnt <= 3'd7; reg_data <= DEVICE_ID; state <= 8'h59; end
        8'h59: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h5A; end
        8'h5A: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h5B; end
        8'h5B: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h59 : 8'h5C; end
        8'h5C: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h5D; end
        8'h5D: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h5E; end
        8'h5E: begin new_data <= 1'b1; data <= sda_in; state <= 8'h5F; end // TX: 00 - success
        8'h5F: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h60; end
        // write_byte(0x0A)
        8'h60: begin bit_cnt <= 3'd7; reg_data <= 8'h0A; state <= 8'h61; end
        8'h61: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h62; end
        8'h62: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h63; end
        8'h63: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h61 : 8'h64; end
        8'h64: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h65; end
        8'h65: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h66; end
        8'h66: begin new_data <= 1'b1; data <= sda_in; state <= 8'h67; end // TX: 00 - success
        8'h67: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h68; end
        // stop
        8'h68: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h69; end
        8'h69: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h6A; end
        8'h6A: begin sda_out <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h6B; end
        8'h6B: begin delay_cnt <= cnt_100us; state <= 8'h6C; end
        // start
        8'h6C: begin sda_out <= 1'b1; state <= 8'h6D; end
        8'h6D: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h6E; end
        8'h6E: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h6F; end
        8'h6F: begin scl <= 1'b0; state <= 8'h70; end
        // write_byte(DEVICE_ID | 0x01)
        8'h70: begin bit_cnt <= 3'd7; reg_data <= DEVICE_ID | 1'b1; state <= 8'h71; end
        8'h71: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h72; end
        8'h72: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h73; end
        8'h73: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h71 : 8'h74; end
        8'h74: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h75; end
        8'h75: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h76; end
        8'h76: begin new_data <= 1'b1; data <= sda_in; state <= 8'h77; end // TX: 00 - success
        8'h77: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h78; end
        // read_byte
        8'h78: begin sda_oe <= 1'b0; bit_cnt <= 3'd7; delay_cnt <= cnt_50us; state <= 8'h79; end
        8'h79: begin scl <= 1'b1; data[bit_cnt] <= sda_in; delay_cnt <= cnt_50us; state <= 8'h7A; end
        8'h7A: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h7B : 8'h7C; end
        8'h7B: begin delay_cnt <= cnt_50us; state <= 8'h79; end
        8'h7C: begin sda_oe <= 1'b1; state <= 8'h7D; end
        8'h7D: begin new_data <= 1'b1; state <= 8'h7E; end // TX: 76 - success
        8'h7E: begin new_data <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h7F; end
        // nack
        8'h7F: begin sda_out <= 1'b1; state <= 8'h80; end
        8'h80: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h81; end
        8'h81: begin scl <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h82; end
        8'h82: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h83; end
        // stop
        8'h83: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h84; end
        8'h84: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h85; end
        8'h85: begin sda_out <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h86; end
        8'h86: begin delay_cnt <= cnt_100us; state <= 8'h87; end
        
        // write config
        // start
        8'h87: begin sda_out <= 1'b1; state <= 8'h88; end
        8'h88: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h89; end
        8'h89: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h8A; end
        8'h8A: begin scl <= 1'b0; state <= 8'h8B; end
        // write_byte(DEVICE_ID)
        8'h8B: begin bit_cnt <= 3'd7; reg_data <= DEVICE_ID; state <= 8'h8C; end
        8'h8C: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h8D; end
        8'h8D: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h8E; end
        8'h8E: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h8C : 8'h8F; end
        8'h8F: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h90; end
        8'h90: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h91; end
        8'h91: begin new_data <= 1'b1; data <= sda_in; state <= 8'h92; end // TX: 00 - success
        8'h92: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h93; end
        // write_byte(conf[idx++])
        8'h93: begin bit_cnt <= 3'd7; reg_data <= conf[idx]; idx <= idx + 1'd1; state <= 8'h94; end
        8'h94: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h95; end
        8'h95: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h96; end
        8'h96: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h94 : 8'h97; end
        8'h97: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'h98; end
        8'h98: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h99; end
        8'h99: begin new_data <= 1'b1; data <= sda_in; state <= 8'h9A; end // TX: 00 - success
        8'h9A: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; delay_cnt <= cnt_100us; state <= 8'h9B; end
        // write_byte(conf[idx++])
        8'h9B: begin bit_cnt <= 3'd7; reg_data <= conf[idx]; idx <= idx + 1'd1; state <= 8'h9C; end
        8'h9C: begin sda_out <= reg_data[bit_cnt]; delay_cnt <= cnt_50us; state <= 8'h9D; end
        8'h9D: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'h9E; end
        8'h9E: begin scl <= 1'b0; bit_cnt <= bit_cnt - 1'd1; state <= bit_cnt ? 8'h9C : 8'h9F; end
        8'h9F: begin sda_oe <= 1'b0; delay_cnt <= cnt_50us; state <= 8'hA0; end
        8'hA0: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'hA1; end
        8'hA1: begin new_data <= 1'b1; data <= sda_in; state <= 8'hA2; end // TX: 00 - success
        8'hA2: begin new_data <= 1'b0; scl <= 1'b0; sda_oe <= 1'b1; state <= 8'hA3; end
        // stop
        8'hA3: begin sda_out <= 1'b0; delay_cnt <= cnt_50us; state <= 8'hA4; end
        8'hA4: begin scl <= 1'b1; delay_cnt <= cnt_50us; state <= 8'hA5; end
        8'hA5: begin sda_out <= 1'b1; delay_cnt <= cnt_50us; state <= 8'hA6; end
        8'hA6: begin delay_cnt <= cnt_2ms; state <= idx == conf_cnt ? 8'hA7 : 8'h87; end
        
        // finish
        8'hA7: begin new_data <= 1'b1; data <= 8'h0D; state <= 8'hA8; end // TX: 0D
        8'hA8: begin new_data <= 1'b0; delay_cnt <= cnt_50us; state <= 8'hA9; end
        8'hA9: begin new_data <= 1'b1; data <= 8'h0A; state <= 8'hAA; end // TX: 0A
        8'hAA: begin new_data <= 1'b0; initialized <= 1'b1; end
        
        default: state <= 8'h00;
        endcase
endmodule
