`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 21:14:58 2023-05-01 by Miguel Angel Rodriguez Jodar
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.

module tld (
  input  wire clk50mhz,
  //////////////////////////////////////////
  input  wire clkps2,
  input  wire dataps2,
  //////////////////////////////////////////  
  output wire audio_out_left,
  output wire audio_out_right,  
  output wire [1:0] led,
  //////////////////////////////////////////
  output wire i2s_bclk,
  output wire i2s_lrclk,
  output wire i2s_dout,  
  //////////////////////////////////////////
  output wire [5:0] vga_r,
  output wire [5:0] vga_g,
  output wire [5:0] vga_b,
  output wire vga_hs,
  output wire vga_vs,
  //////////////////////////////////////////
  output wire dp_tx_lane_p,
  output wire dp_tx_lane_n,
  input  wire dp_refclk_p,
  input  wire dp_refclk_n,
  input  wire dp_tx_hp_detect,
  inout  wire dp_tx_auxch_tx_p,
  inout  wire dp_tx_auxch_tx_n,
  inout  wire dp_tx_auxch_rx_p,
  inout  wire dp_tx_auxch_rx_n
  );
  
  wire clkvideo, clkpalntsc, clock_stable;
  wire [7:0] video_r, video_g, video_b;
  wire video_cs, video_hs, video_vs;
  
  relojes_mmcm relojes (
    .CLK_IN1(clk50mhz),
    .CLK_OUT1(clkvideo),
    .CLK_OUT2(clkpalntsc),
    .reset(1'b0),
    .locked(clock_stable)
  );
  
  wire [15:0] audio_l, audio_r;
  audio_source #(.CLKMHZ(14)) pitido (clkvideo, audio_l, audio_r); 
  
  ///////////////////////////////////////////////////
  // Manejo del core por teclado
  ///////////////////////////////////////////////////
  wire       new_key;
  wire [7:0] scancode;
  wire       key_released, key_extended;

  reg        video_output_sel = 1;
  reg        disable_scanlines = 1;
  reg [1:0]  monochrome_sel = 0;
  reg        reset_maestro = 0;         
  reg        ad724_clken = 0; 
  
  ps2_port el_teclado (
      .clk(clkvideo),  // se recomienda 1 MHz <= clk <= 600 MHz
      .enable_rcv(1'b1),  // habilitar la maquina de estados de recepcion
      .kb_or_mouse(1'b0),  // 0: kb, 1: mouse
      .ps2clk_ext(clkps2),
      .ps2data_ext(dataps2),
      .kb_interrupt(new_key),  // a 1 durante 1 clk para indicar nueva tecla recibida
      .scancode(scancode), // make o breakcode de la tecla
      .released(key_released),  // soltada=1, pulsada=0
      .extended(key_extended)  // extendida=1, no extendida=0
      );
  
  always @(posedge clkvideo) begin
    if (new_key == 1'b1 && key_released == 1'b0 && key_extended == 1'b0) begin
      case (scancode)
        'h16: video_output_sel <= ~video_output_sel;    // tecla 1
        'h1E: disable_scanlines <= ~disable_scanlines;  // tecla 2 
        'h26: monochrome_sel <= (monochrome_sel == 3)? 0 : monochrome_sel + 1;  // tecla 3
        'h25: ad724_clken <= ~ad724_clken;    // tecla 4
        'h76: reset_maestro <= 1'b1;    // tecla ESC
      endcase
    end
  end
  
  carta_ajuste_tve_50hz_pal video_original (
    .clk(clkvideo),
    .red(video_r),
    .green(video_g),
    .blue(video_b),
    .hsync_n(video_hs),
    .vsync_n(video_vs),
    .csync_n(video_cs)
  );
  localparam HSTART = 110;   // Estos valores centran muy bien una pantalla PAL generada con 
  localparam VSTART = 44;    // timings standard, de 704x576, y con un reloj de 14 MHz
  localparam CLKVIDEO = 14;
  localparam INITIAL_FIELD = 1;   // 1 o 0. Si la fuente no es entrelazada, dejar a 0
  
  zxtres_wrapper #(.HSTART(HSTART), .VSTART(VSTART), .CLKVIDEO(CLKVIDEO), .INITIAL_FIELD(INITIAL_FIELD)) scaler (
  .clkvideo(clkvideo),                    // reloj de pixel de la se�al de video original (generada por el core)
  .enclkvideo(1'b1),                      // si el reloj anterior es mayor que el reloj de pixel, y se necesita un clock enable
  .clkpalntsc(clkpalntsc),                // Reloj de 100 MHz para la generacion del reloj de color PAL o NTSC
  .reset_n(clock_stable),                 // Reset de todo el m�dulo (reset a nivel bajo)
  .reboot_fpga(reset_maestro),            // a 1 para indicar que se quiere volver al core principal
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////
  .video_output_sel(video_output_sel),    // 0: RGB 15kHz + DP   1: VGA + DP pantalla azul
  .disable_scanlines(disable_scanlines),  // 0: emular scanlines (cuidado con el polic�a del retro!)  1: sin scanlines
  .monochrome_sel(monochrome_sel),        // 0 : RGB, 1: f�sforo verde, 2: f�sforo �mbar, 3: escala de grises
  .interlaced_image(1'b1),                //
  .ad724_modo(1'b0),                      // Reloj de color. 0 : PAL, 1: NTSC
  .ad724_clken(ad724_clken),              // 0 = AD724 usa su propio cristal. 1 = AD724 usa reloj de FPGA
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  .ri(video_r),            //  
  .gi(video_g),            // RGB (8 bits por color primario) de entrada
  .bi(video_b),            // 
  .hsync_ext_n(video_hs),  // Sincronismo horizontal y vertical separados. Los necesito separados para poder, dentro del m�dulo
  .vsync_ext_n(video_vs),  // medir cu�ndo comienza y termina un scan y un frame, y as� centrar la imagen en el framebuffer
  .csync_ext_n(video_cs),  // entrada de sincronismo compuesto de la se�al original
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  .audio_l(audio_l),            // Entrada de audio
  .audio_r(audio_r),            // 16 bits, PCM, ca2
  .i2s_bclk(i2s_bclk),          //
  .i2s_lrclk(i2s_lrclk),        // Salida hacia el m�dulo I2S  
  .i2s_dout(i2s_dout),          //
  .sd_audio_l(audio_out_left),  // Salida de 1 bit desde
  .sd_audio_r(audio_out_right), // los conversores sigma-delta
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  .ro(vga_r),         // Salida RGB de VGA 
  .go(vga_g),         // o de 15 kHz, seg�n el valor
  .bo(vga_b),         // de video_output_sel
  .hsync(vga_hs),     // Para RGB 15 kHz, aqui estar� el sincronismo compuesto
  .vsync(vga_vs),     // Para RGB 15 kHz, de momento se queda al valor 1, pero aqu� luego ir� el reloj de color x4
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  .dp_tx_lane_p(dp_tx_lane_p),          // De los dos lanes de la Artix 7, solo uso uno.
  .dp_tx_lane_n(dp_tx_lane_n),          // Cada lane es una se�al diferencial. Esta es la parte negativa.
  .dp_refclk_p(dp_refclk_p),            // Reloj de referencia para los GPT. Siempre es de 135 MHz
  .dp_refclk_n(dp_refclk_n),            // El reloj tambi�n es una se�al diferencial.
  .dp_tx_hp_detect(dp_tx_hp_detect),    // Indica que se ha conectado un monitor DP. Arranca todo el proceso de entrenamiento
  .dp_tx_auxch_tx_p(dp_tx_auxch_tx_p),  // Se�al LVDS de salida (transmisi�n)
  .dp_tx_auxch_tx_n(dp_tx_auxch_tx_n),  // del canal AUX. En alta impedancia durante la recepci�n
  .dp_tx_auxch_rx_p(dp_tx_auxch_rx_p),  // Se�al LVDS de entrada (recepci�n)
  .dp_tx_auxch_rx_n(dp_tx_auxch_rx_n),   // del canal AUX. Siempre en alta impedancia ya que por aqu� no se transmite nada.
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  .dp_ready(led[0]),
  .dp_heartbeat(led[1])
  );
endmodule

`default_nettype wire