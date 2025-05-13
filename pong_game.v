 // =============================================
// Parametri di configurazione del gioco
// =============================================

// Dimensioni della racchetta (larghezza x altezza)
`define RACKET_SIZE_X 10
`define RACKET_SIZE_Y 70

// Posizione fissa delle racchette (sinistra e destra)
`define RACKET_LEFT_POS 40
`define RACKET_RIGHT_POS 599

// Dimensioni della palla (diametro)
`define BALL_SIZE 15

// Dimensioni dello schermo
`define DISPLAY_HEIGHT 479
`define DISPLAY_WIDTH 639

// Velocità di movimento delle racchette
`define MOVE_SPEED 15

// Velocità della palla
`define BALL_VELOCITY 16

// Offset per l'AI (quanto anticipare il movimento)
`define AI_OFFSET 20


module pong_game (
    // Input di clock e reset
    input clk, 
    input reset,
    
    // Output VGA
    output VGA_HS, 
    output VGA_VS, 
    output reg [7:0] VGA_R,    // Canale rosso
    output reg [7:0] VGA_G,    // Canale verde
    output reg [7:0] VGA_B,    // Canale blu
    
    // Input da tastiera e switch
    input [3:0] KEY,           // Tasti per controllare le racchette
    input [8:0] SW,            // Switch per configurazioni
    
    // Display a 7 segmenti per il punteggio
    output [6:0] HEX0,         // Unità punteggio sinistro
    output [6:0] HEX1,         // Decine punteggio sinistro
    output [6:0] HEX4,         // Unità punteggio destro
    output [6:0] HEX5,         // Decine punteggio destro
    
    // Segnali aggiuntivi VGA
    output VGA_BLANK_N, 
    output VGA_SYNC_N, 
    output VGA_CLK,
    
    // Input alternativi per le racchette
    input up,                  // Muovi racchetta sinistra su
    input down                 // Muovi racchetta sinistra giù
);


// =============================================
// Segnali e variabili del gioco
// =============================================

// Coordinate del pixel corrente
wire [9:0] pixel_x, pixel_y;
wire video_on;  // Segnale che indica quando disegnare

// Istanza del controller VGA
VGA_controller video_output (
    .clk(clk), 
    .reset(reset), 
    .VGA_HS(VGA_HS), 
    .VGA_VS(VGA_VS),
    .x(pixel_x), 
    .y(pixel_y), 
    .display_enable(video_on),
    .VGA_BLANK_N(VGA_BLANK_N), 
    .VGA_SYNC_N(VGA_SYNC_N), 
    .VGA_CLK(VGA_CLK)
);

// Segnali per il disegno degli oggetti
reg draw_right_racket, draw_left_racket, draw_ball;

// Posizioni verticali delle racchette
reg [9:0] left_racket_y, right_racket_y;
wire [9:0] left_racket_pos, right_racket_pos;

// Segnali per il controllo del gioco
wire game_reset;  // Reset del gioco (dopo un punto)
wire [9:0] ball_x, ball_y;  // Posizione della palla
wire ball_dir_x, ball_dir_y; // Direzione della palla (0=sinistra/giù, 1=destra/su)
wire point_right, point_left; // Segnali di punto segnato

// Stati per la macchina a stati
reg current_draw_state, next_draw_state;
reg [1:0] current_ai_state, next_ai_state;

// Modulo per la gestione del punteggio
game_points score (
    .clk(clk), 
    .reset(reset),
    .player_right_scores(point_right), 
    .player_left_scores(point_left),
    .HEX5(HEX5), 
    .HEX4(HEX4), 
    .HEX1(HEX1), 
    .HEX0(HEX0)
);

// Istanza del modulo di gestione delle collisioni
collision_controller collision_handler (
    .clk(clk), 
    .reset(reset),
    .ball_x(ball_x),
    .ball_y(ball_y),
    .left_racket_y(left_racket_y),
    .right_racket_y(right_racket_y),
    .ball_dir_x(ball_dir_x),
    .ball_dir_y(ball_dir_y),
    .point_left(point_left),
    .point_right(point_right),
    .game_reset(game_reset)
);

// Segnali per il controllo delle racchette
wire right_up, right_down, left_up, left_down;
reg ai_right_up, ai_right_down;  // Controlli AI per la racchetta destra
wire [18:0] clock_divider;       // Divisore di clock

