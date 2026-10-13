module pulse_latch (
    input  wire clk,
    input  wire rst_n,
    
    input  wire pulse_in,       // Pulso de 1 ciclo vindo do coprocessador
    input  wire clear_from_hps, // Comando do HPS para limpar a trava
    
    output reg  sticky_ack      // Bit retido que o HPS lê
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sticky_ack <= 1'b0;
        end else begin
            if (pulse_in) begin
                sticky_ack <= 1'b1; // O pulso liga a trava
            end else if (clear_from_hps) begin
                sticky_ack <= 1'b0; // O HPS reseta a trava após ler
            end
        end
    end
endmodule