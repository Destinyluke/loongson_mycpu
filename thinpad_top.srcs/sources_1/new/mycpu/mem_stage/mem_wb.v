`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：mem_wb.v
//  简要说明：此文件是连接访存和写回阶段的流水寄存器，用于传递两阶段间的信息

//******************************************************************************************************************
`include "defines.v"

module mem_wb(
    input wire          clk,
    input wire          rst,

    //来自访存阶段的信息
    input wire[`REG_ADDR_BUS]   from_mem_wa,
    input wire                  from_mem_we,
    input wire[`REG_BUS]        from_mem_wd,

    //送到回写阶段的信息
    output reg[`REG_ADDR_BUS]   to_wb_wa,
    output reg                  to_wb_we,
    output reg[`REG_BUS]        to_wb_wd
    );

    always @(posedge clk) begin
        //复位时所有信号清零
        if(rst == `RST_SIGNAL_ENABLE) begin
            to_wb_wa <= `NOP_REG_ADDR;
            to_wb_we <= `WRITE_DISABLE;
            to_wb_wd <= `ZERO_WORD;
        end
        //其他时候在时钟上升沿直接把输入赋给输出
        else begin
            to_wb_wa <= from_mem_wa;
            to_wb_we <= from_mem_we;
            to_wb_wd <= from_mem_wd;
        end
    end
endmodule
