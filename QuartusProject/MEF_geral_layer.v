module MEF_geral_layer(
	input reset,
	input layer_order,
	input clk,
	input doneBg,
	input doneSprt,
	input donePol,
	output reg enableBg,
	output reg enableSprt,
	output reg enablePol,
	input vsync,
	output reg LEDIDLE);
	
	wire vsyncPulse;
	
	parameter BG = 2'b00, SPRT = 2'b01, POL = 2'b10, IDLE = 2'b11;
	reg [1:0] estado_atual, prox_estado;
	
		always @(posedge clk or negedge reset) begin
			
			if(!reset)begin
				estado_atual = IDLE;
			end else begin
				estado_atual = prox_estado;
			end
		end
		
		always @(*)begin
			enableBg   = 1'b0;
			enableSprt = 1'b0;
			enablePol  = 1'b0;
			prox_estado = estado_atual;
			
			if(estado_atual == IDLE )begin
				if(vsyncPulse)begin
					prox_estado = BG;
			
						

				end else begin
						
					prox_estado = IDLE;
					
				end
			end else if(estado_atual == BG )begin
				if(doneBg)begin
					if(layer_order)begin
						prox_estado = SPRT;
			
						
					end else begin
					
						prox_estado = POL;
					
					end
				end else begin
						
					prox_estado = BG;
					
				end
				
			end else if(estado_atual == POL )begin
				if(donePol)begin
			
					if(layer_order)begin
					
						prox_estado = IDLE;
						
					end else begin
						
						prox_estado = SPRT;
						
					end
				end else begin
					
					prox_estado = POL;
				
				end
				
			end else if(estado_atual == SPRT )begin
				if(doneSprt)begin
			
					if(layer_order)begin
					
						prox_estado = POL;
						
					end else begin
						
						prox_estado = IDLE;
						
					end
				end else begin
					
					prox_estado = SPRT;
				
				end
				
			end
				if(estado_atual == BG)begin
					LEDIDLE = 1'b1;
				end else begin
					LEDIDLE = 1'b0;
				end
				if(estado_atual == BG)begin
					enableBg = 1'b1;
				end else begin
					enableBg = 1'b0;
				end
				
				if(estado_atual == POL)begin
					enablePol = 1'b1;
				end else begin
					enablePol = 1'b0;
				end
				
				if(estado_atual == SPRT)begin
					enableSprt = 1'b1;
				end else begin
					enableSprt = 1'b0;
				end
				
			end
			
			
rising_edge_detector (
    clk,
    reset,
    vsync,
    vsyncPulse
);
	
	
	
	
endmodule