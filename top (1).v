module top(clk, rst_n, sensor, led, AN, seg);
    input clk, rst_n;
    input [6:0] sensor;
    output [3:0] led;
    output [3:0] AN;
    output [6:0] seg;
    wire [2:0] score;
    assign AN = 4'b0000;
    Pinball p(clk, rst_n, sensor, score);
    segment s(score, seg);
    LED l(score, led);
endmodule

module segment(in, out);
    input [2:0] in;
    output reg [6:0] out;
    always@(*) begin
        case(in)
            3'b001: out=7'b1001111;
            3'b010: out=7'b0010010;
            3'b011: out=7'b0000110;
            3'b100: out=7'b1001100;
            3'b101: out=7'b0100100;
            default: out=7'b0000001;
        endcase
    end
endmodule

module LED(in, out);
    input [2:0] in;
    output reg [3:0] out;
    always@(*) begin
        case(in)
            3'b001: out=4'b0001;
            3'b010: out=4'b0011;
            3'b011: out=4'b0111;
            3'b100: out=4'b1111;
            default: out=4'b0000;
        endcase
    end
endmodule

module Pinball(clk, rst_n, sensor, score);
    input clk, rst_n;
    input [6:0] sensor;
    output reg [2:0] score;
    parameter PLAY = 2'b00;
    parameter WAIT = 2'b01;
    parameter STOP = 2'b10;
    reg [1:0] state, next_state;
    reg [2:0] next_score;
    reg [1:0] cnt, next_cnt;

    always@(posedge clk) begin
        if(rst_n) begin
            state <= PLAY;
            score <= 3'b000;
            cnt <= 2'b11;
        end
        else begin
            state <= next_state;
            score <= next_score;
            cnt <= next_cnt;
        end
    end

    always@(*) begin
        if(score>=3'b100 || !cnt) begin
            next_state = STOP;
            next_score = score;
            next_cnt = cnt;
        end
        else begin
            case(state)
                PLAY: begin
                    if(sensor[0] || sensor[6]) begin
                        next_state = WAIT;
                        next_cnt = cnt - 1'b1;
                        next_score = score;
                    end
                    else begin
                        if(sensor[1] || sensor[5]) begin
                            next_state = WAIT;
                            next_cnt = cnt - 1'b1;
                            next_score = score+1'b1;
                        end
                        else begin
                            if(sensor[2] || sensor[4]) begin
                                next_state = WAIT;
                                next_cnt = cnt - 1'b1;
                                next_score = score+2'b10;
                            end
                            else begin
                                if(sensor[3]) begin
                                    next_state = WAIT;
                                    next_cnt = cnt - 1'b1;
                                    next_score = 3'b101;
                                end
                                else begin
                                    next_state = PLAY;
                                    next_cnt = cnt;
                                    next_score = score;
                                end
                            end
                        end
                    end
                end
                WAIT: begin
                    if(sensor == 7'b0000000)
                        next_state = PLAY;
                    else
                        next_state = WAIT;
                    next_cnt = 2'b11;
                    next_score = score;
                end
                STOP: begin
                    next_state = STOP;
                    next_score = score;
                    next_cnt = cnt;
                end
            endcase
        end
    end
endmodule