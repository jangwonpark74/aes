//======================================================================
//
// aes.core.v
// ----------
// The AES core. This core supports key size of 128, 192 and 256 bits.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2013, 2014, Secworks Sweden AB
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or 
// without modification, are permitted provided that the following 
// conditions are met: 
// 
// 1. Redistributions of source code must retain the above copyright 
//    notice, this list of conditions and the following disclaimer. 
// 
// 2. Redistributions in binary form must reproduce the above copyright 
//    notice, this list of conditions and the following disclaimer in 
//    the documentation and/or other materials provided with the 
//    distribution. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module aes_core(
                input wire            clk,
                input wire            reset_n,
                   
                input wire            encdec,
                input wire            init,
                input wire            next,
                output wire           ready,
                
                input wire [255 : 0]  key,
                input wire [1 : 0]    keylen,
                   
                input wire [127 : 0]  block,
                output wire [127 : 0] result,
                output wire           result_valid
               );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter AES_128_BIT_KEY = 0;
  parameter AES_192_BIT_KEY = 1;
  parameter AES_256_BIT_KEY = 2;

  parameter AES128_ROUNDS = 10;
  parameter AES192_ROUNDS = 12;
  parameter AES256_ROUNDS = 14;
  
  parameter CTRL_IDLE   = 0;
  parameter CTRL_INIT   = 1;
  parameter CTRL_ROUNDS = 2;
  parameter CTRL_DONE   = 3;
  
  
  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [255 : 0] key_reg;
  reg [1 : 0]   keylen_reg;
  reg           encdec_reg;
  reg           init_we;

  reg [7 : 0]   s00_reg;
  reg [7 : 0]   s00_new;
  reg [7 : 0]   s01_reg;
  reg [7 : 0]   s01_new;
  reg [7 : 0]   s02_reg;
  reg [7 : 0]   s02_new;
  reg [7 : 0]   s03_reg;
  reg [7 : 0]   s03_new;

  reg [7 : 0]   s10_reg;
  reg [7 : 0]   s10_new;
  reg [7 : 0]   s11_reg;
  reg [7 : 0]   s11_new;
  reg [7 : 0]   s12_reg;
  reg [7 : 0]   s12_new;
  reg [7 : 0]   s13_reg;
  reg [7 : 0]   s13_new;

  reg [7 : 0]   s20_reg;
  reg [7 : 0]   s20_new;
  reg [7 : 0]   s21_reg;
  reg [7 : 0]   s21_new;
  reg [7 : 0]   s22_reg;
  reg [7 : 0]   s22_new;
  reg [7 : 0]   s23_reg;
  reg [7 : 0]   s23_new;

  reg [7 : 0]   s30_reg;
  reg [7 : 0]   s30_new;
  reg [7 : 0]   s31_reg;
  reg [7 : 0]   s31_new;
  reg [7 : 0]   s32_reg;
  reg [7 : 0]   s32_new;
  reg [7 : 0]   s33_reg;
  reg [7 : 0]   s33_new;
  
  reg           s_we;
  
  reg           ready_reg;
  reg           ready_new;
  reg           ready_we;

  reg           result_valid_reg;
  reg           result_valid_new;
  reg           result_valid_we;

  reg [3 : 0]   num_rounds;

  reg [3 : 0]   round_ctr_reg;
  reg [3 : 0]   round_ctr_new;
  reg           round_ctr_we;
  reg           round_ctr_rst;
  reg           round_ctr_inc;
  
  reg [2 : 0]   aes_ctrl_reg;
  reg [2 : 0]   aes_ctrl_new;
  reg           aes_ctrl_we;
  
  
  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [7 : 0] tmp_data;
  
  reg init_state;
  reg update_state;
  
  
  //----------------------------------------------------------------
  // Instantiations.
  //----------------------------------------------------------------
  aes_encipher_round enc_round(
                               .block(block),
                               .round_key(round_key),
                               .round_type(round_type),
                               .s00(s00_reg),
                               .s01(s01_reg),
                               .s02(s02_reg),
                               .s03(s03_reg),
                               .s10(s10_reg),
                               .s11(s11_reg),
                               .s12(s12_reg),
                               .s13(s13_reg),
                               .s20(s20_reg),
                               .s21(s21_reg),
                               .s22(s22_reg),
                               .s23(s23_reg),
                               .s30(s30_reg),
                               .s31(s31_reg),
                               .s32(s32_reg),
                               .s33(s33_reg),
                               .s00_new(enc_s00_new),
                               .s01_new(enc_s01_new),
                               .s02_new(enc_s02_new),
                               .s03_new(enc_s03_new),
                               .s10_new(enc_s10_new),
                               .s11_new(enc_s11_new),
                               .s12_new(enc_s12_new),
                               .s13_new(enc_s13_new),
                               .s20_new(enc_s20_new),
                               .s21_new(enc_s21_new),
                               .s22_new(enc_s22_new),
                               .s23_new(enc_s23_new),
                               .s30_new(enc_s30_new),
                               .s31_new(enc_s31_new),
                               .s32_new(enc_s32_new),
                               .s33_new(enc_s33_new)
                              );


  aes_decipher_round dec_round(
                               .block(block),
                               .round_key(round_key),
                               .round_type(round_type),
                               .s00(s00_reg),
                               .s01(s01_reg),
                               .s02(s02_reg),
                               .s03(s03_reg),
                               .s10(s10_reg),
                               .s11(s11_reg),
                               .s12(s12_reg),
                               .s13(s13_reg),
                               .s20(s20_reg),
                               .s21(s21_reg),
                               .s22(s22_reg),
                               .s23(s23_reg),
                               .s30(s30_reg),
                               .s31(s31_reg),
                               .s32(s32_reg),
                               .s33(s33_reg),
                               .s00_new(dec_s00_new),
                               .s01_new(dec_s01_new),
                               .s02_new(dec_s02_new),
                               .s03_new(dec_s03_new),
                               .s10_new(dec_s10_new),
                               .s11_new(dec_s11_new),
                               .s12_new(dec_s12_new),
                               .s13_new(dec_s13_new),
                               .s20_new(dec_s20_new),
                               .s21_new(dec_s21_new),
                               .s22_new(dec_s22_new),
                               .s23_new(dec_s23_new),
                               .s30_new(dec_s30_new),
                               .s31_new(dec_s31_new),
                               .s32_new(dec_s32_new),
                               .s33_new(dec_s33_new)
                              );
  
  
  aes_keygen keygen(
                    .clk(clk),
                    .reset_n(reset_n),
                    .key(key),
                    .keylen(keylen),
                    .encdec(encdec),
                    .init(init),
                    .addr(key_number),

                    .round_key(round_key),
                    .ready(key_ready)
                   );


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign ready        = ready_reg;
  assign result       = block_reg;
  assign result_valid = result_valid_reg;
  
  
  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin: reg_update
      if (!reset_n)
        begin
          ready_reg        <= 1'b0;
          result_valid_reg <= 1'b0;
          key_reg          <= 128'h00000000000000000000000000000000;
          keylen_reg       <= 2'h0;
          encdec_reg       <= 1'b0;
          s00_reg          <= 8'h00;
          s01_reg          <= 8'h00;
          s02_reg          <= 8'h00;
          s03_reg          <= 8'h00;
          s10_reg          <= 8'h00;
          s11_reg          <= 8'h00;
          s12_reg          <= 8'h00;
          s13_reg          <= 8'h00;
          s20_reg          <= 8'h00;
          s21_reg          <= 8'h00;
          s22_reg          <= 8'h00;
          s23_reg          <= 8'h00;
          s30_reg          <= 8'h00;
          s31_reg          <= 8'h00;
          s32_reg          <= 8'h00;
          s33_reg          <= 8'h00;

          round_ctr_reg    <= 4'h0;
          
          aes_ctrl_reg     <= CTRL_IDLE;
        end
      else
        begin
          if (ready_we)
            begin
              ready_reg <= ready_new;
            end

          if (result_valid_we)
            begin
              result_valid_reg <= result_valid_new;
            end
          
          if (init_we)
            begin
              key_reg    <= key;
              keylen_reg <= keylen;
              encdec_reg <= encdec;
            end

          if (s_we)
            begin
              s00_reg <= s00_new;
              s01_reg <= s01_new;
              s02_reg <= s02_new;
              s03_reg <= s03_new;

              s10_reg <= s10_new;
              s11_reg <= s11_new;
              s12_reg <= s12_new;
              s13_reg <= s13_new;

              s20_reg <= s20_new;
              s21_reg <= s21_new;
              s22_reg <= s22_new;
              s23_reg <= s23_new;

              s30_reg <= s30_new;
              s31_reg <= s31_new;
              s32_reg <= s32_new;
              s33_reg <= s33_new;
            end

          if (round_ctr_we)
            begin
              round_ctr_reg <= round_ctr_new;
            end
          
          if (aes_ctrl_we)
            begin
              aes_ctrl_reg <= aes_ctrl_new;
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // rounds_select
  //
  // Simple logic that selects number of rounds based on the given
  // key length.
  //----------------------------------------------------------------
  always @*
    begin : rounds_select
      case (keylen_reg)
        AES_128_BIT_KEY: num_rounds = AES128_ROUNDS;
        AES_192_BIT_KEY: num_rounds = AES192_ROUNDS;
        AES_256_BIT_KEY: num_rounds = AES256_ROUNDS;
        default:         num_rounds = 4'h0;
      endcase // case (keylen_reg)
    end // rounds_select


  //----------------------------------------------------------------
  // state_logic
  //
  // The logic needed to initalize as well as update the internal
  // state during round processing.
  //----------------------------------------------------------------
  always @*
    begin : state_update_logic

    end // state_logic


  //----------------------------------------------------------------
  // round_ctr
  //
  // The round counter with reset and increase logic.
  //----------------------------------------------------------------
  always @*
    begin : round_ctr
      round_ctr_new = 4'h0;
      round_ctr_we  = 1'b0;

      if (round_ctr_rst)
        begin
          round_ctr_we  = 1'b1;
        end
      elsif (round_ctr_inc)
        begin
          round_ctr_new = round_ctr_reg + 1'b1;
          round_ctr_we  = 1'b0;
        end
    end // round_ctr

  
  //----------------------------------------------------------------
  // aes_ctrl_fsm
  //
  // The control FSM that runs the core.
  //----------------------------------------------------------------
  always @*
    begin : aes_ctrl_fsm
      ready_new        = 0;
      ready_we         = 0;
      result_valid_new = 0;
      result_valid_we  = 0;
      init_we          = 0;
      init_state       = 0;
      round_ctr_rst    = 0;
      round_ctr_inc    = 0;
      update_state     = 0;
      aes_ctrl_new     = CTRL_IDLE;
      aes_ctrl_we      = 0;
      
      case (aes_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                init_we      = 1;
                aes_ctrl_new = CTRL_INIT;
                aes_ctrl_we  = 1;
              end
          end

        CTRL_INIT:
          begin
            aes_ctrl_new = CTRL_ROUNDS;
            aes_ctrl_we  = 1;
          end

        CTRL_ROUNDS:
          begin
            aes_ctrl_new = CTRL_DONE;
            aes_ctrl_we  = 1;
          end
          

        CTRL_DONE:
          begin
            aes_ctrl_new = CTRL_IDLE;
            aes_ctrl_we  = 1;
          end

        
        default:
          begin

          end
      endcase // case (aes_ctrl_reg)
    end // aes_ctrl_fsm
    
endmodule // aes_core

//======================================================================
// EOF aes_core.v
//======================================================================
