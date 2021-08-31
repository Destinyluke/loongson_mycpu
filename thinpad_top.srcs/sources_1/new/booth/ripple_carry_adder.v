`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：ripple_carry_adder.v
//  简要说明：此文件设计了一个行波进位加法器，用于wallace tree的最终相加

//******************************************************************************************************************
`include "defines.v"

module ripple_carry_adder#(width=16)(
    input wire[width-1:0] op1,
    input wire[width-1:0] op2,
    input wire cin,
    output wire[width-1:0] sum,
    output wire cout
    );

    wire[width:0] temp;         //用于暂存cin和cout
    assign temp[0] = cin;       //将原始的cin放在temp的最低位
    assign cout = temp[width];  //将最后的cout放在temp的最高位

    genvar i;
    for(i=0;i<width;i=i+1) begin
        full_adder full_adder0(
            .a(op1[i]),
            .b(op2[i]),
            .cin(temp[i]),      //每个加法器的cout就是下一个加法器的cin
            .cout(temp[i+1]),
            .s(sum[i])
        );
    end
    
endmodule
