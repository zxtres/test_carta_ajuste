`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.05.2023 00:05:29
// Design Name: 
// Module Name: audio_source
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module audio_source (
  input wire clk,
  output reg [15:0] audio_l,
  output reg [15:0] audio_r  
  );
  
  parameter [15:0] CLKMHZ = 16'd50;
  parameter FREQHZTONO = 1000; // frecuencia en Hz del tono a escuchar
  localparam [15:0] TICKSPERSAMPLE = CLKMHZ * 10000 / 480;   // asumimos una f.s. de 48 kHz
  localparam SAMPLEPERIOD = 48000 / FREQHZTONO;

  reg [15:0] sample[0:SAMPLEPERIOD-1];
  integer i;
  initial begin
    for (i=0; i<SAMPLEPERIOD; i=i+1)
      sample[i] = 32767*$sin(i*2*3.141592654/SAMPLEPERIOD);
  end
  
  reg [15:0] counter = 0;
  reg [7:0] isample = 0;
  always @(posedge clk) begin
    counter <= counter + 1;
    if (counter == TICKSPERSAMPLE) begin
      counter <= 0;
      if (isample == (SAMPLEPERIOD-1))
        isample <= 0;
      else
        isample <= isample + 1;
      audio_l <= sample[isample];
      audio_r <= sample[isample];
    end
  end
endmodule

`default_nettype none
