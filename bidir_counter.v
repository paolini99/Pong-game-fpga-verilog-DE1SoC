module bidir_counter #(
    parameter BIT_WIDTH = 10  // Larghezza standard del contatore (10 bit)
) (
    input clk,               // Segnale di temporizzazione
    input reset,             // Reset sincrono (carica 'initial_val')
    input [BIT_WIDTH-1:0] initial_val,    // Valore dopo reset
    input [BIT_WIDTH-1:0] max_threshold,  // Valore massimo raggiungibile
    input inc,               // Comando incremento (priorità alta)
    input dec,               // Comando decremento (priorità bassa)
    output reg [BIT_WIDTH-1:0] count      // Uscita contatore
);

    always @(posedge clk) begin
        if (reset) begin
            // Reset: carica valore iniziale
            count <= initial_val;
        end else begin
            // Logica di controllo 
            case ({inc, dec})
                2'b10: begin // Modalità incremento
                    if (count < max_threshold) begin
                        // Incremento normale
                        count <= count + 1'b1;
                    end
                end
                
                2'b01: begin // Modalità decremento
                    if (count > 0) begin
                        // Decremento standard
                        count <= count - 1'b1;
                    end
                end
                
                default: begin
                    // Nessun comando: mantiene stato
                    count <= count;
                end
            endcase
        end
    end
endmodule