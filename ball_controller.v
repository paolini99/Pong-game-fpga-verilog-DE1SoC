// Parametri di gioco globali
`define BALL_SIZE 15        // Dimensione della palla (lato quadrato)
`define DISPLAY_HEIGHT 479   // Altezza schermo (480 pixel - 1)
`define DISPLAY_WIDTH 639    // Larghezza schermo (640 pixel - 1)
`define BALL_VELOCITY 16    // Velocità palla (maggiore = più lenta)

module ball_controller (
    input clk,              // Segnale di clock
    input reset,           // Segnale di reset
    input dir_horiz,       // Direzione orizzontale (1=destra, 0=sinistra)
    input dir_vert,        // Direzione verticale (1=giù, 0=su)
    output [9:0] x,        // Posizione X corrente della palla
    output [9:0] y         // Posizione Y corrente della palla
);

    //=============================================
    // Controllo velocità movimento
    //=============================================
    wire [(`BALL_VELOCITY-1):0] velocity_counter_out;
    wire move_active = (velocity_counter_out == 0);  // Abilita movimento quando il contatore è a zero
    
    //=============================================
    // Logica di movimento direzionale
    //=============================================
    wire go_right = move_active & dir_horiz;  // Muovi a destra
    wire go_left  = move_active & ~dir_horiz; // Muovi a sinistra
    wire go_down  = move_active & dir_vert;   // Muovi in basso
    wire go_up    = move_active & ~dir_vert;  // Muovi in alto

    //=============================================
    // Contatori di posizione X/Y
    //=============================================
    bidir_counter position_x (
        .clk(clk),                  // Clock
        .reset(reset),              // Reset posizione
        .initial_val(10'd320),      // Posizione X iniziale (centro schermo)
        .max_threshold(`DISPLAY_WIDTH - `BALL_SIZE), // Limite destro (639 - 15)
        .inc(go_right),             // Incrementa posizione quando ci si muove a destra
        .dec(go_left),              // Decrementa posizione quando ci si muove a sinistra
        .count(x)                   // Output posizione X
    );

    bidir_counter position_y (
        .clk(clk),                  // Clock
        .reset(reset),              // Reset posizione
        .initial_val(10'd240),      // Posizione Y iniziale (centro schermo)
        .max_threshold(`DISPLAY_HEIGHT - `BALL_SIZE), // Limite inferiore (479 - 15)
        .inc(go_down),              // Incrementa posizione quando ci si muove in basso
        .dec(go_up),                // Decrementa posizione quando ci si muove in alto
        .count(y)                   // Output posizione Y
    );

    //=============================================
    // Contatore di velocità usando modulo esterno
    //=============================================
    counter #(
        .WIDTH(`BALL_VELOCITY)
    ) velocity_counter (
        .clk(clk),
        .reset(reset),
        .inc(1'b1),                 // Incrementa sempre ad ogni ciclo di clock
        .out(velocity_counter_out)
    );

endmodule