// Filtri per gli input dei giocatori (anti-rimbalzo)
player_control right_up_ctrl (.clk(clk), .reset(reset), .raw_input(~KEY[0] | ai_right_up), .filtered_out(right_up));
player_control right_down_ctrl (.clk(clk), .reset(reset), .raw_input(~KEY[1] | ai_right_down), .filtered_out(right_down));
player_control left_up_ctrl (.clk(clk), .reset(reset), .raw_input(~KEY[2] | up), .filtered_out(left_up));
player_control left_down_ctrl (.clk(clk), .reset(reset), .raw_input(~KEY[3] | down), .filtered_out(left_down));

// Contatori per il movimento delle racchette
bidir_counter right_racket_movement (
    .clk(clk), 
    .reset(reset | game_reset),
    .initial_val(`DISPLAY_HEIGHT / 2),  // Posizione iniziale al centro
    .max_threshold(`DISPLAY_HEIGHT - `RACKET_SIZE_Y),  // Limite inferiore
    .inc(right_down),  // Muovi giù
    .dec(right_up),    // Muovi su
    .count(right_racket_pos)  // Posizione corrente
);

bidir_counter left_racket_movement (
    .clk(clk), 
    .reset(reset | game_reset),
    .initial_val(`DISPLAY_HEIGHT / 2),  // Posizione iniziale al centro
    .max_threshold(`DISPLAY_HEIGHT - `RACKET_SIZE_Y),  // Limite inferiore
    .inc(left_down),  // Muovi giù
    .dec(left_up),    // Muovi su
    .count(left_racket_pos)  // Posizione corrente
);

// Divisore di clock per rallentare il gioco
counter #(.WIDTH(19)) clock_div (
    .clk(clk), 
    .reset(reset), 
    .inc(1'b1), 
    .out(clock_divider)
);

// Controller per il movimento della palla
ball_controller ball_control (
    .clk(clk), 
    .reset(reset | game_reset),
    .x(ball_x),       // Posizione X della palla
    .y(ball_y),       // Posizione Y della palla
    .dir_horiz(ball_dir_x),  // Direzione orizzontale
    .dir_vert(ball_dir_y)    // Direzione verticale
);

// Registri per le posizioni delle racchette
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Reset delle posizioni al centro
        right_racket_y <= `DISPLAY_HEIGHT / 2;
        left_racket_y <= `DISPLAY_HEIGHT / 2;
    end else begin
        // Aggiorna le posizioni
        right_racket_y <= right_racket_pos;
        left_racket_y <= left_racket_pos;
    end
end

// =============================================
// Funzioni di supporto
// =============================================

/**
 * Funzione per disegnare un oggetto (racchetta o palla)
 * @param pos_x Posizione X dell'oggetto
 * @param pos_y Posizione Y dell'oggetto
 * @param size_x Larghezza dell'oggetto
 * @param size_y Altezza dell'oggetto
 * @param is_ball Se 1, disegna un cerchio (palla), altrimenti un rettangolo (racchetta)
 * @return 1 se il pixel corrente è dentro l'oggetto, 0 altrimenti
 */
function automatic draw_object(
    input [9:0] pos_x, 
    input [9:0] pos_y, 
    input [9:0] size_x, 
    input [9:0] size_y,
    input is_ball
);
    begin
        if (is_ball) begin
            // Disegna un cerchio per la palla
            integer radius = size_x / 2;
            integer center_x = pos_x + radius;
            integer center_y = pos_y + radius;
            integer dx = (pixel_x > center_x) ? pixel_x - center_x : center_x - pixel_x;
            integer dy = (pixel_y > center_y) ? pixel_y - center_y : center_y - pixel_y;
            draw_object = (dx * dx + dy * dy <= radius * radius);
        end else begin
            // Disegna un rettangolo per le racchette
            draw_object = (pixel_x >= pos_x && pixel_x < pos_x + size_x &&
                          pixel_y >= pos_y && pixel_y < pos_y + size_y);
        end
    end
endfunction

/**
 * Funzione per verificare se il pixel corrente è visibile
 * @param dummy Parametro non usato (per compatibilità)
 * @return 1 se il pixel non è visibile, 0 altrimenti
 */
