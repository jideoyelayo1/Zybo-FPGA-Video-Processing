`timescale 1ns / 1ps

module sqrt_fn (
    input wire signed [15:0] x, // squared number
    output wire signed [15:0] y // result
);

reg signed [15:0] xn;
reg signed [15:0] xn1;

initial begin
    xn = 1; // so it does not crash
    xn1 = 0;
end

always @(*) begin
    if (x <= 0) begin
        xn1 = 0;
    end else begin
        xn1 = (xn + (x / xn)) / 2;
        xn = xn1;
    end
end

assign y = xn1;

endmodule


