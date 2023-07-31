//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2023 20:06:20
// Design Name: 
// Module Name: video_704x288_3bpp_50hz_pal
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
`timescale 1ns / 1ps
`default_nettype none

module carta_ajuste_tve_50hz_pal (
    input wire clk,  // 14 MHz
    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue,
    output reg hsync_n,
    output reg vsync_n,
    output reg csync_n
    );

    localparam ETAPAS_PIPELINE = 12; 
    
    reg [10:0] hcont = 0;  // contador horizontal (cuenta pixeles)
    reg [10:0] vcont = 0;  // contador vertical (cuenta scans)

    reg [7:0] barras[0:399];
    initial $readmemh ("valores_barras_rejilla.hex", barras);
    
    reg [7:0] circulo[0:255];
    initial $readmemh ("valores_cuarto_circunferencia.hex", circulo);

    //reg [0:0] tve[0:256*80-1];
    //reg logopixel;
    //initial $readmemh ("logo_tve.hex", tve);
    reg [2:0] logozxtres[0:256*64-1];
    reg [2:0] logopixel; 
    initial $readmemh ("logo_zxtres.hex", logozxtres);
    
    // Generamos los sincronismos en función de los contadores de pixel y scan
    reg h0,v0,c0;
    always @* begin
      if (vcont >= 0 && vcont < 3 || vcont >= 312 && vcont < 315) 
        v0 = 0;                                                   
      else
        v0 = 1;
      if (hcont >= 0 && hcont < 67)
        h0 = 0;
      else
        h0 = 1;
      
      if (vcont == 0 || vcont == 1 || vcont == 313 || vcont == 314) begin
        if (hcont >= 0 && hcont < 420 || hcont >= 448 && hcont < 868)
          c0 = 0;
        else
          c0 = 1;
      end
      else if (vcont == 3 || vcont == 4 || vcont == 310 || 
               vcont == 311 || vcont == 315 || vcont == 316 || 
               vcont == 622 || vcont == 623 || vcont == 624) begin
        if (hcont >= 0 && hcont < 28 || hcont >= 448 && hcont < 476)
          c0 = 0;
        else
          c0 = 1;
      end
      else if (vcont == 2) begin
        if (hcont >= 0 && hcont < 420 || hcont >= 448 && hcont < 476)
          c0 = 0;
        else
          c0 = 1;
      end
      else if (vcont == 312) begin
        if (hcont >= 0 && hcont <28 || hcont >= 448 && hcont < 868)
          c0 = 0;
        else
          c0 = 1;
      end
      else begin
        if (hcont >= 0 && hcont < 67)
          c0 = 0;
        else
          c0 = 1;
      end
    end  
       
    always @(posedge clk) begin
      // Actualización de los contadores. Estoy usando timings como el del Spectrum 48K
      if (hcont == 895) begin
        hcont <= 0;
        if (vcont == 624)     // me como una linea, para que ambos campos duren el mismo número de ciclos. Esto era inicialmente 624.     
          vcont <= 0;
        else
          vcont <= vcont + 1;
      end
      else
        hcont <= hcont + 1;
    end    
    
    reg [10:0] x [1:ETAPAS_PIPELINE];
    reg [10:0] y [1:ETAPAS_PIPELINE];
    reg       hs [1:ETAPAS_PIPELINE];
    reg       vs [1:ETAPAS_PIPELINE];
    reg       cs [1:ETAPAS_PIPELINE];
    reg [7:0] r  [1:ETAPAS_PIPELINE];
    reg [7:0] g  [1:ETAPAS_PIPELINE];
    reg [7:0] b  [1:ETAPAS_PIPELINE];
        
    `define ETP 1
    `define xa   x[`ETP]
    `define ya   y[`ETP]
    `define hsa hs[`ETP]
    `define vsa vs[`ETP]
    `define csa cs[`ETP]
    `define ra   r[`ETP]
    `define ga   g[`ETP]
    `define ba   b[`ETP]
    `define xp   x[`ETP+1]
    `define yp   y[`ETP+1]
    `define hsp hs[`ETP+1]
    `define vsp vs[`ETP+1]
    `define csp cs[`ETP+1]
    `define rp   r[`ETP+1]
    `define gp   g[`ETP+1]
    `define bp   b[`ETP+1]    

    //////////////////////////////////////////////////////////////////////////
    //                       PIXEL PIPELINE                                 // 
    //////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
      ///////////////////////////////////////////////
      // Fondo gris
      ///////////////////////////////////////////////
      if (hcont >= 146)
        `xa <= hcont - 146;
      else
        `xa <= hcont + 750;
      if (vcont >= 23 && vcont < 311)
`ifdef A200T
        `ya <= (vcont - 23)*2 + 1;   // imagen de 576 lineas sólo para A200T  (576i)
`else
        `ya <= (vcont - 23)*2;   // para el resto, uso una imagen de 288 lineas (288p)
`endif        
      else if (vcont >= 335 && vcont < 623)
        `ya <= (vcont - 335)*2;
      else
        `ya <= 10'h3FF;  // coordenada Y fuera de pantalla
        
      `ra  <= 8'h80;
      `ga  <= 8'h80;
      `ba  <= 8'h80;
      
      `hsa <= h0;
      `vsa <= v0;
      `csa <= c0;

      ///////////////////////////////////////////////
      // Rejilla blanca
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if (`xa == 31+40*0  || `xa == 32+40*0  ||   
          `xa == 31+40*1  || `xa == 32+40*1  ||
          `xa == 31+40*2  || `xa == 32+40*2  ||
          `xa == 31+40*3  || `xa == 32+40*3  ||
          `xa == 31+40*4  || `xa == 32+40*4  ||
          `xa == 31+40*5  || `xa == 32+40*5  ||
          `xa == 31+40*6  || `xa == 32+40*6  ||
          `xa == 31+40*7  || `xa == 32+40*7  ||
          `xa == 31+40*8  || `xa == 32+40*8  ||
          `xa == 31+40*9  || `xa == 32+40*9  ||
          `xa == 31+40*10 || `xa == 32+40*10 ||
          `xa == 31+40*11 || `xa == 32+40*11 ||
          `xa == 31+40*12 || `xa == 32+40*12 ||
          `xa == 31+40*13 || `xa == 32+40*13 ||
          `xa == 31+40*14 || `xa == 32+40*14 ||
          `xa == 31+40*15 || `xa == 32+40*15 ||
          `xa == 31+40*16 || `xa == 32+40*16 ||
          `ya == 7+40*0  || `ya == 8+40*0  ||
          `ya == 7+40*1  || `ya == 8+40*1  ||
          `ya == 7+40*2  || `ya == 8+40*2  ||
          `ya == 7+40*3  || `ya == 8+40*3  ||
          `ya == 7+40*4  || `ya == 8+40*4  ||
          `ya == 7+40*5  || `ya == 8+40*5  ||
          `ya == 7+40*6  || `ya == 8+40*6  ||
          `ya == 7+40*7  || `ya == 8+40*7  ||
          `ya == 7+40*8  || `ya == 8+40*8  ||
          `ya == 7+40*9  || `ya == 8+40*9  ||
          `ya == 7+40*10 || `ya == 8+40*10 ||
          `ya == 7+40*11 || `ya == 8+40*11 ||
          `ya == 7+40*12 || `ya == 8+40*12 ||
          `ya == 7+40*13 || `ya == 8+40*13 ||
          `ya == 7+40*14 || `ya == 8+40*14
          ) begin
        `rp <= 8'hFF;
        `gp <= 8'hFF;
        `bp <= 8'hFF;
      end 

      `undef ETP
      `define ETP 2

      ///////////////////////////////////////////////
      // Rectangulo naranja
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa >= 73 && `xa <= 630 && `ya >= 89 && `ya <= 486) begin
        `rp <= 255;
        `gp <= 144;
        `bp <= 56;
      end 

      `undef ETP
      `define ETP 3

      ///////////////////////////////////////////////
      // Castellación
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa < 24 || `xa >= 680 || `ya < 24 || `ya >= 552) begin
        if (`xa >= 40*0  && `xa < 40*1  ||
            `xa >= 40*2  && `xa < 40*3  ||
            `xa >= 40*4  && `xa < 40*5  ||
            `xa >= 40*6  && `xa < 40*7  ||
            `xa >= 40*8  && `xa < 40*9  ||
            `xa >= 40*10 && `xa < 40*11 ||
            `xa >= 40*12 && `xa < 40*13 ||
            `xa >= 40*14 && `xa < 40*15 ||
            `xa >= 40*16 && `xa < 40*17) begin
          if (`ya < 12 || `ya < 564) begin
            `rp <= 8'h00;
            `gp <= 8'h00;
            `bp <= 8'h00;
          end
          else if (`ya >= 564) begin
            `rp <= 8'hFF;
            `gp <= 8'hFF;
            `bp <= 8'hFF;
          end
          else begin
            `rp <= 8'h80;
            `gp <= 8'h80;
            `bp <= 8'h80;
          end
        end
        else if (`xa >= 40*1  && `xa < 40*2  ||
                 `xa >= 40*3  && `xa < 40*4  ||
                 `xa >= 40*5  && `xa < 40*6  ||
                 `xa >= 40*7  && `xa < 40*8  ||
                 `xa >= 40*9  && `xa < 40*10 ||
                 `xa >= 40*11 && `xa < 40*12 ||
                 `xa >= 40*13 && `xa < 40*14 ||
                 `xa >= 40*15 && `xa < 40*16 ||
                 `xa >= 40*17 && `xa < 40*18) begin
          if (`ya < 12) begin
            `rp <= 8'hFF;
            `gp <= 8'hFF;
            `bp <= 8'hFF;
          end
          else if (`ya >= 12 || `ya >= 564) begin
            `rp <= 8'h00;
            `gp <= 8'h00;
            `bp <= 8'h00;
          end
          else begin
            `rp <= 8'h80;
            `gp <= 8'h80;
            `bp <= 8'h80;
          end
        end
      end

      `undef ETP   
      `define ETP 4

      ///////////////////////////////////////////////
      // Circulo base
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

       if (`ya >= 32 && `ya <= 543 && `xa >= 96 && `xa <= 607) begin
         if (`ya <= 207 && `xa <= 351) begin
           if (`xa >= (351 - circulo[`ya-32])) begin
             `rp <= 8'd93;
             `gp <= 8'd149;
             `bp <= 8'd196;
           end
         end
         else if (`ya <= 287 && `xa <= 351) begin
           if (`xa >= (351 - circulo[`ya-32])) begin
             `rp <= 8'd234;
             `gp <= 8'd214;
             `bp <= 8'd61;
           end
         end
         else if (`ya <= 207 && `xa >= 352) begin
           if (`xa <= (352 + circulo[`ya-32])) begin
             `rp <= 8'd93;
             `gp <= 8'd149;
             `bp <= 8'd196;
           end
         end
         else if (`ya <= 287 && `xa >= 352) begin
           if (`xa <= (352 + circulo[`ya-32])) begin
             `rp <= 8'd19;
             `gp <= 8'd15;
             `bp <= 8'd216;
           end
         end
         else if (`ya <= 447 && `xa <= 351) begin
           if (`xa >= (351 - circulo[255 - (`ya - 288)])) begin
             `rp <= 8'h00;
             `gp <= 8'h00;
             `bp <= 8'h00;
           end
         end
         else if (`ya <= 447 && `xa >= 352) begin
           if (`xa <= (352 + circulo[255 - (`ya - 288)])) begin
             `rp <= 8'hFF;
             `gp <= 8'hFF;
             `bp <= 8'hFF;
           end
         end
         else if (`ya <= 488) begin
           if (`xa >= (351 - circulo[255 - (`ya - 288)]) && `xa <= (352 + circulo[255 - (`ya - 288)])) begin
             `rp <= 8'hFF;
             `gp <= 8'hFF;
             `bp <= 8'hFF;
           end
         end
         else begin
           if (`xa >= (351 - circulo[255 - (`ya - 288)]) && `xa <= (352 + circulo[255 - (`ya - 288)])) begin
             `rp <= 8'd93;
             `gp <= 8'd149;
             `bp <= 8'd196;
           end
         end
       end
           
      `undef ETP   
      `define ETP 5

      ///////////////////////////////////////////////
      // Rejilla de barras de frecuencia
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa >= 151 && `xa <= 550 && `ya >= 368 && `ya <= 447) begin
        `rp <= barras[`xa-151];
        `gp <= barras[`xa-151];
        `bp <= barras[`xa-151];
      end
        
      `undef ETP   
      `define ETP 6

      ///////////////////////////////////////////////
      // Barras de color y B/N
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa >= 192 && `xa < 512 && `ya >= 208 && `ya < 368) begin
        if (`xa < 272) begin
          if (`ya < 288) begin
            `rp <= 8'd0;
            `gp <= 8'd225;
            `bp <= 8'd195;
          end
          else begin
            `rp <= 8'd51;
            `gp <= 8'd51;
            `bp <= 8'd51;
          end
        end
        else if (`xa < 352) begin
          if (`ya < 288) begin
            `rp <= 8'd0;
            `gp <= 8'd219;
            `bp <= 8'd46;
          end
          else begin
            `rp <= 8'd102;
            `gp <= 8'd102;
            `bp <= 8'd102;
          end
        end
        else if (`xa < 432) begin
          if (`ya < 288) begin
            `rp <= 8'd231;
            `gp <= 8'd7;
            `bp <= 8'd240;
          end
          else begin
            `rp <= 8'd153;
            `gp <= 8'd153;
            `bp <= 8'd153;
          end
        end
        else begin
          if (`ya < 288) begin
            `rp <= 8'd246;
            `gp <= 8'd31;
            `bp <= 8'd59;
          end
          else begin
            `rp <= 8'd204;
            `gp <= 8'd204;
            `bp <= 8'd204;
          end
        end
      end              

      `undef ETP   
      `define ETP 7

      ///////////////////////////////////////////////
      // Señal de pulso
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa >= 211 && `ya >= 448 && `xa <= 491 && `ya <= 488) begin
        `rp <= 8'h00;
        `gp <= 8'h00;
        `bp <= 8'h00;
        if (`xa == 270 || `xa == 271) begin
          `rp <= 8'hFF;
          `gp <= 8'hFF;
          `bp <= 8'hFF;
        end
      end
      
      `undef ETP   
      `define ETP 8

      ///////////////////////////////////////////////
      // Caja superior
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if (`xa >= 273 && `ya >= 47 && `xa <= 432 && `ya <= 87 && !(`xa >= 283 && `ya >= 57 && `xa <= 422 && `ya <= 77)) begin
        `rp <= 8'hFF;
        `gp <= 8'hFF;
        `bp <= 8'hFF;
      end
      
      //logopixel <= tve[(`ya - 109)*256 + (`xa - 271)];
      logopixel <= logozxtres[(`ya - 116)*256 + (`xa - 224)];
      
      `undef ETP   
      `define ETP 9

      ///////////////////////////////////////////////
      // Identificativo de la cadena (logo ZXTRES)
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if (`xa >= 224 && `ya >= 116 && `xa < (224+256) && `ya < (116+64) ) begin
        if (logopixel != 3'b000) begin
          `rp <= {8{logopixel[2]}};
          `gp <= {8{logopixel[1]}};
          `bp <= {8{logopixel[0]}};
        end  
      end
      
      `undef ETP   
      `define ETP 10

      ///////////////////////////////////////////////
      // Parrilla de centro
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if ( ((`ya == 287 || `ya == 288) && `xa >= 212 && `xa <= 491) ||
           ((`xa == 351 || `xa == 352) && `ya >= 228 && `ya <= 347) ||
           ((`xa == 231 || `xa == 232) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 271 || `xa == 272) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 311 || `xa == 312) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 391 || `xa == 392) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 431 || `xa == 432) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 471 || `xa == 472) && `ya >= 268 && `ya <= 307) ||
           ((`ya == 247 || `ya == 248) && `xa >= 331 && `xa <= 371) ||
           ((`ya == 327 || `ya == 328) && `xa >= 331 && `xa <= 371) ) begin
        `rp <= 8'hFF;
        `gp <= 8'hFF;
        `bp <= 8'hFF;
      end   
      
      `undef ETP   
      `define ETP 11

      ///////////////////////////////////////////////
      // Distinguir zona de blanking de zona activa. Ultima etapa
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if (`ya == 10'h3FF || `xa >= 704) begin
        `rp <= 8'h00;
        `gp <= 8'h00;
        `bp <= 8'h00;
      end

      `undef ETP
      `define ETP 12
      
      ///////////////////////////////////////////////
      // FIN del pipeline
      ///////////////////////////////////////////////
      red     <= `ra;
      green   <= `ga;
      blue    <= `ba;
      hsync_n <= `hsa;
      vsync_n <= `vsa;
      csync_n <= `csa;
    end    
endmodule

`default_nettype wire
