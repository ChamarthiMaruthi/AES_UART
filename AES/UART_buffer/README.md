# UART with FIFO Buffer

## 📌 Project Overview
This project implements a **UART (Universal Asynchronous Receiver/Transmitter) with FIFO buffers** for both transmission (TX) and reception (RX).  
The design is written in **Verilog HDL** and simulated using **ModelSim / QuestaSim**. It supports:
- Transmitting and receiving serial data.
- FIFO buffering to handle back-to-back data streams.
- Configurable parity.
- Verified testbench with multiple data inputs.

This project was developed as part of my exploration into digital design, FPGA development, and verification.

---

## ⚡ Features
- **UART TX and RX modules**
- **FIFO buffers** for smooth data handling
- **Configurable parity bit**
- **Testbench** for functional verification

---

## 🏗️ Project Structure
```
├── src/
│   ├── uart_tx.v
│   ├── uart_rx.v
│   ├── fifo_tx.v
│   ├── fifo_rx.v
│   └── top_module.v
├── tb/
│   ├── uart_tb.v
│   └── test_data.hex
├── sim/
│   └── (simulation logs, waveform files, etc.)
├── README.md
└── LICENSE
```

---

## 🚀 Getting Started

### Prerequisites
- Intel Quartus Prime (for synthesis on FPGA)  
- ModelSim / QuestaSim (for simulation)  
- Git  

## 📊 Results
- ✅ UART TX & RX verified with FIFO buffering.  
- ✅ Data transmission verified for multiple bytes.  
- ⚠️ Known issue: FIFO underflow may occur if TX start signal is not aligned (fixed in testbench).  


## 👨‍💻 Author
**Maruthi Chamarthi**  
- 🎓 NIT Durgapur  
- 🔬 Interested in FPGA, ASIC, and digital design verification  
- 🌐 [LinkedIn](https://www.linkedin.com/in/maruthi-chamarthi/)  

---

