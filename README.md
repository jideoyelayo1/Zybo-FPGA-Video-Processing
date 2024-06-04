# Zybo FPGA Video Processing

Realtime video processing with Prewitt and Sobel Filters targeting Zybo-Z7-20 FPGA.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Getting Started](#getting-started)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Demonstration](#demonstration)
- [Contributing](#contributing)
- [License](#license)

## Introduction
This project implements real-time video processing using Prewitt and Sobel filters on the Zybo-Z7-20 FPGA. It demonstrates edge detection algorithms applied to live video feed, leveraging the FPGA's parallel processing capabilities.

## Features
- Real-time video processing
- Edge detection using Prewitt and Sobel filters
- Targeted for Zybo-Z7-20 FPGA
- Efficient utilization of FPGA resources

## Getting Started
Follow these instructions to set up and run the project on your Zybo-Z7-20 FPGA board.

### Prerequisites
- Zybo-Z7-20 FPGA board
- Vivado Design Suite
- Xilinx SDK
- HDMI input source

### Installation
1. Clone the repository:
    ```sh
    git clone https://github.com/jideoyelayo1/Zybo-FPGA-Video-Processing.git
    ```
2. Open the project in Vivado:
    - Open Vivado and create a new project.
    - Import the provided VHDL and Verilog files.
3. Generate the bitstream and export the hardware.
4. Open Xilinx SDK and create a new application project.
    - Import the exported hardware.
    - Copy the provided C files into the SDK project.
5. Program the FPGA with the generated bitstream.

## Usage
1. Connect the HDMI input source to the Zybo-Z7-20 board.
2. Power on the board and run the application from the SDK.
3. The processed video with edge detection will be displayed on the HDMI output.

## Demonstration
Watch the demonstration video on YouTube:
- [Prewitt Filter Demonstration](https://www.youtube.com/watch?v=vdC7v7xRRTg)
- [Sobel Filter Demonstration](https://www.youtube.com/watch?v=ISVAD1BXLU4)

## Contributing
Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License
This project is licensed under the Apache-2.0 License. See the [LICENSE](LICENSE) file for details.
