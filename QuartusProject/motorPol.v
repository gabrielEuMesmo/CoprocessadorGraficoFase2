module motorPol (
    input  wire        enable,
    input  wire        clk,
    input  wire [1:0]  polAddress,
    input  wire [1:0]  cordenada,
    input  wire [8:0]  x,
    input  wire [7:0]  y,
    input  wire [7:0]  cor,
    input  wire        visivel,
    input  wire        trapezio,
    input  wire        salva_info,
	 input  wire        salva_config,
	 
    input  wire        reset,
    output wire [16:0] memAdress,
    output reg  [7:0]  pixelS,
    output wire        done
);

    reg [77:0] pol [0:3];
    wire [7:0] pixel [0:3];
    wire [8:0] next_x;
    wire [7:0] next_y;
    wire clkP4;
	 
    integer u;
    genvar e;


    always @(posedge clk or negedge reset) begin 
        if (!reset) begin
            pol[0] <= 78'd0; pol[1] <= 78'd0; 
            pol[2] <= 78'd0; pol[3] <= 78'd0;
        end else if (salva_info) begin
            case (cordenada)
                2'b00: pol[polAddress] <= {pol[polAddress][77:51], pol[polAddress][50:34], pol[polAddress][33:17], x, y};
                2'b01: pol[polAddress] <= {pol[polAddress][77:51], pol[polAddress][50:34], x, y, pol[polAddress][16:0]};
                2'b10: pol[polAddress] <= {pol[polAddress][77:51], x, y, pol[polAddress][33:17], pol[polAddress][16:0]};
                2'b11: pol[polAddress] <= {pol[polAddress][77:68], x, y, pol[polAddress][50:34], pol[polAddress][33:17], pol[polAddress][16:0]};
            endcase
        end else if (salva_config) begin
            pol[polAddress] <= {visivel, trapezio, cor, pol[polAddress][67:0]};
        end
    end

   generate
        for (e = 0; e < 4; e = e + 1) begin : GEN_POLIGONOS
            poligono_gerador inst_pol (
                .trapezio (pol[e][76]),
                .x        (next_x),
                .y        (next_y),
                .x0       (pol[e][16:8]),  .y0(pol[e][7:0]),
                .x1       (pol[e][33:25]), .y1(pol[e][24:17]),
                .x2       (pol[e][50:42]), .y2(pol[e][41:34]),
                .x3       (pol[e][67:59]), .y3(pol[e][58:51]),
                .color    (pol[e][75:68]),
                .pixel    (pixel[e]),
            );
        end
    endgenerate


    always @(*) begin
        pixelS = 8'h00;
        for (u = 0; u < 4; u = u + 1) begin
            if (pixel[u] != 8'h00 && pol[u][77]) begin
                pixelS = pixel[u];
            end
        end
    end
	 
	 divisor_por_4 (
			.clk_in(clk),  // Clock original de entrada
			.reset(reset),   // Reset assíncrono (ativo em zero)
			.clk_out(clkP4) // Clock de saída (frequência / 4)
    );

    contadorVid inst_contador (
        .reset  (reset),
        .clk    (clkP4),
        .enable (enable),
        .x      (next_x),
        .y      (next_y),
        .address(memAdress),
        .done   (done)
    );

endmodule