# Pong-game-fpga-verilog-DE1SoC
This project implements the classic **Pong game** using **pure digital logic** on an **FPGA board (DE1-SoC)**. The game is displayed on a **VGA monitor at 640x480 @60Hz** and is controlled via a **PS/2 keyboard** and **on-board push buttons**.

> ⚙️ No software or processors are used – the entire system is built from digital components and finite state machines.

---

## 🎯 Project Objectives

- Build a hardware-only Pong game on an FPGA.
- Render graphics in real-time via **VGA output**.
- Accept inputs from **PS/2 keyboard** and physical **push buttons**.
- Support for **2-player** and **player vs. AI** game modes.
- Display scores on the **7-segment displays**.

---

## 🕹️ Gameplay Overview

- Left paddle is controlled via **PS/2 keyboard** (W/S or arrow keys).
- Right paddle is controlled via **push buttons** on the board (or AI).
- Game output is rendered to a VGA monitor in real time.
- Scores are shown on the 7-segment displays and can be reset via a switch.
- AI for the right paddle can be enabled using an onboard switch.

---

## 🧱 System Architecture

The design is **modular**, with a `pong_game` top-level module coordinating all submodules.

### 🔧 Key Components

#### ⏱️ Clock & Timing
- `counter`: generic counter for pixel timing and delays.
- `clock_divider`: reduces master clock frequency for the game logic.
- `bidir_counter`: bidirectional counter used for paddle movement.

#### 📺 VGA Output
- `VGA_controller`: generates VGA signals (`hcounter`, `vcounter`, `HSync`, `VSync`) and manages frame timing.
- **No framebuffer**: pixels are evaluated on the fly to determine color based on game state.
- Objects drawn: ball, paddles, borders.

#### 🎹 Input System
- `PS2_Receiver`: handles low-level PS/2 protocol (synchronization, serial data).
- `PS2_Interface`: parses scan codes and generates control signals.
- `keyboard_control`: maps key presses to paddle movement.
- Push buttons: control second player paddle (when AI is off).

#### 🧠 Game Logic
- `pong_game`: top-level game controller.
- `collision_controller`: handles ball collisions with paddles and screen borders.
- `ball`: updates ball position and direction.
- `player_control`: manages paddle movement logic.
- `AI_logic`: simple AI that tracks the ball vertically.
- `game_points`: tracks and updates player scores.

#### 🔢 Score Display
- 7-segment displays show each player’s score (0–99).
- Score reset is manual via a switch.
- Score doesn't auto-reset after reaching a max.

---

## 🎮 Game Modes

| Mode            | Control             | Description                                  |
|-----------------|---------------------|----------------------------------------------|
| Player vs Player | Left: keyboard<br>Right: buttons | Manual control for both paddles.          |
| Player vs AI     | Left: keyboard<br>Right: AI     | Right paddle follows the ball's Y position. |

---

## ⚙️ Technical Highlights

- **VGA resolution**: 640x480 pixels at 60Hz refresh rate.
- **Pixel rendering**: evaluated per pixel, real-time logic – no RAM or buffers.
- **PS/2 keyboard interface**: handled through a finite state machine.
- **Input frequency scaling**: ensures readable input and smooth paddle motion.
- **Debouncing and edge detection**: for reliable button input.

---

## 🧪 Requirements

- **FPGA Board**: DE1-SoC, PS/2, and 7-segment support.
- **Monitor**: VGA-compatible.
- **Keyboard**: PS/2 (not USB).
- **Quartus Prime**: for synthesis and programming.
- **VGA + PS/2 + GPIO cables**.

---

## 🚀 How to Synthesize & Run

1. Open project in **Quartus Prime**.
2. Assign FPGA **pin constraints** (see table above).
3. Compile the project.
4. Connect the board to a **VGA monitor** and **PS/2 keyboard**.
5. Program the board via **JTAG**.
6. Play!

---
