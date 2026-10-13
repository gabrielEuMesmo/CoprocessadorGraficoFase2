/*

module contadorVid(
    input             reset,   
    input             clk,
    input             enable,
    output reg [8:0]  x,
    output reg [7:0]  y,
    output reg [16:0] address,
    output reg        done
);

    reg [16:0] count;
    reg        contando;
    reg        enable_d;  

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            count    <= 17'd0;
            contando <= 1'b0;
            done     <= 1'b0;
            enable_d <= 1'b0;
        end else begin
            enable_d <= enable;

            if (enable && !enable_d) begin
               
                count    <= 17'd0;
                contando <= 1'b1;
                done     <= 1'b0;
            end else if (contando) begin
                if (count == 17'd76799) begin
                    contando <= 1'b0;
                    done     <= 1'b1;
                end else begin
                    count <= count + 1'b1;
                end
            end
				if(done)begin
					done     <= 1'b0;
				end
        end
    end

    always @(*) begin
        address = count;
        y = count / 320;
        x = count % 320;
    end

endmodule */

module contadorVid(
    input reset, 
    input clk,
    input enable,
    output reg [8:0] x,
    output reg [7:0] y,
    output reg [16:0] address,
    output reg done
);

    reg [16:0] count;
    reg contando;
    reg enable_d; 
    
    // Registradores internos para as coordenadas
    reg [8:0] reg_x;
    reg [7:0] reg_y;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            count <= 17'd0;
            contando <= 1'b0;
            done <= 1'b0;
            enable_d <= 1'b0;
            reg_x <= 9'd0;
            reg_y <= 8'd0;
        end else begin
            enable_d <= enable;

            // Detecta a borda de subida do enable para iniciar
            if (enable && !enable_d) begin
                count <= 17'd0;
                contando <= 1'b1;
                done <= 1'b0;
                reg_x <= 9'd0;
                reg_y <= 8'd0;
            end else if (contando) begin
                // Verifica se chegou no final da tela (320x240 = 76800 pixels)
                if (count == 17'd76799) begin
                    contando <= 1'b0;
                    done <= 1'b1;
                end else begin
                    count <= count + 1'b1;
                    
                    // Lógica síncrona para X e Y substituindo a divisão e o módulo
                    if (reg_x == 9'd319) begin
                        reg_x <= 9'd0;
                        reg_y <= reg_y + 1'b1;
                    end else begin
                        reg_x <= reg_x + 1'b1;
                    end
                end
            end
            
            // Limpa o done no ciclo seguinte
            if (done) begin
                done <= 1'b0;
            end
        end
    end

    // Saídas puramente ligadas aos registradores, sem matemática
    always @(*) begin
        address = count;
        x = reg_x;
        y = reg_y;
    end

endmodule
		
	
	