`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：id_ex.v
//  简要说明：此文件是连接译码和执行阶段的流水寄存器，用于传递两阶段间的信息

//******************************************************************************************************************
`include "defines.v"

module id_ex(
    input wire      clk,
    input wire      rst,

    //从译码阶段id_stage传递过来的信息
    input wire[`ALUOP_BUS]      from_id_aluop,
    input wire[`ALUTYPE_BUS]    from_id_alutype,
    input wire[`REG_BUS]        from_id_src1,
    input wire[`REG_BUS]        from_id_src2,
    input wire[`REG_ADDR_BUS]   from_id_wa,
    input wire                  from_id_we,

    input wire[`REG_BUS]        from_id_link_address,
    input wire                  from_id_is_in_delay_slot,
    input wire                  next_in_delay_slot_i,

    input wire[`REG_BUS]        from_id_inst,

    //传递到执行阶段ex_stage的信息
    output reg[`REG_BUS]        to_ex_link_address,
    output reg                  to_ex_is_in_delay_slot,
    output reg                  is_in_delay_slot_o,

    output reg[`ALUOP_BUS]      to_ex_aluop,
    output reg[`ALUTYPE_BUS]    to_ex_alutype,
    output reg[`REG_BUS]        to_ex_src1,
    output reg[`REG_BUS]        to_ex_src2,
    output reg[`REG_ADDR_BUS]   to_ex_wa,
    output reg                  to_ex_we,

    output reg[`REG_BUS]        to_ex_inst
    );

    
    always @(posedge clk) begin
        //复位时所有信号清零
        if(rst == `RST_SIGNAL_ENABLE) begin
            to_ex_aluop <= `ALUOP_NOP;
            to_ex_alutype <= `NOP;
            to_ex_src1 <= `ZERO_WORD;
            to_ex_src2 <= `ZERO_WORD;
            to_ex_wa <= `NOP_REG_ADDR;
            to_ex_we <= `WRITE_DISABLE;
            to_ex_link_address <= `ZERO_WORD;
            to_ex_is_in_delay_slot <= `NOT_IN_DELAY_SLOT;
            is_in_delay_slot_o <= `NOT_IN_DELAY_SLOT;
            to_ex_inst <= `ZERO_WORD;
        end
        //其他时候在时钟上升沿直接将输入赋给输出
        else begin
            to_ex_aluop <= from_id_aluop;
            to_ex_alutype <= from_id_alutype;
            to_ex_src1 <= from_id_src1;
            to_ex_src2 <= from_id_src2;
            to_ex_wa <= from_id_wa;
            to_ex_we <= from_id_we;
            to_ex_link_address <= from_id_link_address;
            to_ex_is_in_delay_slot <= from_id_is_in_delay_slot;
            is_in_delay_slot_o <= next_in_delay_slot_i;
            to_ex_inst <= from_id_inst;
        end
    end
endmodule
