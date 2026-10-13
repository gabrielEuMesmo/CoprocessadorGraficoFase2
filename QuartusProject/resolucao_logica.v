module resolucao_logica(   input wire clock,    
    input wire reset,     
	 input [7:0]data,			
	 input wren,
	 input [16:0] wraddress,
    output [8:0] next_x_log, 
    output [7:0] next_y_log, 
    output wire hsync,   
    output wire vsync,   
    output [7:0] red,     
    output [7:0] green,  
    output [7:0] blue,    
    output sync,          
    output clk,           
    output blank         
);
reg clock_25;
wire [9:0] next_x, next_y;
wire [7:0] color_in1, color_in2;
reg [1:0] count;

reg [16:0] readVGA;
//
reg VGA;

wire [7:0] color_in = (VGA ? color_in1 :color_in2) ;

wire wren1 = (VGA ? 1'b0 :wren);

wire wren2 = (VGA ? wren:1'b0 );

assign next_x_log = next_x/2;
assign next_y_log = next_y/2;



always @(posedge clock or negedge reset) begin
        if (!reset) begin
            count   <= 2'b00;
            clock_25 <= 1'b0;
				
        end else begin
				
            count   <= count + 1'b1;
            clock_25 <= count[1]; 
        end
    end
always @(*) begin
	readVGA = (next_y_log * 320) + next_x_log;
	
	
end

always @(negedge vsync or negedge reset) begin

	if(!reset)begin
	
		VGA <= 1'b0;
	
	end else begin
	
		if(VGA)begin
			VGA <= 1'b0;
		end else begin
			VGA <= 1'b1;
		end
	end
end
RAMVIDEO(
	clock,
	data,
	readVGA,
	wraddress,
	wren1,
	color_in1
);
	
RAMVIDEO(
	clock,
	data,
	readVGA,
	wraddress,
	wren2,
	color_in2
);




	 
 vga_driver (
    clock_25,     // 25 MHz
    reset,     // Active high
    color_in, // Pixel color data (RRRGGGBB)
    next_x,  // x-coordinate of NEXT pixel that will be drawn
    next_y,  // y-coordinate of NEXT pixel that will be drawn
    hsync,    // HSYNC (to VGA connector)
    vsync,    // VSYNC (to VGA connctor)
    red,     // RED (to resistor DAC VGA connector)
    green,   // GREEN (to resistor DAC to VGA connector)
    blue,    // BLUE (to resistor DAC to VGA connector)
    sync,          // SYNC to VGA connector
    clk,           // CLK to VGA connector
    blank          // BLANK to VGA connector
);
endmodule