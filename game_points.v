// Modulo principale per la gestione del punteggio del gioco
module game_points (
    input clk,               // Segnale di clock
    input reset,             // Segnale di reset
    input player_right_scores,         // Segnale vittoria giocatore destro
    input player_left_scores,          // Segnale vittoria giocatore sinistro
    output [6:0] HEX5,       // Display 7-segmenti per decine sinistra
    output [6:0] HEX4,       // Display 7-segmenti per unità sinistra
    output [6:0] HEX1,       // Display 7-segmenti per decine destra
    output [6:0] HEX0        // Display 7-segmenti per unità destra
);
    // Registri per edge detection
    reg right_player_total, left_player_total;
    wire right_pulse, left_pulse;  // Impulsi di vittoria puliti
    
    // Contatori BCD (Binary-Coded Decimal)
    reg [3:0] right_tens;    // Decine giocatore destro (0-9)
    reg [3:0] right_ones;    // Unitá giocatore destro (0-9)
    reg [3:0] left_tens;     // Decine giocatore sinistro (0-9)
    reg [3:0] left_ones;     // Unitá giocatore sinistro (0-9)

    // Logica per rilevare il fronte di salita dei segnali di vittoria
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset dei registri di stato precedente
            right_player_total <= 0;
            left_player_total <= 0;
        end else begin
            // Aggiornamento dello stato precedente
            right_player_total <= player_right_scores;
            left_player_total <= player_left_scores;
        end
    end
    
    // Generazione impulsi di durata 1 ciclo di clock
    assign right_pulse = player_right_scores && !right_player_total;  // Impulso giocatore destro
    assign left_pulse = player_left_scores && !left_player_total;      // Impulso giocatore sinistro

    // Contatore punteggio giocatore destro
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset contatori
            right_tens <= 4'd0;
            right_ones <= 4'd0;
        end else if (right_pulse) begin
            // Blocco a 99 punti
            if (right_tens == 4'd9 && right_ones == 4'd9) begin
                right_tens <= right_tens;
                right_ones <= right_ones;
            end else begin
                if (right_ones == 4'd9) begin
                    // Incremento decine e reset unità
                    right_ones <= 4'd0;
                    right_tens <= right_tens + 1;
                end else begin
                    // Incremento unità
                    right_ones <= right_ones + 1;
                end
            end
        end
    end

    // Contatore punteggio giocatore sinistro (logica identica al destro)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            left_tens <= 4'd0;
            left_ones <= 4'd0;
        end else if (left_pulse) begin
            if (left_tens == 4'd9 && left_ones == 4'd9) begin
                left_tens <= left_tens;
                left_ones <= left_ones;
            end else begin
                if (left_ones == 4'd9) begin
                    left_ones <= 4'd0;
                    left_tens <= left_tens + 1;
                end else begin
                    left_ones <= left_ones + 1;
                end
            end
        end
    end

    // Collegamento display 7-segmenti:
    // - Giocatore destro: HEX1 (decine) e HEX0 (unitá)
    // - Giocatore sinistro: HEX5 (decine) e HEX4 (unitá)
    seven_seg right_lower_display (.value(right_ones), .HEX(HEX0));
    seven_seg right_upper_display (.value(right_tens), .HEX(HEX1));
    seven_seg left_lower_display  (.value(left_ones),  .HEX(HEX4));
    seven_seg left_upper_display  (.value(left_tens),  .HEX(HEX5));

endmodule


