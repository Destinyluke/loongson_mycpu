`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：wb_stage.v
//  简要说明：此文件是mycpu的写回阶段，将来自访存阶段的数据写回到寄存器堆

//******************************************************************************************************************
// `include "defines.v"

module wb_stage(
    input wire          rst,

    //来自访存阶段的输入
    input wire[`REG_ADDR_BUS]   wa_i,
    input wire                  we_i,
    input wire[`REG_BUS]        wd_i,

    //输出至寄存器堆regfile
    output reg[`REG_ADDR_BUS]   wa_o,
    output reg                  we_o,
    output reg[`REG_BUS]        wd_o
    );

    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            wa_o <= `NOP_REG_ADDR;
            we_o <= `WRITE_DISABLE;
            wd_o <= `ZERO_WORD;
        end
        else begin  //直接将输入写回至寄存器堆regfile
            wa_o <= wa_i;
            we_o <= we_i;
            wd_o <= wd_i;
        end
    end
endmodule
