`timescale 1us / 1us

module TOP (
    input sys_clk,
    input rst_n,
    output servo_pwm,
    output [1:0] motor_en,
    output motor_pwm,
    output trig,
    input echo,
    input rx_pin,
    output tx_pin,
    output scl, // sccb clock
    inout sda, // sccb data
    output wen, // fifo write enable
    output wrst, // fifo write reset
    input vsync, // frame alignment
    input [7:0] fifo_data, // fifo data
    output rclk, // fifo read clock
    output rrst, // fifo read reset
    output [15:0] led,
    output [3:0] AN,
    output [0:7] Y
);
    /*-------------------------------------------------
     |                     Clocks                     |
     -------------------------------------------------*/
    parameter SYS_CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 921600;
    
    wire clk_uart, clk_100kHz, clk_1MHz, clk_24MHz, clk_250Hz, clk_2Hz;
    CLK_GEN #(SYS_CLK_FREQ, BAUD_RATE) clk_gen_uart(sys_clk, rst_n, clk_uart);
    CLK_GEN #(SYS_CLK_FREQ, 100_000) clk_gen_100kHz(sys_clk, rst_n, clk_100kHz);
    CLK_GEN #(SYS_CLK_FREQ, 1_000_000) clk_gen_1MHz(sys_clk, rst_n, clk_1MHz);
    CLK_GEN #(SYS_CLK_FREQ, 24_000_000) clk_gen_24MHz(sys_clk, rst_n, clk_24MHz);
    CLK_GEN #(SYS_CLK_FREQ, 250) clk_gen_250Hz(sys_clk, rst_n, clk_250Hz);
    CLK_GEN #(SYS_CLK_FREQ, 2) clk_gen_2Hz(sys_clk, rst_n, clk_2Hz);
    
    /*-------------------------------------------------
     |                     Servo                      |
     -------------------------------------------------*/
    localparam [7:0] min_angle = 8'd150;
    localparam [7:0] max_angle = 8'd250;
    localparam [7:0] default_angle = 8'd200;
    reg[7:0] angle = default_angle;
    SERVO servo(clk_100kHz, rst_n, angle, servo_pwm);
    
    /*-------------------------------------------------
     |                     Motor                      |
     -------------------------------------------------*/
    reg[1:0] direction = 2'b01;
    MOTOR motor(clk_1MHz, rst_n, direction, motor_en, motor_pwm);
    
    /*-------------------------------------------------
     |                   ULTRASONIC                   |
     -------------------------------------------------*/
    reg[11:0] distance = 12'd0;
    ULTRASONIC ultrasonic(clk_1MHz, rst_n, trig, echo, distance);
    
    /*-------------------------------------------------
     |                      UART                      |
     -------------------------------------------------*/
    wire rx_error;
    wire rx_finish;
    wire[7:0] rx_data;
    UART_RX rx(clk_uart, rst_n, rx_pin, rx_error, rx_finish, rx_data);
    
    reg tx_start = 1'b0;
    wire tx_finish;
    reg[7:0] tx_data = 8'h00;
    UART_TX tx(clk_uart, rst_n, tx_pin, tx_start, tx_finish, tx_data);
    
    /*-------------------------------------------------
     |                     Camera                     |
     -------------------------------------------------*/
    parameter [7:0] DEVICE_ID = 8'h42;
    
    wire initialized;
    wire new_init_data;
    wire[7:0] init_data;
    OV_INIT #(DEVICE_ID) init(clk_100kHz, rst_n, scl, sda, initialized, new_init_data, init_data);
        
    wire new_frame;
    wire frame_read;
    wire new_frame_data;
    wire[7:0] frame_data;
    OV_STORE ov_s(clk_24MHz, rst_n, initialized, wen, wrst, vsync, new_frame, frame_read);
    OV_READ ov_r(clk_24MHz, rst_n, initialized, fifo_data, rclk, rrst, new_frame, frame_read, new_frame_data, frame_data);
    
    /*-------------------------------------------------
     |                   Top - RX                     |
     -------------------------------------------------*/
    reg[0:2] rx_finish_reg = {3{1'b0}};
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) rx_finish_reg <= {3{1'b0}};
        else rx_finish_reg <= {rx_finish, rx_finish_reg[0:1]};
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) angle <= default_angle;
        // else if (rx_error) direction <= 2'b01;
        else if (rx_finish_reg[1] & ~rx_finish_reg[2]) // posedge
        if ((rx_data & 8'h03) == 8'h00) begin
            case (rx_data[7:5]) // motor
            3'b011: direction <= 2'b11; // forward
            3'b110: direction <= 2'b00; // backward
            default: direction <= 2'b01; // halt
            endcase
            case (rx_data[4:2]) // servo
            3'b011: if (angle < max_angle) angle <= angle + 1'd1; // turn left
            3'b110: if (angle > min_angle) angle <= angle - 1'd1; // turn right
            3'b101: angle <= default_angle; // straight
            default: ;
            endcase
        end
         
    /*-------------------------------------------------
     |                   Top - TX                     |
     -------------------------------------------------*/
    reg[0:2] new_init_data_reg = {3{1'b0}};
    reg[0:2] new_frame_data_reg = {3{1'b0}};
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) begin new_init_data_reg = {3{1'b0}}; new_frame_data_reg = {3{1'b0}}; end
        else if (!initialized) new_init_data_reg = {new_init_data, new_init_data_reg[0:1]};
        else new_frame_data_reg = {new_frame_data, new_frame_data_reg[0:1]};
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) tx_start <= 1'b0;
        else if (tx_start) begin if (!tx_finish) tx_start <= 1'b0; end
        else if (!initialized) begin tx_start <= new_init_data_reg[1] & ~new_init_data_reg[2]; tx_data <= init_data; end
        else begin tx_start <= new_frame_data_reg[1] & ~new_frame_data_reg[2]; tx_data <= frame_data; end
        
    /*-------------------------------------------------
     |                  Debug LEDs                    |
     -------------------------------------------------*/
    assign led[0] = initialized;
    assign led[15:6] = {
        distance < 12'd1000,
        distance < 12'd900,
        distance < 12'd800,
        distance < 12'd700,
        distance < 12'd600,
        distance < 12'd500,
        distance < 12'd400,
        distance < 12'd300,
        distance < 12'd200,
        distance < 12'd100
    };
    
    /*-------------------------------------------------
     |                   Nixietube                    |
     -------------------------------------------------*/
    reg[31:0] display_data;
    DISPLAY display(clk_250Hz, rst_n, display_data, AN, Y);
    always @(posedge clk_2Hz or negedge rst_n)
        if (!rst_n) display_data <= 32'hFFFFFFFF;
        else case (display_data)
        32'h9161E3E3: display_data <= 32'h61E3E303;
        32'h61E3E303: display_data <= 32'hE3E303FF;
        32'hE3E303FF: display_data <= 32'hE303FF91;
        32'hE303FF91: display_data <= 32'h03FF9161;
        32'h03FF9161: display_data <= 32'hFF9161E3;
        default: display_data <= 32'h9161E3E3;
        endcase
endmodule
