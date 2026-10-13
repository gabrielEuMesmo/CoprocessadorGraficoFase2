/*module poligono_gerador(
	 input  wire trapezio,
    input  wire [8:0] x,
    input  wire [7:0] y,

    input  wire [8:0] x0,
    input  wire [7:0] y0,

    input  wire [8:0] x1,
    input  wire [7:0] y1,

    input  wire [8:0] x2,
    input  wire [7:0] y2,
	 
	 input  wire [8:0] x3,
    input  wire [7:0] y3,


    input  wire [7:0] color,

    output reg [7:0] pixel
);

    integer e0;
    integer e1;
    integer e2;
	 integer e3;

    always @(*) begin

        // Aresta P0 -> P1
        e0 = ((x1 - x0) * (y - y0)) -
             ((y1 - y0) * (x - x0));

        // Aresta P1 -> P2
        e1 = ((x2 - x1) * (y - y1)) -
             ((y2 - y1) * (x - x1));
			if(trapezio)begin
        // Aresta P2 -> P0
				e2 = ((x3 - x2) * (y - y2)) -
             ((y3 - y2) * (x - x2));
				 
				 e3 = ((x0 - x3) * (y - y3)) -
             ((y0 - y3) * (x - x3));
			end else begin
				
				e2 = ((x0 - x2) * (y - y2)) -
             ((y0 - y2) * (x - x2));
				 
				e3 = 0;
	
			end
			
		if(trapezio)begin
		
			if ((e0 >= 0) && (e1 >= 0) && (e2 >= 0) && (e3 >= 0)) begin
            pixel  = color;
        end
        else if ((e0 <= 0) && (e1 <= 0) && (e2 <= 0) && (e3 <= 0)) begin
            pixel  = color;
        end
        else begin
            pixel  = 8'h00;
        end
		
		
		end else begin
        // Verifica se o pixel está dentro
        if ((e0 >= 0) && (e1 >= 0) && (e2 >= 0)) begin
            pixel  = color;
        end
        else if ((e0 <= 0) && (e1 <= 0) && (e2 <= 0)) begin
            pixel  = color;
        end
        else begin
            pixel  = 8'h00;
        end
		  
		  end

    end

endmodule*/

module poligono_gerador(
    input  wire trapezio,
    input  wire [8:0] x,
    input  wire [7:0] y,
    input  wire [8:0] x0, 
    input  wire [7:0] y0,
    input  wire [8:0] x1,
    input  wire [7:0] y1,
    input  wire [8:0] x2,
    input  wire [7:0] y2,
    input  wire [8:0] x3,
    input  wire [7:0] y3,
    input  wire [7:0] color,
    output reg  [7:0] pixel
);
    
    wire signed [9:0] sx  = {1'b0, x};
    wire signed [8:0] sy  = {1'b0, y};
    wire signed [9:0] sx0 = {1'b0, x0}, sx1 = {1'b0, x1}, sx2 = {1'b0, x2}, sx3 = {1'b0, x3};
    wire signed [8:0] sy0 = {1'b0, y0}, sy1 = {1'b0, y1}, sy2 = {1'b0, y2}, sy3 = {1'b0, y3};

    integer e0, e1, e2, e3;

    always @(*) begin
        e0 = ((sx1 - sx0) * (sy - sy0)) - ((sy1 - sy0) * (sx - sx0));
        e1 = ((sx2 - sx1) * (sy - sy1)) - ((sy2 - sy1) * (sx - sx1));

        if (trapezio) begin
            e2 = ((sx3 - sx2) * (sy - sy2)) - ((sy3 - sy2) * (sx - sx2));
            e3 = ((sx0 - sx3) * (sy - sy3)) - ((sy0 - sy3) * (sx - sx3));
        end else begin
            e2 = ((sx0 - sx2) * (sy - sy2)) - ((sy0 - sy2) * (sx - sx2));
            e3 = 0;
        end

        if (trapezio) begin
            if      ((e0>=0)&&(e1>=0)&&(e2>=0)&&(e3>=0)) pixel = color;
            else if ((e0<=0)&&(e1<=0)&&(e2<=0)&&(e3<=0)) pixel = color;
            else pixel = 8'h00;
        end else begin
            if      ((e0>=0)&&(e1>=0)&&(e2>=0)) pixel = color;
            else if ((e0<=0)&&(e1<=0)&&(e2<=0)) pixel = color;
            else pixel = 8'h00;
        end
    end
endmodule