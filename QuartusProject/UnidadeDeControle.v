module UnidadeDeControle(
	input [31:0] instrucao,
	input  wire        clk,
	input  wire        ativa,
	input  wire        rst,

   // ================= Saídas para Background =================
   output reg [1:0]  bg_Roll,
   output reg        bg_WRoll,
   output reg [5:0]  bg_x_tile,
   output reg [4:0]  bg_y_tile,
   output reg        bg_salva_info,
   output reg [7:0]  bg_color,

   // ============= Saídas para Polígonos =================
   output reg [1:0]  pol_Address,
   output reg [1:0]  pol_cordenada,
   output reg [8:0]  pol_x,
   output reg [7:0]  pol_y,
   output reg [7:0]  pol_cor,
   output reg        pol_visivel,
   output reg        pol_trapezio,
   output reg        pol_salva_info,
	output reg        pol_salva_config,

   // ============= Saídas para Sprites =================
   output reg [5:0]  spr_write_idx,
   output reg [8:0]  spr_write_x,
	output reg [7:0]  spr_write_y,
	output reg [5:0]  spr_write_id,
	output reg        spr_write_flip_x,
	output reg        spr_write_flip_y,
	output reg        spr_write_visivel,
   output reg        spr_salva_info,
	output reg        spr_salva_config,
	
	output reg 			geral_layer,
	output reg        geral_layer_save,
	
	output reg ready,
	output reg valid,
	output reg reset
	
);

	parameter FETCH    = 2'b00;
	parameter DECODE    = 2'b01;
	parameter SAVE    = 2'b10;

	reg [31:0] instrucao_reg;
	reg [1:0]  estado;
	

	always @(posedge clk or negedge rst)begin
		
		if(!rst)begin
			estado <= FETCH;
			spr_salva_info <= 0;
			spr_salva_config <= 0;
			pol_salva_info <= 0;
			pol_salva_config <= 0;
			bg_salva_info <= 0;
			geral_layer_save <= 0;
			reset <= 0;
		end else begin
			if(estado == FETCH)begin
				
				spr_salva_info <= 0;
				spr_salva_config <= 0;
				pol_salva_info <= 0;
				pol_salva_config <= 0;
				bg_salva_info <= 0;
				geral_layer_save <= 0;
				bg_WRoll <= 0;
				valid <= 0;
				reset <= 1;
				if(ativa)begin
				
					instrucao_reg <= instrucao;
					estado <= DECODE;
					
				end else begin
					valid <= 0;
					ready <= 1;
				end
			end else if(estado == DECODE)begin
				valid <= 1;
				ready <= 0;
				case (instrucao_reg[31:29])
					3'b001: begin
						spr_write_idx <= 0;
						spr_write_id  <= 0;
						spr_write_x <= 0;
						spr_write_y <= 0;
						spr_write_visivel <= 0;
						spr_write_flip_x <= 0;
						spr_write_flip_y <= 0;
						pol_y <= 0;
						pol_x  <= 0;
						pol_cordenada <= 0;
						pol_Address <= 0;
						pol_cor <= 0;
						pol_trapezio <= 0;
						pol_visivel <= 0;
						bg_color <= 0;
						bg_y_tile <= 0;
						bg_x_tile <= 0;
						bg_Roll <= 0;
						geral_layer <= 0;
						bg_WRoll <= 0;
						reset <= 1;
					end
					3'b010: begin
						spr_write_idx <= instrucao_reg[28:23];
						spr_write_id  <= instrucao_reg[22:17];
						spr_write_x <= instrucao_reg[16:8];
						spr_write_y <= instrucao_reg[7:0];
					end
					3'b011:begin
						spr_write_idx <= instrucao_reg[8:3];
						spr_write_visivel  <= instrucao_reg[2];
						spr_write_flip_x <= instrucao_reg[1];
						spr_write_flip_y <= instrucao_reg[0];
					end
					3'b100:begin
						pol_y <= instrucao_reg[7:0];
						pol_x  <= instrucao_reg[16:8];
						pol_cordenada <= instrucao_reg[18:17];
						pol_Address <= instrucao_reg[20:19];
					end
					3'b101:begin
						pol_cor <= instrucao_reg[7:0];
						pol_trapezio <= instrucao_reg[8];
						pol_visivel <= instrucao_reg[9];
						pol_Address <= instrucao_reg[11:10];
					end
					3'b110:begin
						bg_color <= instrucao_reg[7:0];
						bg_y_tile <= instrucao_reg[12:8];
						bg_x_tile <= instrucao_reg[18:13];
						bg_Roll <= instrucao_reg[20:19];
					end
					3'b111:begin
						geral_layer <= instrucao_reg[0];
					end
				endcase
				
				estado <= SAVE;
			end else if(estado == SAVE)begin
				valid <= 0;
				case (instrucao_reg[31:29])
					3'b001:begin
						reset <= 0;
					end
					3'b010:begin
						spr_salva_info <= 1;
					end
					3'b011:begin
						spr_salva_config <= 1;
					end
					3'b100:begin
						pol_salva_info <= 1;
					end
					3'b101:begin
						pol_salva_config <= 1;
					end
					3'b110:begin
						if(!instrucao_reg[21])begin
							bg_salva_info <= 1;
						end else begin
							bg_WRoll <= 1;
						end
					end
					3'b111:begin
						geral_layer_save <= 1;
					end
				endcase
				
				estado <= FETCH;
			end else begin
				estado <= FETCH;
			end
		end
	end



endmodule
   
	
