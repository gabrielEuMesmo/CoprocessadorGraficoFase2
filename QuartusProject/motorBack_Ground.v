module motorBack_Ground(
	input reset,
	input enable,
	input clk,
	input [1:0] Roll,
	input WRoll,
	input [5:0] x_tile,
	input [4:0] y_tile,
	input write,
	input [7:0] color, 
	output [7:0] colorOut,
	output [16:0] address,
	output done
);
	
	
	wire [8:0] next_x;
	wire [7:0] next_y;
	
	reg [5:0] offset_x, offset_y;
	
	reg [7:0] tileMap [0:1199];
	
	
	
	integer i;
	
	wire [11:0] enderecoTile;
	
	wire [5:0] tile_x = next_x[8:3]; // next_x / 8
   wire [4:0] tile_y = next_y[7:3];// next_y / 8
	wire [5:0] calc_x = (tile_x + offset_x >39)? (tile_x + offset_x) - 40 : (tile_x + offset_x);
	wire [5:0] calc_y = (tile_y + offset_y >29)? (tile_y + offset_y) - 30 : (tile_y + offset_y);
	wire [5:0] calc_x_w = (x_tile + offset_x >39)? (x_tile + offset_x) - 40 : (x_tile + offset_x);
	wire [5:0] calc_y_w = (y_tile + offset_y >29)? (y_tile + offset_y) - 30 : (y_tile + offset_y);
	
   assign enderecoTile = (calc_y * 6'd40) + calc_x; 
   assign colorOut = tileMap[enderecoTile];
    
    // 2. Inferência correta de Memória BRAM (Sem Reset Assíncrono!)
   always @(posedge clk or negedge reset) begin 
			if(!reset)begin
				for(i=0; i<1200; i = i +1)begin
					tileMap[i] <= 0;
				end
			end else begin
			
				  if (write) begin
						// Como x_tile e y_tile já vêm de fora (0 a 39 e 0 a 29), a fórmula é direta
						tileMap[(calc_y_w * 40) + calc_x_w] <= color;
				  end
				  if(WRoll)begin
						case(Roll)
							2'b00:begin
										if(offset_x != 39)begin
											offset_x <= offset_x +1;
										end else begin
											offset_x <= 0;
										end
									end
							2'b01:begin
										if(offset_x != 0)begin
											offset_x <= offset_x -1;
										end else begin
											offset_x <= 39;
										end
									end
							2'b10:begin
										if(offset_y != 29)begin
											offset_y <= offset_y +1;
										end else begin
											offset_y <= 0;
										end
									end
							2'b11:begin
										if(offset_y != 0)begin
											offset_y <= offset_y -1;
										end else begin
											offset_y <= 29;
										end
									end
									
				  endcase
				 end
				
			end
    end
	 
	 
	
	contadorVid(
			.reset(reset),
			.clk(clk),
			.enable(enable),
			.x(next_x),
			.y(next_y),
			.address(address),
			.done(done)
		);
	
	
endmodule
	
	