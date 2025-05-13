module PS2_Receiver (
    input               clk,        // Clock di sistema
    input               reset,      // Reset sincrono
    input               rx_wait,    // Modalità attesa
    input               rx_start,   // Avvio ricezione
    input               clk_edge,   // Fronte di clock PS/2
    input               ps2_data,   // Dati PS/2
    output reg  [7:0]   rx_data,    // Dati ricevuti
    output reg          rx_ready    // Dati pronti (pulse)
);

    // Stati della FSM (one-hot encoding)
    localparam  RX_IDLE     = 5'b00001, // Stato di idle
                RX_WAIT     = 5'b00010, // Attesa dato
                RX_RECEIVE  = 5'b00100, // Ricezione bit dati
                RX_PARITY   = 5'b01000, // Ricezione bit di parità
                RX_STOP     = 5'b10000; // Ricezione bit di stop

    // Registri interni
    reg     [4:0]   state;          // Stato corrente FSM (one-hot)
    reg     [3:0]   bit_count;      // Contatore bit ricevuti (0-7)
    reg     [7:0]   shift_reg;      // Registro a scorrimento per accumulo dati

    // Macchina a stati finiti (FSM) principale
    always @(posedge clk) begin
        if (reset) begin
            // Reset sincrono
            state <= RX_IDLE;
            bit_count <= 4'h0;
            shift_reg <= 8'h00;
            rx_data <= 8'h00;
            rx_ready <= 1'b0;
        end
        else begin
            // Default: rx_ready è attivo solo per un ciclo di clock
            rx_ready <= 1'b0;
            
            // Implementazione one-hot 
            case (1'b1) // Sintassi one-hot
                
                // Stato IDLE - Attesa comando
                state[0]: begin // RX_IDLE
                    bit_count <= 4'h0;
                    if (rx_wait && !rx_ready)
                        state <= RX_WAIT;       // Passa a WAIT se richiesto
                    else if (rx_start && !rx_ready)
                        state <= RX_RECEIVE;    // Passa a RECEIVE se start
                end
                
                // Stato WAIT - Attesa dato (controlla linea dati)
                state[1]: begin // RX_WAIT
                    if (ps2_data == 1'b0 && clk_edge)
                        state <= RX_RECEIVE;    // Inizia ricezione quando dato basso
                    else if (!rx_wait)
                        state <= RX_IDLE;       // Torna a IDLE se non più in attesa
                end
                
                // Stato RECEIVE - Ricezione bit dati
                state[2]: begin // RX_RECEIVE
                    if (clk_edge) begin
                        // Shift del bit ricevuto nel registro
                        shift_reg <= {ps2_data, shift_reg[7:1]};
                        bit_count <= bit_count + 4'h1;
                        
                        if (bit_count == 4'h7)
                            state <= RX_PARITY; // Dopo 8 bit passa a PARITY
                    end
                end
                
                // Stato PARITY - Ricezione bit di parità (non verificato)
                state[3]: begin // RX_PARITY
                    if (clk_edge)
                        state <= RX_STOP;       // Passa a STOP
                end
                
                // Stato STOP - Ricezione bit di stop
                state[4]: begin // RX_STOP
                    if (clk_edge) begin
                        rx_data <= shift_reg;  // Salva dato ricevuto
                        rx_ready <= 1'b1;      // Segnala dato pronto
                        state <= RX_IDLE;      // Torna a IDLE
                    end
                end
                
                // Default per stati non validi
                default: state <= RX_IDLE;
            endcase
        end
    end
endmodule