# AES_UART

A hardware implementation of AES-128 encryption/decryption system with UART communication interface, designed for FPGA deployment.

## 📋 Overview

This project implements a complete AES-128 cryptographic system that encrypts plaintext, transmits the ciphertext via UART, receives it back through UART loopback, and decrypts it to verify the integrity of the data transmission. The design is synthesized and optimized for FPGA deployment using Intel Quartus.

## 🔑 Key Features

- **AES-128 Encryption/Decryption**: Full hardware implementation of the Advanced Encryption Standard (128-bit key)
- **UART Communication**: Integrated UART transmitter and receiver for serial data transmission
- **Multi-Clock Domain Design**: 
  - 100 MHz for AES operations
  - 3.125 MHz for UART TX and RX
- **Clock Domain Crossing (CDC)**: Safe synchronization between different clock domains
- **Complete Data Flow**: Encrypt → Transmit → Receive → Decrypt pipeline
- **Loopback Testing**: Built-in UART loopback capability for verification

## 🏗️ Architecture

### Top-Level Module: `aes_uart_top`

The system integrates the following major components:

```
┌─────────────────────────────────────────────┐
│           aes_uart_top                      │
│                                             │
│  ┌──────────────┐         ┌──────────────┐ │
│  │ AES Encrypt  │────────→│  UART TX     │─┼──→ tx
│  └──────────────┘         └──────────────┘ │
│         ↓                                   │
│  ┌──────────────┐         ┌──────────────┐ │
│  │ AES Decrypt  │←────────│  UART RX     │←┼──← rx
│  └──────────────┘         └──────────────┘ │
└─────────────────────────────────────────────┘
```

### Main Components

1. **AES Encryption Module** (`u_aes_encrypt`)
   - 128-bit plaintext input
   - 128-bit key input
   - Key expansion engine
   - SubBytes, ShiftRows, MixColumns operations
   - 10 rounds of encryption

2. **AES Decryption Module** (`u_aes_decrypt`)
   - Inverse cipher operations
   - InvSubBytes, InvShiftRows, InvMixColumns
   - Same key expansion for symmetric decryption

3. **UART Transmitter** (`u_uart_tx`)
   - Parallel-to-serial conversion
   - 8-bit data transmission
   - Configurable baud rate (3.125 MHz clock)

4. **UART Receiver** (`u_uart_rx`)
   - Serial-to-parallel conversion
   - Data synchronization
   - Error detection

5. **CDC Synchronizers**
   - Safe signal crossing between clock domains
   - Prevents metastability issues

## 📊 Pin Configuration

### Inputs
- `clk_100`: 100 MHz system clock for AES operations
- `clk_3125_tx`: 3.125 MHz clock for UART transmitter
- `clk_3125_rx`: 3.125 MHz clock for UART receiver
- `rst_n`: Active-low asynchronous reset (fast domain)
- `rst_n_slow`: Active-low reset for slow clock domain
- `rst_n_fast`: Active-low reset for fast clock domain
- `start`: Start signal to initiate encrypt→transmit→receive→decrypt flow
- `plaintext[127:0]`: 128-bit input data to encrypt
- `key[127:0]`: 128-bit encryption key
- `rx`: UART receive line

### Outputs
- `tx`: UART transmit line
- `decrypted_text[127:0]`: 128-bit decrypted output
- `done`: Operation complete flag
- `done_slow`: CDC-synchronized done signal
- `enc_done`: Encryption complete flag
- `RD_RX`: UART receive read enable

## 🔧 Technical Specifications

- **Encryption Algorithm**: AES-128 (FIPS 197)
- **Block Size**: 128 bits
- **Key Length**: 128 bits
- **UART Baud Rate**: Configurable (driven by 3.125 MHz clock)
- **Target Device**: Intel/Altera FPGA
- **HDL Language**: Verilog

## 📁 Repository Structure

```
AES_UART/
└── AES/
    └── TOP/
        ├── aes_uart_top.v          # Top-level integration module
        └── db/                      # Quartus database files
            ├── aes_uart_top.lpc.html
            └── aes_uart_top.lpc.txt
```

## 🚀 Getting Started

### Prerequisites

- Intel Quartus Prime (for synthesis and implementation)
- ModelSim or similar simulator (for verification)
- FPGA development board with:
  - At least 100 MHz clock capability
  - UART interface or USB-to-Serial converter
  - Sufficient logic elements for AES implementation

### Synthesis

1. Open Intel Quartus Prime
2. Create a new project and add `aes_uart_top.v` as the top-level entity
3. Add all AES and UART submodules to the project
4. Set timing constraints for multiple clock domains
5. Compile the design
6. Program the FPGA

### Simulation

```verilog
// Example testbench stimulus
initial begin
    rst_n = 0;
    start = 0;
    plaintext = 128'h00112233445566778899aabbccddeeff;
    key = 128'h000102030405060708090a0b0c0d0e0f;
    
    #100 rst_n = 1;
    #50 start = 1;
    #10 start = 0;
    
    wait(done);
    $display("Decrypted Text: %h", decrypted_text);
end
```

## 🧪 Testing

The design includes built-in loopback testing:

1. Apply plaintext and key inputs
2. Assert `start` signal
3. System encrypts data
4. Encrypted data transmitted via UART TX
5. Data received back via UART RX (loopback connection)
6. System decrypts received data
7. `done` signal asserts when complete
8. Compare `decrypted_text` with original `plaintext`

## 📈 Resource Utilization

Based on synthesis results for the design:
- **Logic Elements**: Varies by FPGA family
- **Memory Bits**: S-Box implementations
- **Clock Domains**: 3 (100 MHz, 3.125 MHz TX, 3.125 MHz RX)

Refer to `AES/TOP/db/aes_uart_top.lpc.html` for detailed resource reports.

## 🔒 Security Considerations

- This is a hardware implementation for educational/prototyping purposes
- Key is provided externally (not generated internally)
- No key storage or management implemented
- Side-channel attack countermeasures not included
- For production use, consider additional security measures

## 📖 AES Algorithm Background

AES-128 uses:
- **Key Expansion**: Expands 128-bit key to 11 round keys (1408 bits total)
- **SubBytes**: Non-linear substitution using S-Box
- **ShiftRows**: Circular shift of rows
- **MixColumns**: Mixing operation in Galois Field
- **AddRoundKey**: XOR with round key
- **10 Rounds**: 9 standard rounds + 1 final round (no MixColumns)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:
- Bug fixes
- Performance optimizations

---

**Project Status**: Active Development  
**Last Updated**: January 2026

For questions or support, please open an issue on GitHub.