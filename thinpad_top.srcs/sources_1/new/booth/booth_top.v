`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：booth.top.v
//  简要说明：此文件是32位booth乘法器的顶层模块，它调用各乘法器模块，先利用乘数B进行booth编码，产生输出系数。再根据输出
//           系数和被乘数A，产生相应的16个部分和。将得到的16个部分和按照wallace树结构进行排列和相加，得到最终的sum和carry

//******************************************************************************************************************
`include "defines.v"

module booth_top(
    input wire[`REG_BUS] A,     //32位被乘数补码输入
    input wire[`REG_BUS] B,     //32位乘数补码输入
    output wire[`DOUBLE_REG_BUS] P           //64位乘法结果输出
    );
    wire[`COEFFICIENT_BUS] coefficient0;     //16个输出系数
    wire[`COEFFICIENT_BUS] coefficient1;
    wire[`COEFFICIENT_BUS] coefficient2;
    wire[`COEFFICIENT_BUS] coefficient3;
    wire[`COEFFICIENT_BUS] coefficient4;
    wire[`COEFFICIENT_BUS] coefficient5;
    wire[`COEFFICIENT_BUS] coefficient6;
    wire[`COEFFICIENT_BUS] coefficient7;
    wire[`COEFFICIENT_BUS] coefficient8;
    wire[`COEFFICIENT_BUS] coefficient9;
    wire[`COEFFICIENT_BUS] coefficient10;
    wire[`COEFFICIENT_BUS] coefficient11;
    wire[`COEFFICIENT_BUS] coefficient12;
    wire[`COEFFICIENT_BUS] coefficient13;
    wire[`COEFFICIENT_BUS] coefficient14;
    wire[`COEFFICIENT_BUS] coefficient15;
    wire negative0;
    wire negative1;
    wire negative2;
    wire negative3;
    wire negative4;
    wire negative5;
    wire negative6;
    wire negative7;
    wire negative8;
    wire negative9;
    wire negative10;
    wire negative11;
    wire negative12;
    wire negative13;
    wire negative14;
    wire negative15;

    booth_encode booth_encode0(
        .code({B[1:0],1'b0}),
        .coefficient(coefficient0),
        .negative(negative0)
    ); 
                
    booth_encode booth_encode1(
        .code(B[3:1]),
        .coefficient(coefficient1),
        .negative(negative1)
    );

    booth_encode booth_encode2(
        .code(B[5:3]),
        .coefficient(coefficient2),
        .negative(negative2)
    );

    booth_encode booth_encode3(
        .code(B[7:5]),
        .coefficient(coefficient3),
        .negative(negative3)
    );

    booth_encode booth_encode4(
        .code(B[9:7]),
        .coefficient(coefficient4),
        .negative(negative4)
    );

    booth_encode booth_encode5(
        .code(B[11:9]),
        .coefficient(coefficient5),
        .negative(negative5)
    );

    booth_encode booth_encode6(
        .code(B[13:11]),
        .coefficient(coefficient6),
        .negative(negative6)
    );

    booth_encode booth_encode7(
        .code(B[15:13]),
        .coefficient(coefficient7),
        .negative(negative7)
    );    

   booth_encode booth_encode8(
        .code(B[17:15]),
        .coefficient(coefficient8),
        .negative(negative8)
    );        

   booth_encode booth_encode9(
        .code(B[19:17]),
        .coefficient(coefficient9),
        .negative(negative9)
    );    

   booth_encode booth_encode10(
        .code(B[21:19]),
        .coefficient(coefficient10),
        .negative(negative10)
    );    

   booth_encode booth_encode11(
        .code(B[23:21]),
        .coefficient(coefficient11),
        .negative(negative11)
    );    

   booth_encode booth_encode12(
        .code(B[25:23]),
        .coefficient(coefficient12),
        .negative(negative12)
    );    

   booth_encode booth_encode13(
        .code(B[27:25]),
        .coefficient(coefficient13),
        .negative(negative13)
    );    

   booth_encode booth_encode14(
        .code(B[29:27]),
        .coefficient(coefficient14),
        .negative(negative14)
    );    

   booth_encode booth_encode15(
        .code(B[31:29]),
        .coefficient(coefficient15),
        .negative(negative15)
    );    

    wire[`DOUBLE_REG_BUS] prod0;    //16个部分和
    wire[`DOUBLE_REG_BUS] prod1;
    wire[`DOUBLE_REG_BUS] prod2;
    wire[`DOUBLE_REG_BUS] prod3;
    wire[`DOUBLE_REG_BUS] prod4;
    wire[`DOUBLE_REG_BUS] prod5;
    wire[`DOUBLE_REG_BUS] prod6;
    wire[`DOUBLE_REG_BUS] prod7;
    wire[`DOUBLE_REG_BUS] prod8;
    wire[`DOUBLE_REG_BUS] prod9;
    wire[`DOUBLE_REG_BUS] prod10;
    wire[`DOUBLE_REG_BUS] prod11;
    wire[`DOUBLE_REG_BUS] prod12;
    wire[`DOUBLE_REG_BUS] prod13;
    wire[`DOUBLE_REG_BUS] prod14;
    wire[`DOUBLE_REG_BUS] prod15;
    
    generate_product generate_product0(         //根据16组输出系数，调用16次generate_product模块，产生16个部分和
                .A(A),
                .coefficient(coefficient0),
                .negative(negative0),
                .product(prod0)
            );
    
    generate_product generate_product1(
                .A(A),
                .coefficient(coefficient1),
                .negative(negative1),
                .product(prod1)
            );

    generate_product generate_product2(
                .A(A),               
                .coefficient(coefficient2),
                .negative(negative2),
                .product(prod2)
            );

    generate_product generate_product3(
                .A(A),
                .coefficient(coefficient3),
                .negative(negative3),
                .product(prod3)
            );

    generate_product generate_product4(
                .A(A),
                .coefficient(coefficient4),
                .negative(negative4),
                .product(prod4)
            );

    generate_product generate_product5(
                .A(A),
                .coefficient(coefficient5),
                .negative(negative5),
                .product(prod5)
            );

    generate_product generate_product6(
                .A(A),
                .coefficient(coefficient6),
                .negative(negative6),
                .product(prod6)
            ); 

    generate_product generate_product7(
                .A(A),
                .coefficient(coefficient7),
                .negative(negative7),
                .product(prod7)
            );  

    generate_product generate_product8(
                .A(A),
                .coefficient(coefficient8),
                .negative(negative8),
                .product(prod8)
            );  
    
    generate_product generate_product9(
                .A(A),
                .coefficient(coefficient9),
                .negative(negative9),
                .product(prod9)
            );  

    generate_product generate_product10(
                .A(A),
                .coefficient(coefficient10),
                .negative(negative10),
                .product(prod10)
            );  

    generate_product generate_product11(
                .A(A),
                .coefficient(coefficient11),
                .negative(negative11),
                .product(prod11)
            );  

    generate_product generate_product12(
                .A(A),
                .coefficient(coefficient12),
                .negative(negative12),
                .product(prod12)
            );  

    generate_product generate_product13(
                .A(A),
                .coefficient(coefficient13),
                .negative(negative13),
                .product(prod13)
            );  
    
    generate_product generate_product14(
                .A(A),
                .coefficient(coefficient14),
                .negative(negative14),
                .product(prod14)
            );      

    generate_product generate_product15(
                .A(A),
                .coefficient(coefficient15),
                .negative(negative15),
                .product(prod15)
            );  

    wallace_tree wallace_tree(      //将16个部分和按wallace树的形式相加，得到最终结果
        .prod0(prod0),
        .prod1(prod1),
        .prod2(prod2),
        .prod3(prod3),
        .prod4(prod4),
        .prod5(prod5),
        .prod6(prod6),
        .prod7(prod7),
        .prod8(prod8),
        .prod9(prod9),
        .prod10(prod10),
        .prod11(prod11),
        .prod12(prod12),
        .prod13(prod13),
        .prod14(prod14),
        .prod15(prod15),
        .P(P)
    );
endmodule