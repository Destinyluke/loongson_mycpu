`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：full_adder.v
//  简要说明：此文件设计了一个简单的全加器

//******************************************************************************************************************
`include "defines.v"

module full_adder(
    input wire a,
    input wire b,
    input wire cin,
    output wire cout,
    output wire s
    );

    assign s = a ^ b ^ cin;     //和为三个输入的异或
    assign cout = (a & b) | (cin & (a ^ b));    //输出进位为产生进位或传递进位

endmodule
