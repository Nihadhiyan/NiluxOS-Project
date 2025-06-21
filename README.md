🚀 NiluxOS: A 16-bit Assembly Kernel for PC Architecture

Welcome to NiluxOS, a compact and foundational 16-bit operating system kernel meticulously crafted in Assembly language. Conceived as an immersive educational platform, NiluxOS aims to demystify the intricacies of low-level system operations, direct hardware interaction, and the foundational elements of operating system design within the familiar 8086 real-mode environment.
✨ Core Features

NiluxOS provides a hands-on exploration of system fundamentals through its integrated capabilities:

    Comprehensive Hardware Discovery:
        Memory Analysis: Accurately detects and reports Base, Extended, and Total System Memory.
        CPU Identification: Extracts and displays crucial CPU details, including Vendor ID and Brand String.
        Peripheral Enumeration: Identifies the number of detected Hard Drives and the operational status of the Mouse.
        Serial Port Insight: Reports the total count of Serial Ports and the base I/O address for Serial Port 1.
        CPU Feature Flagging: Detects and indicates the presence of key CPU features such as FPU, MMX, SSE, and SSE2, providing insight into processor capabilities.

    Intuitive Command-Line Interface (CLI):
        info: Presents a detailed summary of the detected hardware information.
        help: Displays a concise list of all available commands and their descriptions.
        clear: Clears the console screen, providing a fresh workspace.

🛠️ Built With

NiluxOS is constructed with precision using:

    Assembly Language (NASM Syntax): The entire kernel is written in 16-bit real-mode Assembly, leveraging NASM (Netwide Assembler) for its robust syntax and powerful macro capabilities.

🎯 Project Philosophy & Acknowledgments

NiluxOS draws significant inspiration from projects like MikeOS (by Mike McLaren and the MikeOS Developers), which serve as exemplary educational resources for aspiring OS developers. We extend our sincere gratitude to these foundational projects for their invaluable contributions to the open-source community and their role in guiding the development of NiluxOS.
💻 Getting Started

To compile and execute NiluxOS, you'll need the following essential tools:

    NASM Assembler: Essential for transforming the Assembly source code (.asm) into a flat, executable binary.
    QEMU (or compatible emulator): Utilized for emulating the PC hardware environment to test the generated bootable image.
    mkdosfs & mtools: For creating and manipulating DOS-formatted floppy disk images.
    mkisofs: For generating bootable ISO images suitable for CD-ROM or modern virtual machines.

Building and Running Instructions:

Execute the provided build and test scripts in your Linux environment:
Bash

sudo ./build.sh && sudo ./test.sh

📸 Screenshots

Witness NiluxOS in action within an emulated environment:

**NiluxOS Home Screen:** Shows the initial boot prompt and welcome message.
![NiluxOS Boot Screen](OS/screenshots/Screenshot From 2025-06-20 23-29-30.png)

**NiluxOS Help Command Output:** Displays a list of available commands.
![NiluxOS Help Screen](OS/screenshots/Screenshot From 2025-06-20 23-29-44.png)

**NiluxOS Info Command Output:** Provides a detailed overview of detected system hardware.
![NiluxOS Info Screen](OS/screenshots/Screenshot From 2025-06-20 23-29-56.png)

**NiluxOS Clear Command Output:** Shows the console after the 'clear' command has been executed.
![NiluxOS Clear Screen](OS/screenshots/Screenshot From 2025-06-20 23-30-26.png)
![NiluxOS Cleared Screen](OS/screenshots/Screenshot From 2025-06-20 23-30-34.png)
    
