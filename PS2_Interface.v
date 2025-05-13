module PS2_Interface (
    // Segnali di ingresso e uscita (solo ricezione)
    input           clk,        // Clock principale di sistema
    input           rst_n,      // Reset attivo basso
    inout           ps2_clk,    // Linea di clock PS/2 (alta impedenza)
    inout           ps2_data,   // Linea dati PS/2 (alta impedenza)
    output  [7:0]   rx_data,    // Byte di dati ricevuto
    output          rx_valid    // Segnale di validità dei dati
);

    // ==============================================
    // Definizione degli stati 
    // ==============================================
    localparam  STATE_IDLE     = 2'b01,  // In attesa del bit di start
                STATE_RX_DATA  = 2'b10;  // Ricezione dei bit di dati

    // ==============================================
    // Registri principali e segnali di controllo
    // ==============================================
    reg     [1:0]   state;          // Stato corrente della FSM
    reg     [1:0]   clk_detect;     // Per il rilevamento del fronte del clock
    reg             dat_sync;       // Sincronizzazione dell’ingresso dati
    wire            clk_pos_edge;   // Rilevamento del fronte di salita del clock PS/2
    wire            rx_start;       // Segnale di inizio ricezione dati

	 
	 
    assign ps2_clk = 1'bz;    // Non pilotare mai la linea di clock
    assign ps2_data = 1'bz;   // Non pilotare mai la linea dati

    // ==============================================
    // Rilevamento del fronte del clock
    // ==============================================
    assign clk_pos_edge = (clk_detect == 2'b01);  // Rileva transizione 1->0

    // Segnale di inizio ricezione (attivo durante lo stato RX_DATA)
    assign rx_start = state[1]; // RX_DATA corrisponde a 2'b10

    // ==============================================
    // Sincronizzazione degli ingressi (clock e dati)
    // ==============================================
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset dei registri di sincronizzazione
            clk_detect <= 2'b11;
            dat_sync <= 1'b1;
        end
        else begin
            // Sincronizza clock e dati PS/2 con il clock di sistema
            clk_detect <= {clk_detect[0], ps2_clk};
            dat_sync <= ps2_data;
        end
    end


    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset allo stato IDLE
            state <= STATE_IDLE;
        end
        else begin
            case (state)
                STATE_IDLE: begin
                    // Attende il bit di start (basso) al fronte di clock
                    if ((dat_sync == 1'b0) && clk_pos_edge)
                        state <= STATE_RX_DATA;
                end
                
                STATE_RX_DATA: begin
                    // Torna a IDLE quando la ricezione è completata
                    if (rx_valid)
                        state <= STATE_IDLE;
                end
                
                default: state <= STATE_IDLE;
            endcase
        end
    end

    // ==============================================
    // Istanziazione del ricevitore PS/2
    // ==============================================
    PS2_Receiver PS2_Receiver_Inst (
        .clk(clk),              // Clock di sistema
        .reset(!rst_n),         // Reset attivo alto
        .rx_wait(1'b0),         // Sempre disabilitato (nessun controllo di flusso)
        .rx_start(rx_start),    // Segnale di inizio ricezione
        .clk_edge(clk_pos_edge),// Rilevamento del fronte del clock
        .ps2_data(dat_sync),    // Ingresso dati sincronizzato
        .rx_data(rx_data),      // Uscita dati ricevuti
        .rx_ready(rx_valid)     // Segnale di validità dei dati
    );

endmodule