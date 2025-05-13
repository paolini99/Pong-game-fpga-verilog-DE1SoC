// Modulo per controllare gioco in base a tasti freccia della tastiera PS/2
module keyboard_control (
    input        clk,         // Segnale di clock
    input        reset_n,     // Reset attivo basso
    inout        ps2_clk,     // Clock linea PS/2 (bidirezionale)
    inout        ps2_dat,     // Dati linea PS/2 (bidirezionale)
    output       p_up,      // LED per freccia su (attivo alto)
    output       p_down     // LED per freccia giù (attivo alto)
);

    // === Costanti e parametri ===
    localparam IDLE     = 2'b00;  // Stato di attesa
    localparam EXTENDED = 2'b01;  // Ricezione codice esteso (E0)
    localparam BREAK    = 2'b10;  // Ricezione codice di rilascio (F0)
    
    localparam PS2_EXTENDED = 8'hE0;   // Codice per tasto esteso
    localparam PS2_BREAK    = 8'hF0;   // Codice di rilascio tasto
    localparam PS2_UP       = 8'h75;   // Codice freccia su
    localparam PS2_DOWN     = 8'h72;   // Codice freccia giù

    // === Segnali interni ===
    wire [7:0] ps2_data;      // Dati ricevuti dalla tastiera
    wire       ps2_data_en;   // Abilita dati (1 quando nuovi dati disponibili)

    // Registri per stato FSM e tasti
    reg [1:0]  state;         // Stato corrente FSM
    reg        extended;      // Flag per tasti estesi
    reg        arrow_up;      // Registro stato freccia su
    reg        arrow_down;    // Registro stato freccia giù

    // === Istanza controller PS/2 ===
    PS2_Interface ps2_ctrl (
        .clk(clk),              
        .rst_n(reset_n),               
        .ps2_clk(ps2_clk),      
        .ps2_data(ps2_dat),     
        .rx_data(ps2_data),     
        .rx_valid(ps2_data_en)  
    );

    // === Macchina a stati per elaborazione scancode ===
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset di tutti i registri
            state     <= IDLE;
            extended  <= 1'b0;
            arrow_up  <= 1'b0;
            arrow_down<= 1'b0;
        end 
        else if (ps2_data_en) begin  // Processa solo quando ci sono nuovi dati
            case (state)
                IDLE: begin
                    if (ps2_data == PS2_EXTENDED) begin
                        extended <= 1'b1;
                        state <= EXTENDED;
                    end
                    else if (ps2_data == PS2_BREAK) begin
                        state <= BREAK;
                    end
                    // Tutti gli altri tasti in IDLE sono ignorati
                end
                
                EXTENDED: begin
                    if (ps2_data == PS2_BREAK) begin
                        state <= BREAK;
                    end
                    else begin
                        // Gestione pressione tasti freccia
                        case (ps2_data)
                            PS2_UP:    arrow_up   <= 1'b1;
                            PS2_DOWN:  arrow_down <= 1'b1;
                            default: ; // Non fa nulla per altri tasti estesi
                        endcase
                        extended <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                BREAK: begin
                    if (extended) begin
                        case (ps2_data)
                            PS2_UP:    arrow_up   <= 1'b0;
                            PS2_DOWN:  arrow_down <= 1'b0;
                            default: ; // Non fa nulla per altri tasti estesi
                        endcase
                    end
                    extended <= 1'b0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;  // Recupero da stati non previsti
            endcase
        end
    end

    // Connessione diretta degli stati ai LED
    assign p_up   = arrow_up;
    assign p_down = arrow_down;

endmodule