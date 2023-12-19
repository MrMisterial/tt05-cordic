module DFlipFlop (
    input clk_i,
    input rst_i,
    input d_i,
    output reg q_o
);

    always @(posedge clk_i ) begin
        if (rst_i == 1'b1)
            q_o <= 1'b1;
        else
            q_o <= d_i;
    end
endmodule