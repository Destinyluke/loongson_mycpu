`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：sram.v
//  简要说明：此文件是sram控制器，用于进行mycpu的访存阶段和sram的交互

//******************************************************************************************************************
`include "defines.v"

module sram(
    input wire          clk,
    input wire          rst,

    //来自取指阶段的输入和输出信号，用于地址操作
    input wire[`INSTRUCTION_ADDR_BUS]  pc_i,   //指令地址输入
    input wire                  chip_enable_i,   //读指令使能信号
    output reg[`INSTRUCTION_BUS]       inst_o, //指令输出

    //来自访存阶段的输入和输出信号，用于数据操作
    input wire[`REG_BUS]        mem_address_i, //地址输入
    input wire                  mem_we_i,   //写使能输入
    input wire[3:0]             mem_select_i,    //位选择输入
    input wire[`REG_BUS]        mem_data_i, //数据输入
    input wire                  mem_chip_enable_i,   //芯片使能输入
    output reg[`REG_BUS]        sram_data_o,  //sram的数据输出

    //连接BaseRAM的信号
    inout wire[31:0]           base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output reg[19:0]           base_ram_addr,  //BaseRAM地址
    output reg[3:0]            base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg                 base_ram_ce_n,  //BaseRAM片选，低有效
    output reg                 base_ram_oe_n,  //BaseRAM读使能，低有效
    output reg                 base_ram_we_n,  //BaseRAM写使能，低有效

    //连接ExtRAM的信号
    inout wire[31:0]           ext_ram_data,   //ExtRAM数据
    output reg[19:0]           ext_ram_addr,   //ExtRAM地址
    output reg[3:0]            ext_ram_be_n,   //ExtRAM字节使能，低有效，如果不使用字节使能，请保持为0
    output reg                 ext_ram_ce_n,   //ExtRAM片选，低有效
    output reg                 ext_ram_oe_n,   //ExtRAM读使能，低有效
    output reg                 ext_ram_we_n    //ExtRAM写使能，低有效
    );

    //用于判断是否选中base_ram和ext_ram
    wire use_base_ram_or_not, use_ext_ram_or_not;
    //当mem_addr_i不访问串口状态和数据，并且mem_addr_i位于8000_0000-803F_FFFF之间时，访问base_ram
    assign use_base_ram_or_not = (mem_address_i != `SERIAL_STATE_ADDR) && (mem_address_i != `SERIAL_DATA_ADDR)
                                && (mem_address_i >= 32'h8000_0000) && (mem_address_i < 32'h8040_0000);
    //当mem_addr_i不访问串口状态和数据，并且mem_addr_i位于8040_0000-807F_FFFF之间时，访问ext_ram                          
    assign use_ext_ram_or_not = (mem_address_i != `SERIAL_STATE_ADDR) && (mem_address_i != `SERIAL_DATA_ADDR)
                                && (mem_address_i >= 32'h8040_0000) && (mem_address_i < 32'h8080_0000);
    
    //BaseRAM控制器
    //base_ram_data是inout信号，当要对base_ram进行数据操作，并且是写时，才在信号上赋值，其他时候都给高阻态，让存储器去访问此线路
    assign base_ram_data = (use_base_ram_or_not == `USE_BASE_RAM)? ((mem_we_i == `WRITE_ENABLE)? mem_data_i:`HIGH_RESISTANCE):`HIGH_RESISTANCE;  

    //用于暂存结果
    reg[31:0] baseram_data_o,extram_data_o;

    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            base_ram_addr <= 20'h00000;
            base_ram_be_n <= 4'b1111;
            base_ram_ce_n <= `CHIP_DISABLE;
            base_ram_oe_n <= `READ_DISABLE;
            base_ram_we_n <= `WRITE_DISABLE;
            inst_o <= `ZERO_WORD;
            baseram_data_o <= `ZERO_WORD;
        end
        else if(use_base_ram_or_not == `USE_BASE_RAM) begin     //对base_ram的数据操作
            base_ram_addr <= mem_address_i[21:2];  //数据地址访问
            base_ram_be_n <= mem_select_i;  //位选信号直接赋值
            base_ram_ce_n <= `CHIP_ENABLE;
            base_ram_oe_n <= !mem_we_i;     //写使能取反便是读使能
            base_ram_we_n <= mem_we_i;
            inst_o <= `ZERO_WORD;
            baseram_data_o <= base_ram_data;
        end
        else begin  //对base_ram的读指令操作
            base_ram_addr <= pc_i[21:2];    //pc输入
            base_ram_be_n <= 4'b0000;       //字节全选，所以4位0
            base_ram_ce_n <= chip_enable_i;
            base_ram_oe_n <= `READ_ENABLE;  //读使能
            base_ram_we_n <= `WRITE_DISABLE;    //此时不能写
            inst_o <= base_ram_data;        //此时数据线上是指令，将其赋给inst_o
            baseram_data_o <= `ZERO_WORD;
        end
    end

    //ExtRAM控制器
    //ext_ram_data是inout信号，当要对ext_ram进行数据操作，并且是写时，才在信号上赋值，其他时候都给高阻态，让存储器去访问此线路
    assign ext_ram_data = (mem_we_i == `WRITE_ENABLE)? mem_data_i:`HIGH_RESISTANCE;  

    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            ext_ram_addr <= 20'h00000;
            ext_ram_be_n <= 4'b1111;
            ext_ram_ce_n <= `CHIP_DISABLE;
            ext_ram_oe_n <= `READ_DISABLE;
            ext_ram_we_n <= `WRITE_DISABLE;
            extram_data_o <= `ZERO_WORD;
        end
        else if(use_ext_ram_or_not == `USE_EXT_RAM) begin   //对extRAM的数据操作
            ext_ram_addr <= mem_address_i[21:2];   //数据地址访问
            ext_ram_be_n <= mem_select_i;   //位选信号直接赋值
            ext_ram_ce_n <= `CHIP_ENABLE;
            ext_ram_oe_n <= !mem_we_i;  //写使能取反便是读使能
            ext_ram_we_n <= mem_we_i;
            extram_data_o <= ext_ram_data;
        end
        else begin  //extRAM不存在读指令操作，因此else为默认态
            ext_ram_addr <= 20'h00000;
            ext_ram_be_n <= 4'b1111;
            ext_ram_ce_n <= `CHIP_DISABLE;
            ext_ram_oe_n <= `READ_DISABLE;
            ext_ram_we_n <= `WRITE_DISABLE;
            extram_data_o <= `ZERO_WORD;
        end
    end

    //根据use_base_ram_or_not和use_ext_ram_or_not信号，选择最终输出的sram_data_o
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            sram_data_o <= `ZERO_WORD;
        end
        else if(use_base_ram_or_not == `USE_BASE_RAM) begin     //最终输出为baseram_data_o
            sram_data_o <= baseram_data_o;
        end
        else if(use_ext_ram_or_not == `USE_EXT_RAM) begin   //最终输出为extram_data_o
            sram_data_o <= extram_data_o;
        end
        else begin
            sram_data_o <= `ZERO_WORD;
        end 
    end
endmodule