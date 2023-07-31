`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 20:16:31 2014-12-26 by Miguel Angel Rodriguez Jodar
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

module ps2_port (
    input wire clk,  // se recomienda 1 MHz <= clk <= 600 MHz
    input wire enable_rcv,  // habilitar la maquina de estados de recepcion
    input wire kb_or_mouse,  // 0: kb, 1: mouse
    input wire ps2clk_ext,
    input wire ps2data_ext,
    output wire kb_interrupt,  // a 1 durante 1 clk para indicar nueva tecla recibida
    output reg [7:0] scancode, // make o breakcode de la tecla
    output wire released,  // soltada=1, pulsada=0
    output wire extended  // extendida=1, no extendida=0
    );
    
    localparam RCVSTART  = 2'b00,
               RCVDATA   = 2'b01,
               RCVPARITY = 2'b10,
               RCVSTOP   = 2'b11;

    reg [7:0] key = 8'h00;

    // Fase de sincronizacion de señales externas con el reloj del sistema
    reg [1:0] ps2clk_synchr;
    reg [1:0] ps2dat_synchr;
    wire ps2clk = ps2clk_synchr[1];
    wire ps2data = ps2dat_synchr[1];
    always @(posedge clk) begin
      ps2clk_synchr[0] <= ps2clk_ext;
      ps2clk_synchr[1] <= ps2clk_synchr[0];
      ps2dat_synchr[0] <= ps2data_ext;
      ps2dat_synchr[1] <= ps2dat_synchr[0];
    end

    // De-glitcher. Sólo detecto flanco de bajada
    reg [15:0] negedgedetect = 16'h0000;
    always @(posedge clk) begin
      negedgedetect <= {negedgedetect[14:0], ps2clk};
    end
    wire ps2clkedge = (negedgedetect == 16'hF000)? 1'b1 : 1'b0;
    
    // Paridad instantánea de los bits recibidos
    wire paritycalculated = ^key;
    
    // Contador de time-out. Al llegar a 16777216 ciclos sin que ocurra
    // un flanco de bajada en PS2CLK, volvemos al estado inicial
    reg [23:0] timeoutcnt = 24'h000000;

    reg [1:0] state = RCVSTART;
    reg [1:0] regextended = 2'b00;
    reg [1:0] regreleased = 2'b00;
    reg rkb_interrupt = 1'b0;
    assign released = regreleased[1];
    assign extended = regextended[1];
    assign kb_interrupt = rkb_interrupt;
    
    always @(posedge clk) begin
        if (rkb_interrupt == 1'b1) begin
            rkb_interrupt <= 1'b0;
        end
        if (ps2clkedge && enable_rcv) begin
            timeoutcnt <= 24'h000000;
            case (state)
                RCVSTART: begin
                    if (ps2data == 1'b0) begin
                        state <= RCVDATA;
                        key <= 8'h80;
                    end
                end
                RCVDATA: begin
                    key <= {ps2data, key[7:1]};
                    if (key[0] == 1'b1) begin
                        state <= RCVPARITY;
                    end
                end
                RCVPARITY: begin
                    if (ps2data^paritycalculated == 1'b1) begin
                        state <= RCVSTOP;
                    end
                    else begin
                        state <= RCVSTART;
                    end
                end
                RCVSTOP: begin
                    state <= RCVSTART;                
                    if (ps2data == 1'b1) begin                        
                        scancode <= key;
                        if (kb_or_mouse == 1'b1) begin
                            rkb_interrupt <= 1'b1;  // no se requiere mirar E0 o F0
                        end
                        else begin
                            if (key == 8'hE0) begin
                                regextended <= 2'b01;
                            end
                            else if (key == 8'hF0) begin
                                regreleased <= 2'b01;
                            end
                            else begin
                                regextended <= {regextended[0], 1'b0};
                                regreleased <= {regreleased[0], 1'b0};
                                rkb_interrupt <= 1'b1;
                            end
                        end
                    end
                end    
                default: state <= RCVSTART;
            endcase
        end           
        else begin
            timeoutcnt <= timeoutcnt + 24'd1;
            if (timeoutcnt == 24'hFFFFFF) begin
                state <= RCVSTART;
            end
        end
    end
endmodule

`default_nettype wire