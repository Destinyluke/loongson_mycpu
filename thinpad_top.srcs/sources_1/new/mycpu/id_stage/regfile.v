`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：regfile.v
//  简要说明：此文件是mycpu的寄存器堆，支持同步写和异步读，并且在读操作里面解决了写回-译码相关

//******************************************************************************************************************
`include "defines.v"

module regfile(
    input wire      clk,
    input wire      rst,

    //写端口
    input wire                  we,     //写使能
    input wire[`REG_ADDR_BUS]   wa,     //写地址
    input wire[`REG_BUS]        wd,     //写数据

    //读端口1
    input wire                  re1,    //读使能
    input wire[`REG_ADDR_BUS]   ra1,    //读地址
    output reg[`REG_BUS]        rd1,    //读数据

    //读端口2
    input wire                  re2,    //和上面相同
    input wire[`REG_ADDR_BUS]   ra2,
    output reg[`REG_BUS]        rd2
    );

    reg[`REG_BUS] regs[0:`REG_NUM-1];   //定义32个32位寄存器
    
    //写操作
    always @(posedge clk) begin
        if(rst == `RST_SIGNAL_DISABLE) begin
            if((we == `WRITE_ENABLE) && (wa != `REG_ADDR_NUM'h0)) begin     //写使能，且不是写零号寄存器
                regs[wa] <= wd;
            end
        end
    end

    //读端口1的读操作
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            rd1 <= `ZERO_WORD;
        end
        else if(ra1 == `REG_ADDR_NUM'h0) begin  //读零号寄存器
            rd1 <= `ZERO_WORD;
        end
        else if((ra1 == wa) && (we == `WRITE_ENABLE)    //写回-译码相关
                    && (re1 == `READ_ENABLE)) begin
            rd1 <= wd;                
        end
        else if(re1 == `READ_ENABLE) begin  //正常读出寄存器数据
            rd1 <= regs[ra1];
        end
        else begin
            rd1 <= `ZERO_WORD;
        end
    end

    //读端口2的读操作
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            rd2 <= `ZERO_WORD;
        end
        else if(ra2 == `REG_ADDR_NUM'h0) begin  //读零号寄存器
            rd2 <= `ZERO_WORD;
        end
        else if((ra2 == wa) && (we == `WRITE_ENABLE)    //写回-译码相关
                    && (re2 == `READ_ENABLE)) begin
            rd2 <= wd;                
        end
        else if(re2 == `READ_ENABLE) begin  //正常读出寄存器数据
            rd2 <= regs[ra2];
        end
        else begin
            rd2 <= `ZERO_WORD;
        end
    end    
endmodule
