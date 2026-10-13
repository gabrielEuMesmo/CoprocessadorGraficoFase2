module rising_edge_detector (
    input  wire clk,
    input  wire rst_n,
    input  wire level_i,
    output wire pulse_o
);
    reg level_d; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            level_d <= 1'b0;
        end else begin
            level_d <= level_i;
        end
    end

  
    assign pulse_o = level_i & (~level_d);

endmodule