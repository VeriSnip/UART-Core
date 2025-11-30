# MyUART  
This module implements the basic interface you would expect from a standard TI 16550 UART.

You need to install [VeriSnip](https://pypi.org/project/VeriSnip/) to use this core.

## MMIO (Memory Mapped IO)
The implemented memory-mapped I/O UART registers are accessible through the bus. These registers adhere to the UART-16550(A) standard, as outlined in [this Datasheet](http://caro.su/msx/ocm_de1/16550.pdf). Attempting to write to an unimplemented register will have no impact, while reading from such a register will consistently yield a value of 0x00. All registers have a width of 8 bits.

| Address | Register                                | Access Type | Reset Value | Description                                                                                                                                                                                                                          |
|---------|-----------------------------------------|-------------|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 0x0     | Receiver Buffer Register (RBR)          | Read only   | 0x00        | This is the register where incoming data is stored after being received.  When new data arrives, it is placed in the RBR, and the UART's  interrupt system can be configured to notify the processor about the  available data.      |
| 0x0     | Transmitter Holding Register (THR)      | Write only  | 0x00        | Outgoing data is written to this register for transmission. When data is  written to the THR, the UART begins sending it bit by bit.                                                                                                 |
| 0x0     | Divisor Latch Low Byte (DLL)            | Read/Write  | 0x00        | This register, along with the Divisor Latch High Byte (DLH), is used to  set the baud rate of the UART. Together, the DLL and DLH determine the  divisor used to divide the UART's clock frequency and set the  communication speed. |
| 0x1     | Interrupt Enable Register (IER)         | Read/Write  | 0x00        | This register controls the UART's interrupt generation. It allows you to  enable or disable various types of interrupts, such as received data  available, transmitter holding register empty, and more.                             |
| 0x1     | Divisor Latch High Byte (DLH)           | Read/Write  | 0x00        | This register, as mentioned earlier, works in conjunction with the DLL to set the baud rate.                                                                                                                                         |
| 0x2     | Interrupt Identification Register (IIR) | Read only   | 0x01        | This register provides information about the cause of the interrupt. It  indicates the highest-priority interrupt pending and its source.                                                                                            |
| 0x2     | FIFO Control Register (FCR)             | Write only  | 0x00        | The FIFO control register is used to configure the behavior of the FIFO  buffer. It allows you to enable or disable the FIFO, set the trigger  level at which interrupts are generated, and clear the FIFOs.                         |
| 0x3     | Line Control Register (LCR)             | Read/Write  | 0x00        | This register configures various line settings, including the number of  data bits per character, the number of stop bits, and whether parity  checking is enabled.                                                                  |
| 0x4     | Modem Control Register (MCR)            | -           | 0x00        | This register controls various modem-related functions, such as  controlling the RTS (Request to Send) and DTR (Data Terminal Ready)  signals.                                                                                       |
| 0x5     | Line Status Register (LSR)              | Read only   | 0x60        | The LSR provides information about the current status of the UART's  receiver and transmitter. It indicates conditions such as receiver data  available, transmitter holding register empty, and various error  conditions.          |
| 0x6     | Modem Status Register (MSR)             | -           | 0x00        | The MSR provides information about the status of the modem control  signals, such as CTS (Clear to Send) and DSR (Data Set Ready).                                                                                                   |
| 0x7     | Scratch Register (SCR)                  | -           | 0x00        | This is a general-purpose register that can be used for temporary storage.                                                                                                                                                           |

### Divisor Latch Low Byte (DLL) and Divisor Latch High Byte (DLH):
These registers together determine the divisor used to set the baud rate. The formula for calculating the divisor is: `Divisor = Clock Frequency / (Baud Rate × 16)`
### FIFO Control Register (FCR):
- Bit 0 (FIFO Enable): Enables or disables the FIFO buffer.
- Bit 1 (Clear Receive FIFO) and Bit 2 (Clear Transmit FIFO): These bits are used to clear the receive and transmit FIFO buffers, respectively.
- Bits 6-7 (Trigger Level): These bits determine when the RX interrupt is generated based on the fill level of the receive FIFO. Different trigger levels can be set to control interrupt frequency.
### Interrupt Enable Register (IER)
- Bit 0 (Enable Received Data Available Interrupt): When set to 1, enables the interrupt for when new data is available in the receive buffer.
- Bit 1 (Enable Transmitter Empty Interrupt): When set to 1, enables the interrupt when the transmitter holding register is empty and ready for new data.
- Bit 2 (Enable Receiver Line Status Interrupt): When set to 1, enables the interrupt for various receiver line status conditions (like framing errors, parity errors, etc.).
- Bit 3 (Enable Modem Status Interrupt): When set to 1, enables the interrupt for modem status changes (like changes in CTS, DSR, etc.).
- Bits 4-7: Reserved or vendor-specific bits, not used in the standard UART-16550.
### Interrupt Identification Register (IIR):
- Bit 0 (Interrupt Pending): When cleared (0), indicates that at least one interrupt is pending. When set (1), indicates that no interrupts are pending.
- Bit 1 (Interrupt Identification): This bit, along with bit 2, indicates the highest-priority interrupt that is pending.
- Bit 2 (Interrupt Identification): Together with bit 1, this bit indicates the highest-priority interrupt pending.
- Bit 3 (FIFO Enabled): When set to 1, indicates that FIFOs are enabled. If cleared (0), the FIFOs are not used.
- Bit 4-7: These bits provide additional information about the status of the FIFOs and the interrupt sources. The exact meaning of these bits can vary between different UART implementations.

| Bit 2 | Bit 1 | Interrupt Source                   |
|-------|-------|------------------------------------|
| 0     | 0     | None (Interrupt pending bit is set)|
| 0     | 1     | Modem Status Interrupt             |
| 1     | 0     | Transmitter Empty Interrupt        |
| 1     | 1     | Received Data Available Interrupt  |
### Line Control Register (LCR):
- Bits 0-1 (Word Length): These bits determine the number of data bits in a frame. Common settings are 00 for 5 data bits, 01 for 6 data bits, 10 for 7 data bits, and 11 for 8 data bits.
- Bit 2 (Stop Bits): This bit specifies the number of stop bits. 0 indicates 1 stop bit, and 1 indicates 1.5 or 2 stop bits.
- Bit 3 (Parity Enable): Enables parity generation and checking.
- Bits 4-5 (Parity Type): These bits configure the type of parity (even, odd, mark, space).
- Bit 6 (Break Control): Sends a break signal when set to 1.
- Bit 7 (DLAB): Divisor Latch Access Bit. When set to 1, allows access to the Divisor Latch registers (DLL and DLH) to set the baud rate. When cleared (0), allows access to other registers.
### Modem Control Register (MCR):
- Bit 0 (DTR): Data Terminal Ready control bit.
- Bit 1 (RTS): Request to Send control bit.
- Bit 2 (Out1): Modem control bit (often used as an auxiliary output).
- Bit 3 (Out2): Modem control bit (often used as a general-purpose output).
### Line Status Register (LSR):
- Bit 0 (Data Ready): Indicates whether there is data available in the receiver buffer.
- Bit 5 (Transmitter Empty): Indicates that the transmitter holding register is empty and ready to accept new data.
- Bit 6 (Transmitter Holding Register Empty): Indicates that the transmitter holding register and shift register are both empty, meaning the UART is ready to transmit new data.
- Bit 7 (Error): Indicates the presence of any error in the received data, like framing errors, parity errors, or break signals.
### Modem Status Register (MSR):
- Bit 0 (CTS): Clear to Send status bit.
- Bit 1 (DSR): Data Set Ready status bit.
- Bit 2 (RI): Ring Indicator status bit.
- Bit 3 (DCD): Data Carrier Detect status bit.
