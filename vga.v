`timescale 1ns/1ps

module VGA(
   input clk,
   input rst,
   input[2:0]score,
   output [3:0] vgaRed,
   output [3:0] vgaGreen,
   output [3:0] vgaBlue,
   output hsync,
   output vsync
    );

    wire [11:0] data;
    wire clk_25MHz;
    wire clk_22;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480

  assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel:12'h0;

     clock_divisor clk_wiz_0_inst(
      .clk(clk),
      .clk1(clk_25MHz),
      .clk22(clk_22)
    );

    mem_addr_gen mem_addr_gen_inst(
    .clk(clk_22),
    .rst(rst),
    .score(score),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt),
    .pixel_addr(pixel_addr)
    );
     
 
    blk_mem_gen_0 blk_mem_gen_0_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(pixel_addr),
      .dina(data[11:0]),
      .douta(pixel)
    ); 

    vga_controller   vga_inst(
      .pclk(clk_25MHz),
      .rst_n(rst),
      .hsync(hsync),
      .vsync(vsync),
      .valid(valid),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt)
    );
      
endmodule

module vga_controller 
  (
    input wire pclk,rst_n,
    output wire hsync,vsync,valid,
    output wire [9:0]h_cnt,
    output wire [9:0]v_cnt
    );
    
    reg [9:0]pixel_cnt, next_pixel;
    reg [9:0]line_cnt, next_line;
    reg hsync_i,vsync_i, next_hsync, next_vsync;
    wire hsync_default, vsync_default;
    wire [9:0] HD, HF, HS, HB, HT, VD, VF, VS, VB, VT, FH1, FV1;

    assign FH1 = 213;
    assign FV1 = 240;
   
    assign HD = 640;
    assign HF = 16;
    assign HS = 96;
    assign HB = 48;
    assign HT = 800; 
    assign VD = 480;
    assign VF = 10;
    assign VS = 2;
    assign VB = 33;
    assign VT = 525;
    assign hsync_default = 1'b1;
    assign vsync_default = 1'b1;

    always@(posedge pclk)begin
        if(rst_n)begin
            pixel_cnt <= 0;
            line_cnt <= 0;
            hsync_i <= hsync_default;
            vsync_i <= vsync_default;
        end
        else begin
            pixel_cnt <= next_pixel;
            line_cnt <= next_line;
            hsync_i <= next_hsync;
            vsync_i <= next_vsync;
        end
    end
   
    always@(*)begin
        next_pixel = pixel_cnt;
        next_line = line_cnt;
        next_hsync = hsync_i;
        next_vsync = vsync_i;
        if(pixel_cnt < (HT -1)) next_pixel = pixel_cnt + 1'b1;
        else next_pixel = 0;
        if(pixel_cnt == (HT-1))begin
            if(line_cnt < (VT - 1)) next_line = line_cnt + 1'b1;
            else next_line = 0; 
        end
        else next_line = line_cnt;
        if((pixel_cnt >= (HD + HF - 1)) && (pixel_cnt < (HD + HF + HS - 1))) next_hsync = ~hsync_default;
        else next_hsync = hsync_default;
        if((line_cnt >= (VD + VF - 1))&&(line_cnt < (VD + VF + VS - 1))) next_vsync = ~vsync_default;
        else next_vsync = vsync_default;        
    end

    assign h_cnt = (pixel_cnt < HD) ? pixel_cnt:10'd0;
    assign v_cnt = (line_cnt < VD) ? line_cnt:10'd0;
    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD ) && (line_cnt < VD));
           
endmodule

module mem_addr_gen(
   input clk,
   input rst,
   input [9:0] h_cnt,
   input [2:0] score,
   input [9:0] v_cnt,
   output [16:0] pixel_addr
   );
   
   wire [9:0] H1, H2, H3, V1, V2;
   reg[9:0] new_h, new_v;
   
   assign H1 = 0;
   assign H2 = 213;
   assign H3 = 426;
   assign V1 = 0;
   assign V2 = 240;
    
   always@(*)begin
        case(score)
        3'd0:begin
            new_h = H1 + h_cnt/3;
            new_v = V1 + v_cnt/2;
        end    
        3'd1:begin
            new_h = H2 + h_cnt/3;
            new_v = V1 + v_cnt/2;
        end
        3'd2:begin
            new_h = H3 + h_cnt/3;
            new_v = V1 + v_cnt/2;
        end
        3'd3:begin
            new_h = H1 + h_cnt/3;
            new_v = V2 + v_cnt/2;
        end
        3'd4:begin
            new_h = H2 + h_cnt/3;
            new_v = V2 + v_cnt/2;
        end
        3'd5:begin
            new_h = H3 + h_cnt/3;
            new_v = V2 + v_cnt/2;
        end
        default:begin
            new_h = H1 + h_cnt/3;
            new_v = V1 + v_cnt/2;
        end
        endcase
   end
    
    assign pixel_addr = ((new_h >>1)+320*(new_v >>1))% 76800;  //640*480 --> 320*240 
endmodule

module clock_divisor(clk1, clk, clk22);
input clk;
output clk1;
output clk22;
reg [21:0] num;
wire [21:0] next_num;

always @(posedge clk) begin
  num <= next_num;
end

assign next_num = num + 1'b1;
assign clk1 = num[1];
assign clk22 = num[21];
endmodule
