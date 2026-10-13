module divisor_por_4 (
    input wire clk_in,  // Clock original de entrada
    input wire reset,   // Reset assíncrono (ativo em zero)
    output wire clk_out // Clock de saída (frequência / 4)
);

    // Contador de 2 bits (conta de 0 a 3)
    reg [1:0] contador;

    always @(posedge clk_in or negedge reset) begin
        if (!reset) begin
            contador <= 2'b00; // Zera o contador no reset
        end else begin
            contador <= contador + 1'b1; // Incrementa a cada ciclo de clock
        end
    end

    // O bit 1 do contador inverte seu estado a cada 2 ciclos do clk_in, 
    // gerando um ciclo completo a cada 4 ciclos do clk_in (Duty Cycle de 50%)
    assign clk_out = contador[1];

endmodule