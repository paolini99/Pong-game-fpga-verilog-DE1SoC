// I segmenti sono attivi bassi (0 = acceso, 1 = spento)
module seven_seg (
    input [3:0] value,    // Valore da visualizzare (0-9)
    output reg [6:0] HEX  // Uscita per i segmenti
);
    always @(*) begin
        case(value)
            4'd0: HEX = 7'b1000000; // 0
            4'd1: HEX = 7'b1111001; // 1
            4'd2: HEX = 7'b0100100; // 2
            4'd3: HEX = 7'b0110000; // 3
            4'd4: HEX = 7'b0011001; // 4
            4'd5: HEX = 7'b0010010; // 5
            4'd6: HEX = 7'b0000010; // 6
            4'd7: HEX = 7'b1111000; // 7
            4'd8: HEX = 7'b0000000; // 8
            4'd9: HEX = 7'b0010000; // 9
            default: HEX = 7'b1000000; // Default 0
        endcase
    end
endmodule