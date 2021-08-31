`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：ex_mem.v
//  简要说明：此文件是连接执行和访存阶段的流水寄存器，用于传递两阶段间的信息

//******************************************************************************************************************
`include "defines.v"

module ex_mem(
    input wire          clk,
    input wire          rst,

    //来自执行阶段的信息
    input wire[`REG_ADDR_BUS]   from_ex_wa,  //写地址
    input wire                  from_ex_we,  //写使能
    input wire[`REG_BUS]        from_ex_wd,  //写数据

    //用于加载存储指令的输入
    input wire[`ALUOP_BUS]      from_ex_aluop,
    input wire[`REG_BUS]        from_ex_mem_address,
    input wire[`REG_BUS]        from_ex_src2,

    //送到访存阶段的信息
    output reg[`REG_ADDR_BUS]   to_mem_wa,
    output reg                  to_mem_we,
    output reg[`REG_BUS]        to_mem_wd,

    output reg[`ALUOP_BUS]      to_mem_aluop,
    output reg[`REG_BUS]        to_mem_mem_address,
    output reg[`REG_BUS]        to_mem_src2  
    );

    always @(posedge clk) begin
        //复位时所有信号清零
        if(rst == `RST_SIGNAL_ENABLE) begin
            to_mem_wa <= `NOP_REG_ADDR;
            to_mem_we <= `WRITE_DISABLE;
            to_mem_wd <= `ZERO_WORD;
            to_mem_aluop <= `ALUOP_NOP;
            to_mem_mem_address <= `ZERO_WORD;
            to_mem_src2 <= `ZERO_WORD;
        end
        //其它时候在时钟上升沿直接将输入赋给输出
        else begin
            to_mem_wa <= from_ex_wa;
            to_mem_we <= from_ex_we;
            to_mem_wd <= from_ex_wd;
            to_mem_aluop <= from_ex_aluop;
            to_mem_mem_address <= from_ex_mem_address;
            to_mem_src2 <= from_ex_src2;
        end
    end
endmodule
