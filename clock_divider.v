module clock_divider (
    input clock,              // Clock in ingresso
    output reg [15:0] divided_clocks = 0 // Uscita con 32 clock divisi (inizializzato a 0)
);

    // Incrementa il contatore a ogni fronte di salita del clock
    always @(posedge clock) begin
        divided_clocks <= divided_clocks + 1; 
        // Esempio: divided_clocks[0] cambia ogni ciclo (freq/2)
    end

endmodule