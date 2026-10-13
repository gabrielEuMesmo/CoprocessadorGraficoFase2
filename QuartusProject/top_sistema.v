module top_sistema (
    input  wire        clock,      
    input  wire        reset,
	 input  wire [31:0] instrucao,
	 input  wire 		  ativa,
	 input  wire        clear,

    output wire        hsync,
    output wire        vsync_out,   
    output wire [7:0]  red,
    output wire [7:0]  green,
    output wire [7:0]  blue,
    output wire        sync,
    output wire        vga_clk,     
    output wire        blank,
	 
	 output LEDIDLE,
	 output ready,
	 output valid
);


  
    wire [1:0]  w_bg_Roll;
    wire        w_bg_WRoll;
    wire [5:0]  w_bg_x_tile;
    wire [4:0]  w_bg_y_tile;
    wire        w_bg_write;
    wire [7:0]  w_bg_color;

    wire [1:0]  w_pol_Address;  
    wire [1:0]  w_pol_cordenada;
    wire [8:0]  w_pol_x;
    wire [7:0]  w_pol_y;
    wire [7:0]  w_pol_cor;
    wire        w_pol_visivel;
    wire        w_pol_trapezio;
    wire        w_pol_salva_info;
	 wire        w_pol_salva_config;

    wire [5:0]  w_spr_write_idx;
    wire [8:0]  w_spr_write_x;
	 wire [7:0]  w_spr_write_y;
	 wire [5:0]  w_spr_write_id;
	 wire        w_spr_write_flip_x;
	 wire        w_spr_write_flip_y;
	 wire        w_spr_write_visivel;
    wire        w_spr_write_en_info;
	 wire        w_spr_write_en_config;

   
    wire [16:0] w_address;
    wire [7:0]  w_pixel;
    wire        w_wren;
    wire        w_vsync;
    wire        w_camada_ativa; 
	 
	 reg [16:0] w_address_reg;
	 
	 wire reset_inst, ativa_pulse, valid_pulse, layer_order;
	 
	 rising_edge_detector (
			.clk (clock),
			.rst_n(reset),
			.level_i(ativa),
			.pulse_o(ativa_pulse)
	 );
		
	 pulse_latch (
     .clk(clock),
     .rst_n(reset),
   
     .pulse_in(valid_pulse),       // Pulso de 1 ciclo vindo do coprocessador
     .clear_from_hps(clear), // Comando do HPS para limpar a trava
   
     .sticky_ack(valid)      // Bit retido que o HPS lê
    );


  
    UnidadeDeControle u_controlador (
        .clk           (clock),
		  .instrucao      (instrucao),
		  .ativa         (ativa_pulse),
		  .rst           (reset),
		  
		  .ready         (ready),
		  .valid         (valid_pulse),
		  
		  .geral_layer   (layer_order),

        .bg_Roll       (w_bg_Roll),
        .bg_WRoll      (w_bg_WRoll),
        .bg_x_tile     (w_bg_x_tile),
        .bg_y_tile     (w_bg_y_tile),
        .bg_salva_info (w_bg_write),
        .bg_color      (w_bg_color),
		  
        .pol_Address   (w_pol_Address),
        .pol_cordenada (w_pol_cordenada),
        .pol_x         (w_pol_x),
        .pol_y         (w_pol_y),
        .pol_cor       (w_pol_cor),
        .pol_visivel   (w_pol_visivel),
        .pol_trapezio  (w_pol_trapezio),
        .pol_salva_info(w_pol_salva_info),
		  .pol_salva_config(w_pol_salva_config),
		  
        .spr_write_idx  (w_spr_write_idx),
        .spr_write_x    (w_spr_write_x),
	     .spr_write_y    (w_spr_write_y),
	     .spr_write_id   (w_spr_write_id),
	     .spr_write_flip_x (w_spr_write_flip_x),
	     .spr_write_flip_y (w_spr_write_flip_y),
	     .spr_write_visivel(w_spr_write_visivel),
        .spr_salva_info   (w_spr_write_en_info),
	     .spr_salva_config (w_spr_write_en_config),
		  
		  .reset            (reset_inst)

    );


    motorVideoTop u_video (
        .clk            (clock),
        .reset          (reset_inst),
        .vsync          (w_vsync),
        .layer_order    (layer_order),

        .pol_polAddress (w_pol_Address),
        .pol_cordenada  (w_pol_cordenada),
        .pol_x          (w_pol_x),
        .pol_y          (w_pol_y),
        .pol_cor        (w_pol_cor),
        .pol_visivel    (w_pol_visivel),
        .pol_trapezio   (w_pol_trapezio),
        .pol_salva_info (w_pol_salva_info),
		  .pol_salva_config (w_pol_salva_config),


        .bg_Roll        (w_bg_Roll),
        .bg_WRoll       (w_bg_WRoll),
        .bg_x_tile      (w_bg_x_tile),
        .bg_y_tile      (w_bg_y_tile),
        .bg_write       (w_bg_write),
        .bg_color       (w_bg_color),

        .spr_write_idx  (w_spr_write_idx),
        .spr_write_x    (w_spr_write_x),
	     .spr_write_y    (w_spr_write_y),
	     .spr_write_id   (w_spr_write_id),
	     .spr_write_flip_x (w_spr_write_flip_x),
	     .spr_write_flip_y (w_spr_write_flip_y),
	     .spr_write_visivel(w_spr_write_visivel),
        .spr_write_en_info(w_spr_write_en_info),
	     .spr_write_en_config(w_spr_write_en_config),

        .address        (w_address),
        .pixel          (w_pixel),
        .camada_ativa   (w_camada_ativa),
        .wren           (w_wren),
		  .LEDIDLE			(LEDIDLE)
    );
	 
	always @(posedge clock or negedge reset)begin
	 if(!reset)begin
		w_address_reg = 0;
	 end else begin
		w_address_reg = w_address;
	 end
	end


    resolucao_logica u_resolucao (
        .clock     (clock),
        .reset     (reset),       
        .data      (w_pixel),
        .wren      (w_wren),
        .wraddress (w_address_reg),
        .hsync     (hsync),
        .vsync     (w_vsync),     
        .red       (red),
        .green     (green),
        .blue      (blue),
        .sync      (sync),
        .clk       (vga_clk),
        .blank     (blank)
    );

    assign vsync_out = w_vsync;

endmodule