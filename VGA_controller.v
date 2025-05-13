module VGA_controller (
    input clk,          // Segnale di clock (25.175 MHz)
    input reset,        // Reset sincrono
    output reg VGA_HS,  // Sincronizzazione orizzontale (attiva bassa)
    output reg VGA_VS,  // Sincronizzazione verticale (attiva bassa)
    output wire VGA_BLANK_N, // Segnale blanking (sempre attivo)
    output wire VGA_SYNC_N,  // Sincronizzazione (disabilitata)
    output wire VGA_CLK,     // Clock VGA (pass-through)
    output reg display_enable,    // Abilita disegno quando in active area
    output [9:0] x, y   // Coordinate pixel corrente (0-639, 0-479)
);

    // Assegnazioni fisse per segnali VGA
    assign VGA_BLANK_N = 1'b1;  // Blanking sempre disabilitato
    assign VGA_SYNC_N  = 1'b0;   // Sincronizzazione normale
    assign VGA_CLK     = clk;    // Clock diretto

    // Parametri temporali VERTICALI (linee totali: 525)
    parameter V_VISIBLE  = 480;  // Linee visibili (0-479)
    parameter V_PORCH_F  = 490;  // Fine active area (480-489)
    parameter V_PULSE    = 492;  // Front porch + sync pulse (490-491)
    parameter V_PORCH_B  = 525;  // Back porch (492-524)

    // Parametri temporali ORIZZONTALI (pixel totali: 799)
    parameter H_VISIBLE  = 640;  // Pixel visibili (0-639)
    parameter H_PORCH_F  = 655;  // Fine active area (640-654)
    parameter H_PULSE    = 750;  // Front porch + sync pulse (655-749)
    parameter H_PORCH_B  = 798;  // Back porch (750-797)

    // Stati FSM verticale
    parameter [1:0] V_STATE_PULSE  = 2'd0,  // Sync pulse (2 linee)
                    V_STATE_BPORCH = 2'd1,  // Back porch (33 linee)
                    V_STATE_ACTIVE = 2'd2, // Active video (480 linee)
                    V_STATE_FPORCH = 2'd3;  // Front porch (10 linee)

    // Stati FSM orizzontale
    parameter [1:0] H_STATE_PULSE  = 2'd0,  // Sync pulse (96 pixel)
                    H_STATE_BPORCH = 2'd1,  // Back porch (48 pixel)
                    H_STATE_ACTIVE = 2'd2, // Active video (640 pixel)
                    H_STATE_FPORCH = 2'd3;  // Front porch (16 pixel)

    // Registri di stato
    reg [1:0] curr_h_state, next_h_state, curr_v_state, next_v_state;
    
    // Contatori posizione
    wire [9:0] h_pos, v_pos;
    wire h_inc = 1'b1;  // Incrementa ogni ciclo
    reg v_inc, h_rst, v_rst;

    // Collegamento uscite coordinate
    assign x = h_pos;  // Posizione X corrente
    assign y = v_pos;  // Posizione Y corrente

    // Contatore orizzontale (pixel/linea)
    counter horizontal_counter (
        .clk(clk),
        .reset(reset | h_rst),  // Reset a fine linea
        .inc(h_inc),
        .out(h_pos)
    );

    // Contatore verticale (linee/frame)
    counter vertical_counter (
        .clk(clk),
        .reset(reset | v_rst),  // Reset a fine frame
        .inc(v_inc),
        .out(v_pos)
    );

    // Logica combinatoria
    always @(*) begin
        // Default
        v_inc = 0;
        h_rst = 0;
        v_rst = 0;
        
        // Reset contatore orizzontale e incremento verticale
        if (h_pos == H_PORCH_B - 1) begin
            h_rst = 1;
            v_inc = 1;
            v_rst = (v_pos == V_PORCH_B - 1);  // Reset verticale
        end

        // Transizioni stati VERTICALI
        case (curr_v_state)
            V_STATE_PULSE:  next_v_state = (v_pos == V_PULSE - 1)  ? V_STATE_BPORCH : V_STATE_PULSE;
            V_STATE_BPORCH:  next_v_state = (v_pos == V_PORCH_B - 1)  ? V_STATE_ACTIVE : V_STATE_BPORCH;
            V_STATE_ACTIVE: next_v_state = (v_pos == V_VISIBLE - 1) ? V_STATE_FPORCH : V_STATE_ACTIVE;
            V_STATE_FPORCH: next_v_state = (v_pos == V_PORCH_F - 1) ? V_STATE_PULSE  : V_STATE_FPORCH;
            default:    next_v_state = V_STATE_PULSE;
        endcase

        // Transizioni stati ORIZZONTALI
        case (curr_h_state)
            H_STATE_PULSE:  next_h_state = (h_pos == H_PULSE - 1)  ? H_STATE_BPORCH  : H_STATE_PULSE;
            H_STATE_BPORCH:  next_h_state = (h_pos == H_PORCH_B - 1)  ? H_STATE_ACTIVE : H_STATE_BPORCH;
            H_STATE_ACTIVE: next_h_state = (h_pos == H_VISIBLE - 1) ? H_STATE_FPORCH : H_STATE_ACTIVE;
            H_STATE_FPORCH: next_h_state = (h_pos == H_PORCH_F - 1) ? H_STATE_PULSE  : H_STATE_FPORCH;
            default:    next_h_state = H_STATE_PULSE;
        endcase
    end

    // Logica sequenziale
    always @(posedge clk) begin
        if (reset) begin
            curr_h_state <= H_STATE_ACTIVE;  // Stato iniziale orizzontale
            curr_v_state <= V_STATE_ACTIVE;  // Stato iniziale verticale
            {VGA_HS, VGA_VS} <= 2'b11; // Sync attivi bassi
            display_enable <= 0;           // Disabilitazione disegno
        end else begin
            curr_h_state <= next_h_state;  // Aggiornamento stato orizzontale
            if (h_rst)
                curr_v_state <= next_v_state; // Aggiornamento verticale solo a fine linea
            
            // Generazione segnali sync (attivi bassi)
            VGA_HS <= (curr_h_state == H_STATE_PULSE);
            VGA_VS <= (curr_v_state == V_STATE_PULSE);
            
            // Abilita disegno solo in active area
            display_enable <= (curr_h_state == H_STATE_ACTIVE) && (curr_v_state == V_STATE_ACTIVE);
        end
    end

endmodule