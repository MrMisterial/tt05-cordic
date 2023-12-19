`include "d_flipflop.v"


module uart_rx #(
    parameter CLKS_PER_BIT = 1000, //???
    parameter DATA_LEN = 8,
    parameter N_SYNCS = 2
) (
    input                       clk_i,
    input                       rst_i,
    input                       rx_i,
    output wire [DATA_LEN-1:0]  data_o,
    output reg                  data_valid_strb_o
);

    localparam IDLE         = 2'b00;
    localparam STARTBIT     = 2'b01;
    localparam RECEIVING    = 2'b10;
    localparam STOPBIT      = 2'b11;

    parameter BW_COUNTER = $clog2(DATA_LEN);
    parameter BW_BAUD_COUNTER =  $clog2(CLKS_PER_BIT);
    
    parameter BIT_SAMPLE_POINT = BW_BAUD_COUNTER'($rtoi($ceil(CLKS_PER_BIT/2))); //real to int conversion added
    
    reg [1:0] next_state, state;

    reg [BW_COUNTER-1:0] next_receive_counter, receive_counter;

    reg [BW_BAUD_COUNTER-1:0] next_baud_counter, baud_counter;

    reg [DATA_LEN-1:0] next_received_data, received_data;

    reg next_strobe;

    reg [DATA_LEN-1:0] next_bit_counter, bit_counter; //???

    genvar j;
    wire sync_out[N_SYNCS-1:0];
    wire rx_sync;

    generate
        for(j = 0; j < N_SYNCS; j = j+1)
            begin: Gen_DFlipFlops
                DFlipFlop #() DFlipFlop_Instance(
                    clk_i, rst_i,
                    sync_out[j]
            );
        end
    endgenerate

    assign rx_sync = sync_out[N_SYNCS-1];
    assign data_o = received_data;


    always @(posedge clk_i ) begin
        if (rst_i == 1'b1) begin
            state <= IDLE;
            data_valid_strb_o <= 1'b0;
            receive_counter <= {BW_COUNTER{1'b0}};
            baud_counter <= {BW_BAUD_COUNTER{1'b0}};
            received_data <= {DATA_LEN{1'b0}};
            bit_counter <= {DATA_LEN{1'b0}}; //???
        end else begin
            state <= next_state;
            data_valid_strb_o <= next_strobe;
            receive_counter <= next_receive_counter;
            baud_counter <= next_baud_counter;
            received_data <= next_received_data;
            bit_counter <= next_bit_counter; //???
        end
    end

    always @(state, received_data, rx_sync, baud_counter, bit_counter) begin
        next_state <= state;
	    next_received_data <= received_data;
	    next_strobe <= 1'b0;
        next_bit_counter <= bit_counter;

        case (state)
            IDLE: begin
		        if (rx_sync == 1'b0) 
                    next_state <= STARTBIT;
            end
            STARTBIT: begin
                if (baud_counter == BIT_SAMPLE_POINT)
                    next_state <= RECEIVING;
            end 
            RECEIVING: begin
                if (baud_counter == BIT_SAMPLE_POINT) begin
                    next_receive_counter <= {rx_sync, receive_counter[DATA_LEN-1:1]};
                    next_bit_counter <= bit_counter + 1'b1;
                end

                if (bit_counter == DATA_LEN) begin
                    next_state <= STOPBIT;
                    next_bit_counter <= 0;
                end
            end
            STOPBIT: begin
                if (baud_counter == BIT_SAMPLE_POINT) begin
                    next_state <= IDLE;
                    next_strobe <= 1'b1;
                end
            end
            default: 
                    next_state <= IDLE;
        endcase
    end

    always @(baud_counter, state) begin
        next_baud_counter <= baud_counter + 1'b1;
        if (baud_counter == CLKS_PER_BIT || state == IDLE) begin
            next_baud_counter <= 0;
        end
    end

endmodule
