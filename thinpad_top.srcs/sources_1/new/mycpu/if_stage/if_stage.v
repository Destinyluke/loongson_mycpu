`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：if_stage.v
//  简要说明：此文件是mycpu的取指阶段，负责决定pc的值，从而从sram中取出指令

//******************************************************************************************************************
`include "defines.v"

module if_stage(
    input wire      clk,
    input wire      rst,
    input wire[1:0] stall,  //暂停信号输入

    //与分支跳转指令有关的输入信号
    input wire              jump_flag_i,    //分支跳转标志
    input wire[`REG_BUS]    jump_address_i,    //分支跳转地址

    output reg[`INSTRUCTION_ADDR_BUS] pc,
    output reg      chip_enable
    );

    always @(posedge clk) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            chip_enable <= `CHIP_DISABLE;    //复位信号有效时芯片禁止
        end
        else begin
            chip_enable <= `CHIP_ENABLE;     //其它时候芯片使能
        end
    end

    always @(posedge clk) begin
        if(chip_enable == `CHIP_DISABLE) begin
            pc <= 32'h8000_0000;     //芯片禁止时，pc为初始值8000_0000
        end
        else if(stall[0] == `NO_STOP) begin //流水线不暂停时
            if(jump_flag_i == `JUMP) begin
                pc <= jump_address_i;  //进行分支跳转
            end
            else begin
                pc <= pc + 4'h4;        //其它情况，pc的值每时钟周期加4
            end
        end
    end
endmodule