function automatic is_visible(
    input dummy
);
    begin
        is_visible = ~(pixel_x < `DISPLAY_WIDTH &&
                      pixel_y < `DISPLAY_HEIGHT &&
                      video_on);
    end
endfunction

/**
 * Funzione per il controllo dell'AI
 * @param dir_x Direzione orizzontale della palla (0=sinistra, 1=destra)
 * @param switches Stato degli switch per configurare l'AI
 * @return 0: nessun movimento, 1: muovi su, 2: muovi giù
 */
function automatic [1:0] ai_control(
    input dir_x,
    input [1:0] switches
);
    begin
        // L'AI è attiva solo se la palla si sta muovendo verso destra
        // e l'AI è abilitata tramite gli switch
        if (dir_x && switches[1]) begin
            // Se la palla è sopra la racchetta + offset, muovi su
            if (ball_y > (right_racket_y + `AI_OFFSET))
                ai_control = 1;  // Muovi giù
            else
                ai_control = 2;  // Muovi su
        end else
            ai_control = 0;  // Nessun movimento
    end
endfunction

// =============================================
// Logica principale del gioco
// =============================================

always @(*) begin
    // Macchina a stati per il disegno
    case (current_draw_state)
        0: begin  // Stato di disegno attivo
            next_draw_state = is_visible(1'b0);
            
            // Determina se disegnare gli oggetti
            draw_right_racket = draw_object(`RACKET_RIGHT_POS, right_racket_y, `RACKET_SIZE_X, `RACKET_SIZE_Y, 1'b0);
            draw_left_racket = draw_object(`RACKET_LEFT_POS, left_racket_y, `RACKET_SIZE_X, `RACKET_SIZE_Y, 1'b0);
            draw_ball = draw_object(ball_x, ball_y, `BALL_SIZE, `BALL_SIZE, 1'b1);

            // Selezione del colore in base alla modalità 
            if (~SW[0]) begin  // Modalità normale (bianco e nero)
                if (draw_right_racket || draw_left_racket || draw_ball)
                    {VGA_R, VGA_G, VGA_B} = 24'h000000;  // Nero per gli oggetti
                else
                    {VGA_R, VGA_G, VGA_B} = 24'hFFFFFF;  // Bianco per lo sfondo
            end else begin  // Modalità debug (a colori)
                if (draw_right_racket)
                    {VGA_R, VGA_G, VGA_B} = 24'h0000FF;  // Blu per racchetta destra
                else if (draw_left_racket)
                    {VGA_R, VGA_G, VGA_B} = 24'hFF0000;  // Rosso per racchetta sinistra
                else if (draw_ball)
                    {VGA_R, VGA_G, VGA_B} = 24'h00FF00;  // Verde per la palla
                else
                    {VGA_R, VGA_G, VGA_B} = 24'h000000;  // Nero per lo sfondo
            end
        end
        1: begin  // Stato di disegno non attivo
            next_draw_state = is_visible(1'b0);
            {VGA_R, VGA_G, VGA_B} = 24'h000000;  // Nero (fuori dall'area visibile)
            {draw_right_racket, draw_left_racket, draw_ball} = 3'b0;
        end
    endcase

    // Macchina a stati per l'AI
    case (current_ai_state)
        0: begin  // Stato di attesa
            next_ai_state = ai_control(ball_dir_x, SW);
            {ai_right_up, ai_right_down} = 2'b00;  // Nessun movimento
        end
        1: begin  // Muovi la racchetta su
            next_ai_state = ai_control(ball_dir_x, SW);
            {ai_right_up, ai_right_down} = 2'b01;  // Attiva movimento su
        end
        2: begin  // Muovi la racchetta giù
            next_ai_state = ai_control(ball_dir_x, SW);
            {ai_right_up, ai_right_down} = 2'b10;  // Attiva movimento giù
        end
        default: next_ai_state = 0;
    endcase
end

// Registri per gli stati
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Reset di tutti gli stati
        current_draw_state <= 1'b1;
        current_ai_state <= 2'b00;
    end else begin
        // Aggiornamento degli stati
        current_draw_state <= next_draw_state;
        current_ai_state <= next_ai_state;
    end
end

endmodule