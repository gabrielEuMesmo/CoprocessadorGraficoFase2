module controlador_MEF (
    input  wire        clk,
    input  wire [3:0]  KEY,  // KEY[3:0] (Ativos em BAIXO na DE1-SoC)
    input  wire [9:0]  SW,   // SW[9:0]

    // ================= Saídas para Background =================
    output wire [1:0]  bg_Roll,
    output wire        bg_WRoll,
    output wire [5:0]  bg_x_tile,
    output wire [4:0]  bg_y_tile,
    output wire        bg_write,
    output wire [7:0]  bg_color,

    // ================= Saídas para Polígonos =================
    output wire [1:0]  pol_Address,
    output wire [1:0]  pol_cordenada,
    output wire [8:0]  pol_x,
    output wire [7:0]  pol_y,
    output wire [7:0]  pol_cor,
    output wire        pol_visivel,
    output wire        pol_trapezio,
    output wire        pol_salva,

    // ================= Saídas para Sprites =================
    output wire [5:0]  spr_write_idx,
    output wire [31:0] spr_write_data,
    output wire        spr_write_en,
    
    // Indicadores para LEDs (Para saber em qual estado você está)
    output wire [1:0]  LED_Modo,
    output wire [1:0]  LED_SubEstado
);

    // -----------------------------------------------------------------
    // 1. SINCRONIZADORES E DETECTORES DE BORDA PARA OS BOTÕES (KEY)
    // -----------------------------------------------------------------
    // Na DE1, o botão não apertado é '1' e apertado é '0'.
    reg [2:0] sync_key1, sync_key2, sync_key3;

    always @(posedge clk) begin
        sync_key1 <= {sync_key1[1:0], ~KEY[1]}; // Invertido para lógica Positiva
        sync_key2 <= {sync_key2[1:0], ~KEY[2]};
        sync_key3 <= {sync_key3[1:0], ~KEY[3]};
    end

    wire press_MODE   = (sync_key1[2:1] == 2'b01); // Borda de subida do KEY[1]
    wire press_NEXT   = (sync_key2[2:1] == 2'b01); // Borda de subida do KEY[2]
    wire press_ACTION = (sync_key3[2:1] == 2'b01); // Borda de subida do KEY[3]
    wire rst_n        = KEY[0]; // Reset assíncrono padrão

    // -----------------------------------------------------------------
    // 2. MÁQUINA DE ESTADOS PRINCIPAL
    // -----------------------------------------------------------------
    localparam MODE_RUN    = 2'd0;
    localparam MODE_BG     = 2'd1;
    localparam MODE_POL    = 2'd2;
    localparam MODE_SPRITE = 2'd3;

    reg [1:0] mode;
    reg [1:0] sub_state;

    // Registradores Temporários de Montagem (Background)
    reg [5:0] temp_bg_x;
    reg [4:0] temp_bg_y;
    reg [7:0] temp_bg_color;
    
    // Registradores Temporários de Montagem (Polígono)
    reg [1:0] temp_pol_idx;
    reg [1:0] temp_pol_coord;
    reg [8:0] temp_pol_x;
    reg [7:0] temp_pol_y;
    
    // Registradores Temporários de Montagem (Sprite)
    reg [5:0] temp_spr_idx;
    reg [8:0] temp_spr_x;
    reg [7:0] temp_spr_y;
    reg [5:0] temp_spr_tile;
    reg       temp_spr_flipx, temp_spr_flipy, temp_spr_vis;

    // Sinais de pulso de gravação (Duração 1 Clock)
    reg reg_bg_write, reg_bg_wroll;
    reg reg_pol_salva;
    reg reg_spr_write;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode <= MODE_RUN;
            sub_state <= 2'd0;
            
            reg_bg_write <= 1'b0; reg_bg_wroll <= 1'b0;
            reg_pol_salva <= 1'b0; reg_spr_write <= 1'b0;
        end else begin
            // Zerar pulsos por padrão
            reg_bg_write <= 1'b0; reg_bg_wroll <= 1'b0;
            reg_pol_salva <= 1'b0; reg_spr_write <= 1'b0;

            // Trocar Modo Principal (Zera o subestado sempre que muda de modo)
            if (press_MODE) begin
                mode <= mode + 1'b1;
                sub_state <= 2'd0;
            end
            // Trocar Subestado
            else if (press_NEXT) begin
                sub_state <= sub_state + 1'b1;
            end

            // Navegação dentro de cada Modo
            case (mode)
                MODE_RUN: begin
                    // Nada acontece, o hardware roda livremente.
                end

                MODE_BG: begin
                    case (sub_state)
                        2'd0: if (press_ACTION) temp_bg_x     <= SW[5:0]; // Grava X
                        2'd1: if (press_ACTION) temp_bg_y     <= SW[4:0]; // Grava Y
                        2'd2: if (press_ACTION) begin                     // Escreve Cor
                                  temp_bg_color <= SW[7:0]; 
                                  reg_bg_write  <= 1'b1; 
                              end
                        2'd3: if (press_ACTION) reg_bg_wroll  <= 1'b1;    // Scroll usa SW[1:0] direto
                    endcase
                end

                MODE_POL: begin
                    case (sub_state)
                        2'd0: if (press_ACTION) begin 
                                  temp_pol_idx   <= SW[1:0]; 
                                  temp_pol_coord <= SW[3:2]; 
                              end
                        2'd1: if (press_ACTION) temp_pol_x <= SW[8:0];
                        2'd2: if (press_ACTION) temp_pol_y <= SW[7:0];
                        2'd3: if (press_ACTION) reg_pol_salva <= 1'b1; // Cor, Visivel e Trapezio vão direto das chaves
                    endcase
                end

                MODE_SPRITE: begin
                    case (sub_state)
                        2'd0: if (press_ACTION) temp_spr_idx <= SW[5:0];
                        2'd1: if (press_ACTION) temp_spr_x   <= SW[8:0];
                        2'd2: if (press_ACTION) temp_spr_y   <= SW[7:0];
                        2'd3: if (press_ACTION) begin
                                  temp_spr_tile  <= SW[5:0];
                                  temp_spr_vis   <= SW[6];
                                  temp_spr_flipy <= SW[7];
                                  temp_spr_flipx <= SW[8];
                                  reg_spr_write  <= 1'b1;
                              end
                    endcase
                end
            endcase
        end
    end

    // -----------------------------------------------------------------
    // 3. ATRIBUIÇÃO CONTÍNUA DAS SAÍDAS PARA OS MÓDULOS
    // -----------------------------------------------------------------
    
    // Background
    assign bg_x_tile = temp_bg_x;
    assign bg_y_tile = temp_bg_y;
    assign bg_color  = (mode == MODE_BG && sub_state == 2'd2) ? SW[7:0] : temp_bg_color;
    assign bg_Roll   = SW[1:0];
    assign bg_write  = reg_bg_write;
    assign bg_WRoll  = reg_bg_wroll;

    // Polígonos
    assign pol_Address   = temp_pol_idx;
    assign pol_cordenada = temp_pol_coord;
    assign pol_x         = (mode == MODE_POL && sub_state == 2'd1) ? SW[8:0] : temp_pol_x;
    assign pol_y         = (mode == MODE_POL && sub_state == 2'd2) ? SW[7:0] : temp_pol_y;
    assign pol_cor       = SW[7:0];
    assign pol_visivel   = SW[8];
    assign pol_trapezio  = SW[9];
    assign pol_salva     = reg_pol_salva;

    // Sprites
    assign spr_write_idx = temp_spr_idx;
    assign spr_write_en  = reg_spr_write;
    
    // Concatenação formatada conforme o Compositor (Total 32 bits)
    // [31:23] X (9), [22:15] Y (8), [14:9] Tile (6), [8] FlipX, [7] FlipY, [6] Visivel, [5:0] Padding (Zerar)
    assign spr_write_data = {
        temp_spr_x,
        temp_spr_y,
        ((mode == MODE_SPRITE && sub_state == 2'd3) ? SW[5:0] : temp_spr_tile),
        ((mode == MODE_SPRITE && sub_state == 2'd3) ? SW[8]   : temp_spr_flipx),
        ((mode == MODE_SPRITE && sub_state == 2'd3) ? SW[7]   : temp_spr_flipy),
        ((mode == MODE_SPRITE && sub_state == 2'd3) ? SW[6]   : temp_spr_vis),
        6'd0
    };

    // Feedback Visual para a Placa
    assign LED_Modo      = mode;
    assign LED_SubEstado = sub_state;

endmodule