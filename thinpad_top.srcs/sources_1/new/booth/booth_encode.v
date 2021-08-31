`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：booth_encode.v
//  简要说明：此文件参照booth编码表，根据输入码字，输出相应的系数

//******************************************************************************************************************
`include "defines.v"

module booth_encode(
    input wire[`CODE_BUS] code,
    output reg[`COEFFICIENT_BUS] coefficient,    //输出系数
    output reg negative     //用于判断部分和是否是负数
    );
    always @(*) begin
        if((code == 3'b000) || (code == 3'b111)) begin //code为000和111时，输出系数为0
            coefficient <= `ZERO;
        end
        else if((code == 3'b100) || (code == 3'b011)) begin //code为100和011时，输出系数为2
            coefficient <= `TWO;
        end
        else begin  //其他时候输出系数为1
            coefficient <= `ONE;
        end
        if(code[2] == 1) begin  //code[2]为1时，部分和为负数；code[2]为0时，部分和为正数
            negative <= `NEGATIVE;
        end
        else begin
            negative <= `POSITIVE;
        end
    end
    
endmodule
