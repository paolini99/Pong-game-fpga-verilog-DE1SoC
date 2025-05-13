// Parametri di gioco
`define MOVE_SPEED         15   // Bit per divisore frequenza

// Gestione input con antirimbalzo e rate limiting
module player_control(
    input  clk,     // Clock sistema
    input  reset,   // Reset modulo
    input  raw_input,      // Segnale input grezzo
    output reg filtered_out  // Segnale filtrato
);
    
    wire [`MOVE_SPEED-1:0] speed_div;  // Divisore di frequenza

    // Contatore per rallentare l'input
    counter #(.WIDTH(`MOVE_SPEED)) div (
        .clk(clk),
        .reset(reset),
        .inc(1'b1),    // Incremento continuo
        .out(speed_div)
    );

    // Abilita output solo a divisore azzerato
    always @(*) begin
        filtered_out = (speed_div == 0) && raw_input;  // Combina controllo frequenza e stato input
    end
    
endmodule
