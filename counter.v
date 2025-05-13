module counter #(parameter WIDTH = 10) (
    input clk,       // Clock di ingresso
    input reset,     // Reset sincrono
    input inc,       // Segnale di abilitazione all'incremento
    output reg [WIDTH-1:0] out  // Uscita del contatore
);

always @(posedge clk) begin
    if (reset)        // Priorità al reset
        out <= {WIDTH{1'b0}};
    else if (inc)     // Incremento condizionale esplicito
        out <= out + 1'b1;
end

endmodule