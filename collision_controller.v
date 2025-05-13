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

module collision_controller (
    input clk,                // Clock di sistema
    input reset,              // Reset del modulo
    
    // Posizioni attuali
    input [9:0] ball_x,       // Posizione X della palla
    input [9:0] ball_y,       // Posizione Y della palla
    input [9:0] left_racket_y,  // Posizione Y della racchetta sinistra
    input [9:0] right_racket_y, // Posizione Y della racchetta destra
    
    // Output
    output reg ball_dir_x,    // Direzione orizzontale della palla
    output reg ball_dir_y,    // Direzione verticale della palla
    output reg point_left,    // Punto per il giocatore sinistro
    output reg point_right,   // Punto per il giocatore destro
    output reg game_reset     // Segnale di reset del gioco
);

// Definizione degli stati per le collisioni orizzontali
localparam [2:0] RIGHT_SCORE = 3'b001,  // Punto per il giocatore destro
                 LEFT_SCORE  = 3'b010,  // Punto per il giocatore sinistro
                 RIGHT_HIT   = 3'b011,  // Colpito dalla racchetta destra
                 LEFT_HIT    = 3'b100,  // Colpito dalla racchetta sinistra
                 MOVE_LEFT   = 3'b101,  // Palla si muove a sinistra
                 MOVE_RIGHT  = 3'b110;  // Palla si muove a destra

// Definizione degli stati per le collisioni verticali
localparam [1:0] NO_COLLISION = 2'b00,  // Nessuna collisione
                 TOP_HIT      = 2'b01,  // Colpito il bordo superiore
                 BOTTOM_HIT   = 2'b10,  // Colpito il bordo inferiore
                 CONTINUE     = 2'b11;  // Continua il movimento

// Stati per la macchina a stati
reg [2:0] current_collision_state, next_collision_state;
reg [1:0] current_y_collision, next_y_collision;

/**
 * Funzione per rilevare collisioni verticali (con i bordi superiore e inferiore)
 * @param dir_y Direzione verticale della palla (0=giù, 1=su)
 * @return Stato della collisione verticale
 */
function automatic [1:0] vertical_collision(
    input dir_y
);
    begin
        if (ball_y == 0)  // Toccato il bordo superiore
            vertical_collision = TOP_HIT;
        else if (ball_y == (`DISPLAY_HEIGHT - `BALL_SIZE))  // Toccato il bordo inferiore
            vertical_collision = BOTTOM_HIT;
        else
            vertical_collision = (dir_y == 0) ? NO_COLLISION : CONTINUE;
    end
endfunction

/**
 * Funzione per rilevare collisioni orizzontali (con racchette e bordi laterali)
 * @param dir_x Direzione orizzontale della palla (0=sinistra, 1=destra)
 * @return Stato della collisione orizzontale
 */
function automatic [2:0] horizontal_collision(
    input dir_x
);
    begin
        if (ball_x == 0)  // Palla uscita a sinistra: punto per il giocatore destro
            horizontal_collision = RIGHT_SCORE;
        else if (ball_x == (`DISPLAY_WIDTH - `BALL_SIZE))  // Palla uscita a destra: punto per il giocatore sinistro
            horizontal_collision = LEFT_SCORE;
        else if ((ball_x == (`RACKET_LEFT_POS + `RACKET_SIZE_X)) &&  // Colpita la racchetta sinistra
               (ball_y + `BALL_SIZE >= left_racket_y) &&
               (ball_y <= left_racket_y + `RACKET_SIZE_Y))
            horizontal_collision = LEFT_HIT;
        else if ((ball_x + `BALL_SIZE == `RACKET_RIGHT_POS) &&  // Colpita la racchetta destra
               (ball_y + `BALL_SIZE >= right_racket_y) &&
               (ball_y <= right_racket_y + `RACKET_SIZE_Y))
            horizontal_collision = RIGHT_HIT;
        else
            horizontal_collision = dir_x ? MOVE_RIGHT : MOVE_LEFT;  // Continua il movimento
    end
endfunction

// Logica di gestione delle collisioni
always @(*) begin
    // Macchina a stati per le collisioni orizzontali
    case (current_collision_state)
        MOVE_RIGHT, MOVE_LEFT: begin  // Palla in movimento
            next_collision_state = horizontal_collision(ball_dir_x);
            {game_reset, point_left, point_right} = 3'b000;  // Nessun punto
            ball_dir_x = (current_collision_state == MOVE_RIGHT);  // Mantieni direzione
        end
        LEFT_SCORE, RIGHT_SCORE: begin  // Punto segnato
            next_collision_state = (current_collision_state == LEFT_SCORE) ? MOVE_LEFT : MOVE_RIGHT;
            game_reset = 1;  // Reset del gioco
            point_left = (current_collision_state == LEFT_SCORE);  // Punto sinistro
            point_right = (current_collision_state == RIGHT_SCORE);  // Punto destro
            ball_dir_x = (current_collision_state == LEFT_SCORE);  // Nuova direzione
        end
        RIGHT_HIT, LEFT_HIT: begin  // Colpita una racchetta
            next_collision_state = (current_collision_state == RIGHT_HIT) ? MOVE_LEFT : MOVE_RIGHT;
            {game_reset, point_left, point_right} = 3'b000;  // Nessun punto
            ball_dir_x = (current_collision_state == LEFT_HIT);  // Inverti direzione
        end
        default: begin  // Stato di default
            next_collision_state = current_collision_state;
            {game_reset, point_left, point_right} = 3'b000;
            ball_dir_x = ball_dir_x;
        end
    endcase

    // Macchina a stati per le collisioni verticali
    case (current_y_collision)
        NO_COLLISION, CONTINUE: begin  // Nessuna collisione o movimento normale
            next_y_collision = vertical_collision(ball_dir_y);
            ball_dir_y = (current_y_collision == CONTINUE);  // Mantieni direzione
        end
        TOP_HIT: begin  // Colpito il bordo superiore
            next_y_collision = CONTINUE;
            ball_dir_y = 1'b1;  // Inverti direzione (verso il basso)
        end
        BOTTOM_HIT: begin  // Colpito il bordo inferiore
            next_y_collision = NO_COLLISION;
            ball_dir_y = 1'b0;  // Inverti direzione (verso l'alto)
        end
        default: next_y_collision = NO_COLLISION;
    endcase
end

// Registri per gli stati
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Reset di tutti gli stati
        current_collision_state <= MOVE_RIGHT;
        current_y_collision <= NO_COLLISION;
    end else begin
        // Aggiornamento degli stati
        current_collision_state <= next_collision_state;
        current_y_collision <= next_y_collision;
    end
end

endmodule