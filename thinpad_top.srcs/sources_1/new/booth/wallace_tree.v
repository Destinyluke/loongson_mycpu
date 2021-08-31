`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：wallace_tree.v
//  简要说明：此文件设计了一个wallace树结构，可求解sum和carry

//******************************************************************************************************************
`include "defines.v"

module wallace_tree(
    input wire[`DOUBLE_REG_BUS] prod0,		//输入为16个部分和
    input wire[`DOUBLE_REG_BUS] prod1,
	input wire[`DOUBLE_REG_BUS] prod2,
	input wire[`DOUBLE_REG_BUS] prod3,
	input wire[`DOUBLE_REG_BUS] prod4,
	input wire[`DOUBLE_REG_BUS] prod5,
	input wire[`DOUBLE_REG_BUS] prod6,
	input wire[`DOUBLE_REG_BUS] prod7,
	input wire[`DOUBLE_REG_BUS] prod8,
	input wire[`DOUBLE_REG_BUS] prod9,
	input wire[`DOUBLE_REG_BUS] prod10,
	input wire[`DOUBLE_REG_BUS] prod11,
	input wire[`DOUBLE_REG_BUS] prod12,
	input wire[`DOUBLE_REG_BUS] prod13,
	input wire[`DOUBLE_REG_BUS] prod14,
	input wire[`DOUBLE_REG_BUS] prod15,
    output wire[`DOUBLE_REG_BUS] P		//输出为64位的最终结果
    );

wire [`DOUBLE_REG_BUS] sum_level01;		//level01的和输出
wire [`DOUBLE_REG_BUS] carry_level01;	//level01的进位输出
wire [`DOUBLE_REG_BUS] sum_level02;		//level02的和输出
wire [`DOUBLE_REG_BUS] carry_level02;	//level02的进位输出
wire [`DOUBLE_REG_BUS] sum_level03;		//level03的和输出
wire [`DOUBLE_REG_BUS] carry_level03;	//level03的进位输出
wire [`DOUBLE_REG_BUS] sum_level04;		//level04的和输出
wire [`DOUBLE_REG_BUS] carry_level04;	//level04的进位输出
wire [`DOUBLE_REG_BUS] sum_level05;		//level05的和输出
wire [`DOUBLE_REG_BUS] carry_level05;	//level05的进位输出

wire [`DOUBLE_REG_BUS] sum_level11;		//level11的和输出
wire [`DOUBLE_REG_BUS] carry_level11;	//level11的进位输出
wire [`DOUBLE_REG_BUS] sum_level12;		//level12的和输出
wire [`DOUBLE_REG_BUS] carry_level12;	//level12的进位输出
wire [`DOUBLE_REG_BUS] sum_level13;		//level13的和输出
wire [`DOUBLE_REG_BUS] carry_level13;	//level13的进位输出

wire [`DOUBLE_REG_BUS] sum_level21;		//level21的和输出
wire [`DOUBLE_REG_BUS] carry_level21;	//level21的进位输出
wire [`DOUBLE_REG_BUS] sum_level22;		//level22的和输出
wire [`DOUBLE_REG_BUS] carry_level22;	//level22的进位输出

wire [`DOUBLE_REG_BUS] sum_level31;		//level31的和输出
wire [`DOUBLE_REG_BUS] carry_level31;	//level31的进位输出
wire [`DOUBLE_REG_BUS] sum_level32;		//level32的和输出
wire [`DOUBLE_REG_BUS] carry_level32;	//level32的进位输出

wire [`DOUBLE_REG_BUS] sum_level41;		//level41的和输出
wire [`DOUBLE_REG_BUS] carry_level41;	//level41的进位输出

wire [`DOUBLE_REG_BUS] sum_level51;		//level51的和输出
wire [`DOUBLE_REG_BUS] carry_level51;	//level51的进位输出

wire final_cout;				//用于存放最终的进位输出

//level 0
carry_save_adder #(64) csa_level01(		
	.op1(prod0),
	.op2(prod1<<2),
	.op3(prod2<<4),
	.S(sum_level01),
	.C(carry_level01)
);

carry_save_adder #(64) csa_level02(
	.op1(prod3<<6),
	.op2(prod4<<8),
	.op3(prod5<<10),
	.S(sum_level02),
	.C(carry_level02)
);

carry_save_adder #(64) csa_level03(
	.op1(prod6<<12),
	.op2(prod7<<14),
	.op3(prod8<<16),
	.S(sum_level03),
	.C(carry_level03)
);

carry_save_adder #(64) csa_level04(
	.op1(prod9<<18),
	.op2(prod10<<20),
	.op3(prod11<<22),
	.S(sum_level04),
	.C(carry_level04)
);

carry_save_adder #(64) csa_level05(
	.op1(prod12<<24),
	.op2(prod13<<26),
	.op3(prod14<<28),
	.S(sum_level05),
	.C(carry_level05)
);

//level 1
carry_save_adder #(64) csa_level11(
	.op1(sum_level01),
	.op2(carry_level01<<1),
	.op3(sum_level02),
	.S(sum_level11),
	.C(carry_level11)
);

carry_save_adder #(64) csa_level12(
	.op1(carry_level02<<1),
	.op2(sum_level03),
	.op3(carry_level03<<1),
	.S(sum_level12),
	.C(carry_level12)
);

carry_save_adder #(64) csa_level13(
	.op1(sum_level04),
	.op2(carry_level04<<1),
	.op3(sum_level05),
	.S(sum_level13),
	.C(carry_level13)
);

//level 2
carry_save_adder #(64) csa_level21(
	.op1(sum_level11),
	.op2(carry_level11<<1),
	.op3(sum_level12),
	.S(sum_level21),
	.C(carry_level21)
);

carry_save_adder #(64) csa_level22(
	.op1(carry_level12<<1),
	.op2(sum_level13),
	.op3(carry_level13<<1),
	.S(sum_level22),
	.C(carry_level22)
);

//level 3
carry_save_adder #(64) csa_level31(
	.op1(sum_level21),
	.op2(carry_level21<<1),
	.op3(sum_level22),
	.S(sum_level31),
	.C(carry_level31)
);

carry_save_adder #(64) csa_level32(
	.op1(carry_level22<<1),
	.op2(prod15<<30),
	.op3(carry_level05<<1),
	.S(sum_level32),
	.C(carry_level32)
);

//level 4
carry_save_adder #(64) csa_level41(
	.op1(sum_level31),
	.op2(carry_level31<<1),
	.op3(sum_level32),
	.S(sum_level41),
	.C(carry_level41)
);

//level 5
carry_save_adder #(64) csa_level51(
	.op1(sum_level41),
	.op2(carry_level41<<1),
	.op3(carry_level32<<1),
	.S(sum_level51),
	.C(carry_level51)
);

//最终相加，采用行波进位加法器
ripple_carry_adder #(64) final_adder (
    .op1(sum_level51), 
    .op2(carry_level51<<1),
    .cin(1'b0),
    .sum(P),
    .cout(final_cout)
);
endmodule
