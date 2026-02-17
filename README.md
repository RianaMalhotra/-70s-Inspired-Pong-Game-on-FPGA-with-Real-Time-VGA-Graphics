# -70s-Inspired-Pong-Game-on-FPGA-with-Real-Time-VGA-Graphics
Hardware-Accelerated Real-Time VGA Graphics on DE1-SoC

A fully hardware-implemented 2-player Pong game built on the Intel Cyclone V SoC (DE1-SoC FPGA board) using Verilog HDL. The system renders a deterministic, clock-driven game engine with real-time 640×480 @ 60 Hz VGA output, keyboard-controlled paddles, and FSM-based collision logic — all implemented entirely in hardware.

The system renders a live game environment where a ball continuously moves and interacts with paddles under deterministic, clock-driven control logic.

Player inputs are captured via keyboard interfaced to the FPGA, and processed through paddle control modules to enable low-latency real-time movement. The game engine includes finite state machine (FSM)-based collision handling, boundary reflection, dynamic position tracking, and score state management.

The VGA pipeline generates 640×480 @ 60 Hz video output, rendering paddles, ball motion, and scores directly in hardware - demonstrating strong proficiency in digital logic design, synchronous systems, and FPGA-based graphics rendering.

# 📌 System Overview

This project demonstrates a fully synchronous digital system integrating:
* VGA timing generation
* Real-time graphics rendering pipeline
* Finite State Machine (FSM)-driven game engine
* Deterministic collision detection
* Keyboard (PS/2) input interface
* Score state management
* Unlike software-based implementations, all rendering, physics, and control logic execute directly on FPGA fabric, ensuring cycle-accurate timing and zero OS latency.

# 🏗️ Hardware Platform
* Board: Terasic DE1-SoC
* FPGA: Intel Cyclone V SoC
* Toolchain: Intel Quartus Prime
* HDL: Verilog
* Display Output: VGA 640×480 @ 60 Hz
* Input Interface: PS/2 Keyboard
