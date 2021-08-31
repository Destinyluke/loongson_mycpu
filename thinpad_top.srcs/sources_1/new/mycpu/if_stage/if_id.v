`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：if_id.v
//  简要说明：此文件是连接取指和译码阶段的流水寄存器，用于传递两阶段间的信息

//******************************************************************************************************************
`include "defines.v"

module if_id(
    input wire      clk,
    input wire      rst,

    //来自流水线暂停控制模块control的信息
    input wire[1:0] stall,

    //来自取指阶段if_stage的信号
    input wire[`INSTRUCTION_ADDR_BUS] from_if_pc,
    input wire[`INSTRUCTION_BUS]      from_if_inst,

    //输出至译码阶段id_stage的信号
    output reg[`INSTRUCTION_ADDR_BUS] to_id_pc,
    output reg[`INSTRUCTION_BUS]      to_id_inst
    );

    always @(posedge clk) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            to_id_pc <= `ZERO_WORD;    //复位的时候pc为0
            to_id_inst <= `ZERO_WORD;  //复位的时候指令为0
        end
        //流水线暂停
        else if(stall[1] == `STOP) begin
            to_id_pc <= `ZERO_WORD;
            to_id_inst <= `ZERO_WORD;
        end
        //流水线不暂停时，直接将输入赋给输出
        else if(stall[1] == `NO_STOP) begin
            to_id_pc <= from_if_pc;
            to_id_inst <= from_if_inst;
        end
    end
endmodule
