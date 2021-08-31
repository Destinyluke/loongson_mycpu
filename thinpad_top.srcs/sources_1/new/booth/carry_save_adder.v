`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：carry_save_adder.v
//  简要说明：此文件设计了一个进位保留加法器，它接收3个输入，输出所有进位与和

//******************************************************************************************************************
`include "defines.v"

module carry_save_adder #(width=16)(    //位宽可调，默认值为16
    input wire[width-1:0] op1,  
    input wire[width-1:0] op2,
    input wire[width-1:0] op3,
    output wire[width-1:0] S,   
    output wire[width-1:0] C
    );

    //模块生成
    genvar i;
    generate
        for (i=0;i<width;i=i+1) begin   //调用16次全加器
            full_adder full_adder(
                .a(op1[i]),
                .b(op2[i]),
                .cin(op3[i]),
                .cout(C[i]),
                .s(S[i])
            );
        end
    endgenerate

endmodule
