module motorVideoTop (
    input  wire        clk,
    input  wire        reset,
    input  wire        vsync,
    input  wire        layer_order,

    // ---- Escrita no motorPol ----
    input  wire [1:0]  pol_polAddress,
    input  wire [1:0]  pol_cordenada,
    input  wire [8:0]  pol_x,
    input  wire [7:0]  pol_y,
    input  wire [7:0]  pol_cor,
    input  wire        pol_visivel,
    input  wire        pol_trapezio,
    input  wire        pol_salva_info,
	 input  wire        pol_salva_config,

    // ---- Escrita no motorBack_Ground ----
    input  wire [1:0]  bg_Roll,
    input  wire        bg_WRoll,
    input  wire [5:0]  bg_x_tile,
    input  wire [4:0]  bg_y_tile,
    input  wire        bg_write,
    input  wire [7:0]  bg_color,

    // ---- Escrita na OAM do motorSprites_Blitter ----
    input  wire [5:0]  spr_write_idx,
    input  wire [8:0]  spr_write_x,
	 input  wire [7:0]  spr_write_y,
	 input  wire [5:0]  spr_write_id,
	 input  wire        spr_write_flip_x,
	 input  wire        spr_write_flip_y,
	 input  wire        spr_write_visivel,
    input  wire        spr_write_en_info,
	 input  wire        spr_write_en_config,

    // ---- Saída única: camada ativa no momento, segundo a MEF ----
    output reg  [16:0] address,
    output reg  [7:0]  pixel,
    output wire        camada_ativa, // alto sempre que Bg/Sprt/Pol estiver desenhando
	 output reg wren,
	 output LEDIDLE
);

    wire enableBg, enableSprt, enablePol;
    wire doneBg, doneSprt, donePol;

    MEF_geral_layer u_mef (
        .reset      (reset),
        .layer_order(layer_order),
        .clk        (clk),
        .doneBg     (doneBg),
        .doneSprt   (doneSprt),
        .donePol    (donePol),
        .enableBg   (enableBg),
        .enableSprt (enableSprt),
        .enablePol  (enablePol),
        .vsync      (vsync), 
		  .LEDIDLE(LEDIDLE)
    );

    // ================= Background =================
    wire [7:0]  bg_pixel;
    wire [16:0] bg_address;
	 wire bgPulseEnable;
	 

    motorBack_Ground u_bg (
        .reset   (reset),
        .enable  (enableBg),
        .clk     (clk),
        .Roll    (bg_Roll),
        .WRoll   (bg_WRoll),
        .x_tile  (bg_x_tile),
        .y_tile  (bg_y_tile),
        .write   (bg_write),
        .color   (bg_color),
        .colorOut(bg_pixel),
        .address (bg_address),
        .done    (doneBg)
    );

    // ================= Polígonos =================
    wire [7:0]  pol_pixel;
    wire [16:0] pol_address;
	 wire polPulseEnable;
	 

    motorPol u_pol (
        .enable      (enablePol),
        .clk         (clk),
        .polAddress  (pol_polAddress),
        .cordenada   (pol_cordenada),
        .x           (pol_x),
        .y           (pol_y),
        .cor         (pol_cor),
        .visivel     (pol_visivel),
        .trapezio    (pol_trapezio),
        .salva_info  (pol_salva_info),
		  .salva_config(pol_salva_config),
        .reset       (reset),
        .memAdress   (pol_address),
        .pixelS      (pol_pixel),
        .done        (donePol)
    );

    // ================= Sprites =================
    // enableSprt é nível -> vira pulso de start_draw só na borda
    // de subida, pra não reiniciar o Blitter em loop dentro do
    // mesmo estado SPRT.
    wire [7:0]  spr_pixel;
    wire [16:0] spr_address;
    wire        spr_start_pulse;

    rising_edge_detector u_edge_sprt (
        clk,
        reset,
        enableSprt,
        spr_start_pulse
    );

    motorSprites_Blitter u_sprt (
        .clk                   (clk),
        .reset                 (reset),
        .start_draw            (spr_start_pulse),
        .done_draw             (doneSprt),
        .spr_write_idx         (spr_write_idx),
        .spr_write_x           (spr_write_x),
		  .spr_write_y           (spr_write_y),
		  .spr_write_id          (spr_write_id),
		  .spr_write_flip_x      (spr_write_flip_x),
		  .spr_write_flip_y      (spr_write_flip_y),
		  .spr_write_visivel		 (spr_write_visivel),
        .spr_write_en_info     (spr_write_en_info),
		  .spr_write_en_config   (spr_write_en_config),
        .address               (spr_address),
        .color                 (spr_pixel)
    );

    // ================= Mux final =================
    // A MEF garante que só um enable fica ativo por vez, então
    // esse if/else em cadeia é só uma seleção segura — não existe
    // disputa real de prioridade entre os ramos.
    /*always @(*) begin
			address = 17'd0;
         pixel   = 8'h00;
			wren = 1'b0;
        if (enableBg) begin
            address = bg_address;
            pixel   = bg_pixel;
				wren = 1'b1;
        end else if (enablePol) begin
				if(pol_pixel > 0)begin
					address = pol_address;
					pixel   = pol_pixel;
					wren = 1'b1;
				end else begin
					wren = 1'b0;
				end
        end else if(enableSprt) begin
				if(spr_pixel > 0)begin
					address = spr_address;
					pixel   = spr_pixel;
					wren = 1'b1;
				end else begin
					wren = 1'b0;
				end
        end else begin
            address = 17'd0;
            pixel   = 8'h00;
				wren = 1'b0;
        end
    end*/
	 
	 // ================= Mux final =================
 // Agora utilizando lógica sequencial (Flip-Flops) para blindar a RAM contra glitches
 always @(negedge clk or negedge reset) begin
    if (!reset) begin
        address <= 17'd0;
        pixel <= 8'h00;
        wren <= 1'b0;
    end else begin
        if (enableBg) begin
            address <= bg_address;
            pixel <= bg_pixel;
            wren <= 1'b1;
        end else if (enablePol) begin
            if (pol_pixel > 0) begin
                address <= pol_address;
                pixel <= pol_pixel;
                wren <= 1'b1;
            end else begin
                wren <= 1'b0;
            end
        end else if (enableSprt) begin
            if (spr_pixel > 0) begin
                address <= spr_address;
                pixel <= spr_pixel;
                wren <= 1'b1;
            end else begin
                wren <= 1'b0;
            end
        end else begin
            wren <= 1'b0;
            // address e pixel retêm o valor anterior de forma segura no flip-flop
        end
    end
 end

    assign camada_ativa = enableBg | enableSprt | enablePol;

endmodule