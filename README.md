# Multi-Core Machine Learning Accelerator (Verilog Simulation)

This repository contains the complete simulation of a **multi-core machine learning accelerator** written in **Verilog** and tested using **ModelSim**. The accelerator is designed to execute **parallel CNN inference** on multiple inputs using a **shared memory-mapped interconnect** and **standard Wishbone bus architecture**.

---

## Overview

This project implements a **multi-core CNN (Convolutional Neural Network) system**, where each **CNN core** is an independent hardware pipeline consisting of:

- 🔹 Convolutional Engine  
- 🔹 Average Pooling Layer  
- 🔹 Fully Connected Layer  
- 🔹 ReLU Activation Function

These CNN cores operate concurrently and are instantiated **4 times** in the top-level module. The entire setup is connected through:

- A shared RAM module for input/output data
- A GPIO module for signaling progress using LEDs
- A UART module for serial I/O

Each module communicates over a **Wishbone-compliant interconnect**.

---

## System Components

### CNN Core

Each CNN core includes:
- A **convolution engine** that performs feature extraction
- An **average pooling layer** to reduce spatial dimensions
- A **fully connected layer** with **ReLU** activation for final classification

Weights are **pre-trained and exported from Python** (NumPy `.npz` format) and are **loaded into the hardware module** to enable inference.

---

### Multi-Core Controller

A controller FSM manages 4 CNN cores:
- Distributes input images to each core
- Triggers each CNN core
- Waits for all cores to complete
- Collects predictions

---

### Wishbone Interconnect

This project uses a **Wishbone bus** to connect the CPU/controller to peripheral modules.

**Wishbone** is an open-source hardware bus interface, often used in FPGA and ASIC projects for its simplicity and flexibility. It consists of signals like:
- `wb_cyc`: Valid bus cycle
- `wb_stb`: Strobe signal, initiates transfer
- `wb_ack`: Acknowledge from the slave
- `wb_we`: Write enable
- `wb_addr`: Address lines
- `wb_data`: Data lines

Each peripheral is **memory-mapped** using address decoding logic (`bus_decoder.v`).

---

### UART (from [ZipCPU/wbuart32](https://github.com/ZipCPU/wbuart32))

UART is used for asynchronous serial communication between the accelerator and an external device.  
- **Baud Rate** is set via `UART_SETUP` register  
- RX and TX logic handle 8N1 transmission (8 data bits, No parity, 1 stop bit)  
- UART module is Wishbone-compatible

---

### GPIO

The GPIO module is used to control and monitor 4 LEDs:
- Indicates the state of the controller FSM (IDLE → START → WAIT → DONE)
- Helps in **hardware debugging and progress visualization**

---

## 🧪 Simulation & Testing

All modules were tested using **ModelSim** via:
- Individual **unit testbenches** for CNN, RAM, UART, and GPIO
- A **top-level testbench** that simulates the entire multi-core system
- Functional testing using **pre-trained weight files** in `.npz` format

---

## Directory Structure (Example)
Multi-core-ML-Accelerator

├── cnn_core/ # Convolutional, Pooling, FC, ReLU

├── uart_modules/ # wbuart32 from ZipCPU

├── gpio_module/ # GPIO controller

├── memory/ # Dual-port RAM

├── wishbone/ # Interconnect + decoder

├── tb/ # Testbenches

└── README.md # This file

---

## Applications

This project simulates a design approach used in:
- Low-power embedded CNN accelerators
- FPGA-based real-time inference systems
- Hardware-software co-design (Python for training, Verilog for inference)

---

## Future Extensions

- Add AXI4-Lite compatibility  
- Interface with external memory (e.g., DDR3/SDRAM)  
- Deploy on a real FPGA (e.g., Intel/Altera or Xilinx boards)  
- Add SPI or I2C for sensor interfacing  
- Train for multi-class image classification

---

## License

This project reuses open-source modules (e.g., ZipCPU UART) under **GPL** license. Refer to individual module directories for licensing details.

---

**Developed and Simulated by: _Shruti Hegde_**

