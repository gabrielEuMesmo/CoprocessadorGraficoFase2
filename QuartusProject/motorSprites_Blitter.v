module motorSprites_Blitter (
    input  wire        clk,
    input  wire        reset,
    

    input  wire        start_draw,
    output reg         done_draw,
    

    input  wire [5:0]  spr_write_idx,
    input  wire [8:0]  spr_write_x,
	 input  wire [7:0]  spr_write_y,
	 input  wire [5:0]  spr_write_id,
	 input  wire        spr_write_flip_x,
	 input  wire        spr_write_flip_y,
	 input  wire        spr_write_visivel,
    input  wire        spr_write_en_info,
    input  wire        spr_write_en_config,
	 
  
    output reg  [16:0] address,   
    output reg  [7:0]  color      
);


    reg [31:0] oam [0:63];
    integer i;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            for (i = 0; i < 64; i = i + 1) begin
                oam[i] <= 32'd0;
            end
        end else if (spr_write_en_info) begin
            oam[spr_write_idx] <= {spr_write_x, spr_write_y, spr_write_id, oam[spr_write_idx][8:0]} ;
        end else if (spr_write_en_config) begin
            oam[spr_write_idx] <= {oam[spr_write_idx][31:9],spr_write_flip_x, spr_write_flip_y, spr_write_visivel, 6'd0 } ;
        end
    end


    reg  [13:0] rom_addr;
    wire [7:0]  rom_data;

    sprite_rom_m10k u_sprite_rom (
        .address ( rom_addr ),
        .clock   ( clk      ),
        .q       ( rom_data )
    );


    localparam ST_IDLE       = 3'd0;
    localparam ST_READ_OAM   = 3'd1;
    localparam ST_SETUP_ROM  = 3'd2;
    localparam ST_WAIT_ROM   = 3'd3;
    localparam ST_WRITE_BUF  = 3'd4;

    reg [2:0] state;
    reg [5:0] spr_idx;
    reg [3:0] px;
    reg [3:0] py;

    wire [8:0] pos_x    = oam[spr_idx][31:23];
    wire [7:0] pos_y    = oam[spr_idx][22:15];
    wire [5:0] tile_id  = oam[spr_idx][14:9];
    wire       flip_x   = oam[spr_idx][8];
    wire       flip_y   = oam[spr_idx][7];
    wire       visible  = oam[spr_idx][6];

    wire [3:0] px_flipped = flip_x ? (4'd15 - px) : px;
    wire [3:0] py_flipped = flip_y ? (4'd15 - py) : py;

  
    wire [9:0] real_x_full = pos_x + px;  
    wire [8:0] real_y_full = pos_y + py; 

   
    wire offscreen = (real_x_full >= 10'd320) || (real_y_full >= 9'd240);

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state     <= ST_IDLE;
            done_draw <= 1'b0;
            spr_idx   <= 6'd63;
            px        <= 4'd0;
            py        <= 4'd0;
            address   <= 17'd0;
            color     <= 8'd0;
        end else begin
            
            case (state)
                ST_IDLE: begin
                    done_draw <= 1'b0;
                    if (start_draw) begin
                        spr_idx <= 6'd63; 
                        state   <= ST_READ_OAM;
                    end
                end

                ST_READ_OAM: begin
                    if (visible) begin
                        px    <= 4'd0;
                        py    <= 4'd0;
                        state <= ST_SETUP_ROM;
                    end else begin
                        if (spr_idx == 6'd0) begin
                            done_draw <= 1'b1;
                            state     <= ST_IDLE;
                        end else begin
                            spr_idx <= spr_idx - 1'b1;
                        end
                    end
                end

                ST_SETUP_ROM: begin
                    rom_addr <= {tile_id, py_flipped, px_flipped};
                    state    <= ST_WAIT_ROM;
                end

                ST_WAIT_ROM: begin
                    state <= ST_WRITE_BUF;
                end

                ST_WRITE_BUF: begin
                   
                    if (!offscreen) begin
                        address <= (real_y_full * 17'd320) + real_x_full[8:0];
                        color   <= rom_data;
                    end

                    if (px == 4'd15) begin
                        px <= 4'd0;
                        if (py == 4'd15) begin
                            if (spr_idx == 6'd0) begin
                                done_draw <= 1'b1;
                                state     <= ST_IDLE;
                            end else begin
                                spr_idx <= spr_idx - 1'b1;
                                state   <= ST_READ_OAM;
                            end
                        end else begin
                            py    <= py + 1'b1;
                            state <= ST_SETUP_ROM;
                        end
                    end else begin
                        px    <= px + 1'b1;
                        state <= ST_SETUP_ROM;
                    end
                end
            endcase
        end
    end

endmodule