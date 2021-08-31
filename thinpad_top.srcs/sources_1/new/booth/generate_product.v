`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：generate_product.v
//  简要说明：此文件用于根据booth_encode生成的输出系数，产生不同的部分和，在后面的模块相加

//******************************************************************************************************************
`include "defines.v"

module generate_product(
    input wire[`REG_BUS] A,     //数据输入
    input wire[`COEFFICIENT_BUS] coefficient, //booth_encode生成的系数
    input wire      negative,    //判断部分和是否是负数
    output wire[`DOUBLE_REG_BUS] product   //部分和输出
    );

    reg[`DOUBLE_REG_BUS] product_pre;  //用于保存中间数值

    always @(*) begin
        product_pre <= 64'd0;
        if(coefficient == `ZERO) begin  //当系数是zero时，部分和为0
            product_pre <= 64'd0; 
        end
        else if(coefficient == `ONE) begin  //当系数是1时，部分和为被乘数
            product_pre <= {{32{A[31]}},A};
        end
        else if(coefficient == `TWO) begin  //当系数是2时，部分和为被乘数左移1位
            product_pre <= {{31{A[31]}},A,1'b0};
        end
    end

    //最后输出由negative决定，若是负数则取补码，若是正数则取原码
    assign product = negative? (~product_pre + 1'b1) : product_pre;

endmodule
