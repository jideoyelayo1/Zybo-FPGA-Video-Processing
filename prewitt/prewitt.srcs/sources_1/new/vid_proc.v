`timescale 1ns / 1ps

module video_processing #
(
    parameter DATA_WIDTH = 24 // 8 bits for R, G & B
)
(
    input  wire                   clk,
    input  wire                   n_rst,

    /*
     * Pixel inputs
     */
    input  wire [DATA_WIDTH-1:0] i_vid_data,
    input  wire                  i_vid_hsync,
    input  wire                  i_vid_vsync,
    input  wire                  i_vid_VDE,

    /*
     * Pixel output
     */
    output reg [DATA_WIDTH-1:0] o_vid_data,
    output reg                  o_vid_hsync,
    output reg                  o_vid_vsync,
    output reg                  o_vid_VDE,
    
    /*
     * Control
     */
    input wire [3:0]            btn,
    input wire [3:0]            sw,
    output reg [3:0]            led
);

localparam HDMI_LENGTH = 1800;
localparam HDMI_DEPTH = 1080;
localparam DATA_SIZE = 8;


wire [7:0] red, blu, gre;
reg  [3:0] sw_On;
reg [15:0] tmpR,tmpB,tmpG;
reg [7:0] gray,out,PrewittX,PrewittY;
reg [3:0] cnt = 0;
reg upBtnOn = 0,downBtnOn = 0;

wire [7:0] PrewittRes;
reg [16:0] PrewittProd;

// line buffer
reg [7:0] lineBuf0 [HDMI_LENGTH-1:0];
reg [7:0] lineBuf1 [HDMI_LENGTH-1:0];
reg [7:0] lineBuf2 [HDMI_LENGTH-1:0];
reg [11:0] XPtr;
reg [1:0] wtPtr;//write pointer
reg [24:0] outMatrix [2:0];

assign {red, blu, gre} = i_vid_data;

// gray stream
always @ (posedge clk) begin 
 gray = (red>>2)+(red>>5)+(red>>6)+(gre>>1)+(gre>>4)+(gre>>5)+(blu>>3);
end

// line buffer reading and writing
always@(posedge clk) begin
    if(i_vid_hsync) XPtr <= 0;
    if(i_vid_vsync) wtPtr <= 0;
    if(XPtr > 0 && XPtr < HDMI_LENGTH-1) begin
        case(wtPtr)
            0:begin
                outMatrix[0] <= {lineBuf0[XPtr-1],lineBuf0[XPtr],lineBuf0[XPtr+1]};
                outMatrix[1] <= {lineBuf1[XPtr-1],lineBuf1[XPtr],lineBuf1[XPtr+1]};
                outMatrix[2] <= {lineBuf2[XPtr-1],lineBuf2[XPtr],lineBuf2[XPtr+1]};
                lineBuf0[XPtr] <= gray;
                wtPtr <= 1;
            end
            1:begin
                outMatrix[0] <= {lineBuf1[XPtr-1],lineBuf1[XPtr],lineBuf1[XPtr+1]};
                outMatrix[1] <= {lineBuf2[XPtr-1],lineBuf2[XPtr],lineBuf2[XPtr+1]};
                outMatrix[2] <= {lineBuf0[XPtr-1],lineBuf0[XPtr],lineBuf0[XPtr+1]};
                lineBuf1[XPtr] <= gray;
                wtPtr <= 2;
            end
            2:begin
                outMatrix[0] <= {lineBuf2[XPtr-1],lineBuf2[XPtr],lineBuf2[XPtr+1]};
                outMatrix[1] <= {lineBuf0[XPtr-1],lineBuf0[XPtr],lineBuf0[XPtr+1]};
                outMatrix[2] <= {lineBuf1[XPtr-1],lineBuf1[XPtr],lineBuf1[XPtr+1]};
                lineBuf2[XPtr] <= gray;
                wtPtr <= 0;
            end
        endcase
    end
    if(XPtr < HDMI_LENGTH) XPtr <= XPtr + 1;
end




always @ (*) begin
    led <= cnt; // displays mode in LEDs 0 to 15  
end

//Navigation
always @(posedge clk) begin

    if(btn[0] && !upBtnOn) begin 
        cnt <= cnt + 1;upBtnOn <= 1; 
    end
    else if (!btn[0] && upBtnOn) begin 
        upBtnOn <= 0; 
    end
    
    if(btn[1] && !downBtnOn) begin 
        cnt <= cnt - 1; downBtnOn <= 1; 
    end else if (!btn[1] && downBtnOn) begin 
        downBtnOn <= 0; 
    end 
    
    if(btn[2]) begin
        cnt <= 0;upBtnOn <= 0;downBtnOn <= 0;
    end
    
    if(btn[3]) begin
        cnt <= 8;
    end
end


always @ (posedge clk) begin    
    
    if(!n_rst) begin
        o_vid_hsync <= 0;
        o_vid_vsync <= 0; 
        o_vid_VDE <= 0;
        o_vid_data <= 0;
    end
    else begin
        o_vid_hsync <= i_vid_hsync;
        o_vid_vsync <= i_vid_vsync; 
        o_vid_VDE <= i_vid_VDE;
        
        
        if(sw[3])begin out <= gray;end      
        else if(XPtr >= HDMI_LENGTH) out <= 8'b11111111;
        else if(cnt == 0) begin // Edge Detection - Prewitt Filter Y
            out <= (outMatrix[0][23:16]*-1 + outMatrix[0][15:8]*-1 + outMatrix[0][7:0]*-1 +
                    outMatrix[1][23:16]* 0 + outMatrix[1][15:8]* 0 + outMatrix[1][7:0]* 0 +
                    outMatrix[2][23:16]* 1 + outMatrix[2][15:8]* 1 + outMatrix[2][7:0]* 1) ;end
        else if(cnt == 1) begin // Edge Detection - Prewitt Filter X
            out <= (outMatrix[0][23:16]*-1 + outMatrix[0][15:8]* 0 + outMatrix[0][7:0]* 1 +
                    outMatrix[1][23:16]*-1 + outMatrix[1][15:8]* 0 + outMatrix[1][7:0]* 1 +
                    outMatrix[2][23:16]*-1 + outMatrix[2][15:8]* 0 + outMatrix[2][7:0]* 1) ;end
        else if(cnt == 2) begin // Edge Detection - Prewitt Filter X
            PrewittY <= (outMatrix[0][23:16]*-1 + outMatrix[0][15:8]*-1 + outMatrix[0][7:0]*-1 +
                    outMatrix[1][23:16]* 0 + outMatrix[1][15:8]* 0 + outMatrix[1][7:0]* 0 +
                    outMatrix[2][23:16]* 1 + outMatrix[2][15:8]* 1 + outMatrix[2][7:0]* 1) ;
            PrewittX <= (outMatrix[0][23:16]*-1 + outMatrix[0][15:8]* 0 + outMatrix[0][7:0]* 1 +
                    outMatrix[1][23:16]*-1 + outMatrix[1][15:8]* 0 + outMatrix[1][7:0]* 1 +
                    outMatrix[2][23:16]*-1 + outMatrix[2][15:8]* 0 + outMatrix[2][7:0]* 1) ;
            
            PrewittProd <= PrewittX*PrewittX + PrewittY*PrewittY;
            out <= PrewittRes;
        end
        else begin out <= 8'b11111111; end
        
        
       o_vid_data <= {out, out, out};
        
        
    end
end

sqrt_fn (
    .x(PrewittProd),
    .y(PrewittRes)
);

endmodule