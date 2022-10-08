`timescale 1ns/1ps
`default_nettype none

function automatic integer max;
    input integer a, b;
    begin
        max = a > b ? a : b;
    end
endfunction

module wb2uart #(
    parameter addr_width = 4,
    parameter data_width = 8,
    parameter strobe_width = addr_width/8,
    parameter clk_per_bit = 217 // 115200 @25MHz
)(
    input                     clock,
    input                     reset,
    input  [addr_width-1:0]   wb_adr,
    input  [data_width-1:0]   wb_datwr,
    output [data_width-1:0]   wb_datrd,
    input                     wb_we,
    input                     wb_stb,
    output                    wb_ack,
    input                     wb_cyc,
    input  [strobe_width-1:0] wb_sel,
    output                    uart_tx,
    input                     uart_rx
);
    parameter IDLE = 0;
    parameter LOAD_TX = 1;
    parameter WAIT_TX = 2;
    parameter WAIT_RX = 3;
    parameter buffer_width = max(addr_width,data_width);
    parameter read_send_bytes = 1 + max(addr_width/8,1);
    parameter write_send_bytes = 1 + max(addr_width/8,1) + max(data_width/8,1) + max(strobe_width/8,1);
    parameter read_receive_bytes = max(data_width/8,1);
    parameter write_receive_bytes = 1;
    reg [1:0] state;
    reg [1:0] next_state;
    reg [buffer_width-1:0] rx_buffer;
    reg [buffer_width-1:0] tx_buffer;
    reg [(write_send_bytes*8)-1:0] wb_buffer;
    reg [7:0] rx_data;
    reg [7:0] tx_data;
    wire rx_data_valid;
    wire receive_done;
    wire tx_data_load;
    wire tx_done;
    reg tx_buffer_load;
    reg tx_buffer_load_uart;
    wire send_done;
    reg [$clog2(write_send_bytes)-1:0] send_bytes;
    reg [$clog2(read_receive_bytes)-1:0] receive_bytes;
    assign wb_ack = (receive_done ? (rx_buffer != 0) : 0) && wb_stb;
    assign wb_datrd = receive_done ? rx_buffer : 0;
    assign tx_buffer_load = state == LOAD_TX;
    assign tx_data_load = tx_buffer_load_uart && !send_done && state != WAIT_RX;
    always @(posedge clock)
        if(reset)
            tx_buffer_load_uart <= 0;
        else if(tx_buffer_load_uart != tx_buffer_load || tx_done)
            tx_buffer_load_uart <= tx_buffer_load || tx_done;
    always @(posedge clock)
        if(wb_stb && wb_cyc) begin
            if(wb_we == 0) begin
                wb_buffer <= {8'd0,8'd0,wb_adr,{7'd0,wb_we}};
                send_bytes <= read_send_bytes;
                receive_bytes <= read_receive_bytes;
            end else begin
                wb_buffer <= {wb_sel,wb_datwr,wb_adr,{7'd0,wb_we}};
                send_bytes <= write_send_bytes;
                receive_bytes <= write_receive_bytes;
            end
        end
    always @(posedge clock)
        if(reset)
            state <= IDLE;
        else
            state <= next_state;
    always @(*) begin
        next_state = IDLE;
        case(state)
            IDLE: begin
                if(wb_stb && wb_cyc)
                    next_state = LOAD_TX;
            end 
            LOAD_TX: begin
                next_state = WAIT_TX;
            end
            WAIT_TX: begin
                next_state = WAIT_TX;
                if(send_done)
                    next_state = WAIT_RX;
            end
            WAIT_RX: begin
                next_state = WAIT_RX;
                if(receive_done)
                    next_state = IDLE;
            end
        endcase
    end
    fifo #(.width(8),.length(buffer_width/8)) rx_fifo(
        .clock(clock),
        .reset(reset),
        .load(rx_data_valid),
        .data_in(rx_data),
        .pardata_in(0),
        .parload(0),
        .max_length(receive_bytes),
        .done(receive_done),
        .data_out(rx_buffer)
    );
    fifo #(.width(8),.length(write_send_bytes)) tx_fifo(
        .clock(clock),
        .reset(reset),
        .load(tx_done),
        .data_in(0),
        .pardata_in(wb_buffer),
        .parload(tx_buffer_load),
        .max_length(send_bytes),
        .done(send_done),
        .data_out(tx_buffer)
    );
    uart_rx rx(
        .clk(clock),
        .rst(reset),
        .clk_per_bit(clk_per_bit),
        .rx(uart_rx),
        .data(rx_data),
        .data_valid(rx_data_valid)
    );
    uart_tx tx(
        .clk(clock),
        .rst(reset),
        .clk_per_bit(clk_per_bit),
        .data(tx_buffer[7:0]),
        .data_load(tx_data_load),
        .tx(uart_tx),
        .tx_done(tx_done)
    );
endmodule

module fifo #(
    parameter width = 8,
    parameter length = 4,
    parameter counter_width = $clog2(length+1),
    parameter out_width = (width*length)
)(
    input clock,
    input reset,
    input load,
    input [width-1:0] data_in,
    input [out_width-1:0] pardata_in,
    input parload,
    input [counter_width-1:0] max_length,
    output done,
    output [out_width-1:0] data_out
);
    reg done;
    reg [out_width-1:0] data_out;
    reg [counter_width-1:0] counter;
    always @(posedge clock)
        if (reset) begin
            data_out <= 0;
            counter <= 0;
        end else if(load) begin
            data_out <= {data_in,data_out[out_width-1:width]};
            counter <= counter + 1;
        end else if(parload) begin
            data_out <= pardata_in;
            counter <= 0;
        end
    always @(*) begin
        done = counter == length;
        if(max_length != 0)
            done = counter == max_length;
    end
endmodule

module uart_rx(
    input clk,
    input rst,
    input [31:0] clk_per_bit,
    input rx,
    output [7:0] data,
    output data_valid
);
    // Control states
    parameter IDLE = 0;
    parameter WAIT = 1;
    parameter EDGE = 2;
    parameter DONE = 3;
    reg [1:0] state;
    reg [1:0] next_state;
    // Counters
    reg  [3:0]  bit_count;
    reg         bit_count_up;
    reg         bit_count_clr;
    wire        bit_count_done;
    reg  [31:0] baud_count;
    reg         baud_count_up;
    reg         baud_count_clr;
    wire        baud_count_done;
    // Datapath
    wire do_sample;
    reg sample_rx;
    reg [9:0] buffer;
    reg [7:0] data;
    reg data_valid;
    reg data_valid_next;
    
    assign bit_count_done = bit_count == 10 - 1;
    assign baud_count_done = baud_count == clk_per_bit - 2;
    assign do_sample = baud_count == (clk_per_bit >> 1) - 1;
    
    always @(posedge clk)
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    always @(*) begin
        next_state = IDLE;
        case(state)
            IDLE: begin
                if(~rx)
                    next_state = WAIT;
            end 
            WAIT: begin
                if(baud_count_done)
                    next_state = EDGE;
                else
                    next_state = WAIT;
            end 
            EDGE: begin
                if(bit_count_done)
                    next_state = DONE;
                else
                    next_state = WAIT;
            end
            DONE: begin
                if(~rx)
                    next_state = WAIT;
                else
                    next_state = IDLE;
            end
        endcase
    end
    always @(*) begin
        bit_count_up = 0;
        bit_count_clr = 0;
        baud_count_up = 0;
        baud_count_clr = 0;
        sample_rx = 0;
        data_valid_next = 0;
        case(state)
            IDLE: begin
            end 
            WAIT: begin
                baud_count_up = 1;
                if(do_sample)
                    sample_rx = 1;
            end 
            EDGE: begin
                bit_count_up = 1;
                baud_count_clr = 1;
            end
            DONE: begin
                if(~rx)
                    baud_count_up = 1;
                data_valid_next = 1;
                bit_count_clr = 1;
            end 
        endcase
    end
    always @(posedge clk)
        if(rst)
            buffer <= 0;
        else if(sample_rx)
            buffer <= {rx, buffer[9:1]};
    always @(posedge clk)
        if(rst) begin
            data <= 0;
        end else if(data_valid_next)
            data <= buffer[8:1];
    always @(posedge clk)
        if(rst)
            data_valid <= 0;
        else
            data_valid <= data_valid_next;
    always @(posedge clk)
        if(rst || baud_count_clr)
            baud_count <= 0;
        else if(baud_count_up)
            baud_count <= baud_count + 1;
    always @(posedge clk)
        if(rst || bit_count_clr)
            bit_count <= 0;
        else if(bit_count_up)
            bit_count <= bit_count + 1;
endmodule

module uart_tx(
    input clk,
    input rst,
    input [31:0] clk_per_bit,
    input [7:0] data,
    input data_load,
    output tx,
    output reg tx_done
);
    parameter IDLE = 0;
    parameter WAIT = 1;
    parameter TRANSMIT = 2;
    reg [2:0] state;
    reg [2:0] next_state;
    reg count_up;
    reg baud_count_up;
    reg baud_count_reset;
    wire count_done;
    wire baud_count_done;
    assign count_done = count == 10;
    assign baud_count_done = baud_count == clk_per_bit - 2;
    assign tx_done = count_done;
    always @(posedge clk)
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    always @(*) begin
        next_state = IDLE;
        case(state)
            IDLE: begin
                if(data_load)
                    next_state = TRANSMIT;
            end 
            TRANSMIT: begin
                next_state = WAIT;
            end
            WAIT: begin
                if(count_done) begin
                    next_state = IDLE;
                end else if(baud_count_done) begin
                    next_state = TRANSMIT;
                end else begin
                    next_state = WAIT;
                end
            end 
        endcase
    end
    always @(*) begin
        count_up = 0;
        baud_count_up = 0;
        baud_count_reset = 0;
        case(state)
            IDLE: begin
            end 
            TRANSMIT: begin
                baud_count_reset = 1;
            end
            WAIT: begin
                baud_count_up = 1;
                if(baud_count_done)
                    count_up = 1;
            end 
        endcase
    end
    reg [9:0] buffer;
    reg [3:0] count;
    reg [31:0] baud_count;
    assign tx = buffer[0];
    always @(posedge clk)
        if(rst)
            buffer <= {10{1'b1}};
        else if(data_load)
            buffer <= {1'b1, data, 1'b0};
        else if(count_up)
            buffer <= {1'b1, buffer[9:1]};
    always @(posedge clk)
        if(rst)
            count <= 0;
        else if(count_up)
            count <= count + 1;
        else if(count_done)
            count <= 0;
    always @(posedge clk)
        if(rst)
            baud_count = 0;
        else if(baud_count_up) begin
            baud_count = baud_count + 1;
        end else if(baud_count_reset) begin
            baud_count = 0;
        end
endmodule

