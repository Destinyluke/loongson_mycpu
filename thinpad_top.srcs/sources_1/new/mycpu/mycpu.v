`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：mycpu.v
//  简要说明：此文件是mycpu的顶层模块，用于例化各流水线阶段和流水线寄存器，
//           并将它们连接起来

//******************************************************************************************************************
`include "defines.v"

module mycpu(
    input wire              rst,
    input wire              clk,

    //与指令有关的信号
    input wire[`REG_BUS]    inst_data_i,
    output wire[`REG_BUS]   inst_address_o,
    output wire             inst_chip_enable_o,

    //与数据有关的信号
    input wire[`REG_BUS]    sram_data_i,
    output wire[`REG_BUS]   ram_address_o,
    output wire[`REG_BUS]   ram_data_o,
    output wire             ram_we_o,
    output wire[3:0]        ram_select_o,
    output wire             ram_chip_enable_o,

    //连接到uart
    input wire[`REG_BUS]    uart_data_i
    );

    //连接if/id模块输出与译码阶段id_stage模块输入的变量
    wire[`INSTRUCTION_ADDR_BUS] pc;
    wire[`INSTRUCTION_ADDR_BUS] id_stage_pc_i;
    wire[`INSTRUCTION_BUS] id_stage_inst_i;
    
    //连接译码阶段id_stage模块输出与id/ex模块输入的变量
    wire[`ALUOP_BUS] id_stage_aluop_o;
    wire[`ALUTYPE_BUS] id_stage_alutype_o;
    wire[`REG_BUS] id_stage_src1_o;
    wire[`REG_BUS] id_stage_src2_o;
    wire id_stage_we_o;
    wire[`REG_ADDR_BUS] id_stage_wa_o;
    wire id_stage_is_in_delay_slot_o;
    wire[`REG_BUS] id_stage_link_address_o;
    wire[`REG_BUS] id_stage_inst_o;

    //连接id/ex模块输出与执行阶段ex_stage模块输入的变量
    wire[`ALUOP_BUS] ex_stage_aluop_i;
    wire[`ALUTYPE_BUS] ex_stage_alutype_i;
    wire[`REG_BUS] ex_stage_src1_i;
    wire[`REG_BUS] ex_stage_src2_i;
    wire ex_stage_we_i;
    wire[`REG_ADDR_BUS] ex_stage_wa_i;
    wire ex_stage_is_in_delay_slot_i;
    wire[`REG_BUS] ex_stage_link_address_i;
    wire[`REG_BUS] ex_stage_inst_i;

    //连接执行阶段ex_stage模块输出与ex/mem模块输入的变量
    wire ex_stage_we_o;
    wire[`REG_ADDR_BUS] ex_stage_wa_o;
    wire[`REG_BUS] ex_stage_wd_o;
    wire[`ALUOP_BUS] ex_stage_aluop_o;
    wire[`REG_BUS] ex_stage_mem_address_o;
    wire[`REG_BUS] ex_stage_src2_o;

    //连接ex/mem模块的输出与访存阶段mem_stage模块输入的变量
    wire mem_stage_we_i;
    wire[`REG_ADDR_BUS] mem_stage_wa_i;
    wire[`REG_BUS] mem_stage_wd_i;
    wire[`ALUOP_BUS] mem_stage_aluop_i;
    wire[`REG_BUS] mem_stage_mem_address_i;
    wire[`REG_BUS] mem_stage_src2_i;

    //连接访存阶段mem_stage模块输出与mem/wb模块输入的变量
    wire mem_stage_we_o;
    wire[`REG_ADDR_BUS] mem_stage_wa_o;
    wire[`REG_BUS] mem_stage_wd_o;

    //连接mem/wb模块的输出与写回阶段wb_stage的输入的变量
    wire wb_stage_we_i;
    wire[`REG_ADDR_BUS] wb_stage_wa_i;
    wire[`REG_BUS] wb_stage_wd_i;

    //连接写回阶段wb_stage模块输出与通用寄存器regfile模块的变量
    wire wb_stage_we_o;
    wire[`REG_ADDR_BUS] wb_stage_wa_o;
    wire[`REG_BUS] wb_stage_wd_o;

    //连接译码阶段id_stage模块与通用寄存器regfile模块的变量
    wire reg1_read;
    wire reg2_read;
    wire[`REG_BUS] reg1_data;
    wire[`REG_BUS] reg2_data;
    wire[`REG_ADDR_BUS] reg1_address;
    wire[`REG_ADDR_BUS] reg2_address;

    //与转移指令有关的延迟槽变量
    wire is_in_delay_slot_i;
    wire is_in_delay_slot_o;
    wire next_in_delay_slot_o;

    //与转移指令有关的转移变量
    wire jump_flag;
    wire[`REG_BUS] jump_address;

    //流水线暂停
    wire[1:0] stall;
    wire stall_request_from_id;

    //if_stage模块例化
    if_stage if_stage(
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .chip_enable(inst_chip_enable_o),
        .stall(stall),
        .jump_flag_i(jump_flag),
        .jump_address_i(jump_address)
    );

    assign inst_address_o = pc; //指令存储器的输入地址为pc

    //if/id模块例化
    if_id if_id(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .from_if_pc(pc),
        .from_if_inst(inst_data_i),
        .to_id_pc(id_stage_pc_i),
        .to_id_inst(id_stage_inst_i)
    );

    //id_stage模块例化
    id_stage id_stage(
        .rst(rst),
        .pc_i(id_stage_pc_i),
        .inst_i(id_stage_inst_i),

        //来自regfile模块的输入
        .reg1_data_i(reg1_data),
        .reg2_data_i(reg2_data),

        //处于执行阶段的指令要写入的信息（执行-译码相关）
        .ex_we_i(ex_stage_we_o),
        .ex_wd_i(ex_stage_wd_o),
        .ex_wa_i(ex_stage_wa_o),

        //处于访存阶段的指令要写入的信息（访存-译码相关）
        .mem_we_i(mem_stage_we_o),
        .mem_wd_i(mem_stage_wd_o),
        .mem_wa_i(mem_stage_wa_o),

        .is_in_delay_slot_i(is_in_delay_slot_i),
        
        //送到regfile模块的输出
        .reg1_read_o(reg1_read),
        .reg2_read_o(reg2_read),
        .reg1_address_o(reg1_address),
        .reg2_address_o(reg2_address),

        //送到id/ex模块的输出
        .aluop_o(id_stage_aluop_o),
        .alutype_o(id_stage_alutype_o),
        .src1_o(id_stage_src1_o),
        .src2_o(id_stage_src2_o),
        .wa_o(id_stage_wa_o),
        .we_o(id_stage_we_o),
        .inst_o(id_stage_inst_o),

        //与转移指令有关
        .next_in_delay_slot_o(next_in_delay_slot_o),
        .jump_flag_o(jump_flag),
        .jump_address_o(jump_address),
        .link_address_o(id_stage_link_address_o),

        .is_in_delay_slot_o(id_stage_is_in_delay_slot_o),

        .stall_request_from_id(stall_request_from_id)
    );

    //regfile模块例化
    regfile regfile(
        .clk(clk),
        .rst(rst),
        .we(wb_stage_we_o),
        .wa(wb_stage_wa_o),
        .wd(wb_stage_wd_o),
        .re1(reg1_read),
        .ra1(reg1_address),
        .rd1(reg1_data),
        .re2(reg2_read),
        .ra2(reg2_address),
        .rd2(reg2_data)
    );

    //id/ex模块例化
    id_ex id_ex(
        .clk(clk),
        .rst(rst),

        //从译码阶段id_stage模块传递过来的信息
        .from_id_aluop(id_stage_aluop_o),
        .from_id_alutype(id_stage_alutype_o),
        .from_id_src1(id_stage_src1_o),
        .from_id_src2(id_stage_src2_o),
        .from_id_we(id_stage_we_o),
        .from_id_wa(id_stage_wa_o),
        .from_id_link_address(id_stage_link_address_o),
        .from_id_is_in_delay_slot(id_stage_is_in_delay_slot_o),
        .next_in_delay_slot_i(next_in_delay_slot_o),
        .from_id_inst(id_stage_inst_o),

        //传递到执行阶段ex_stage模块的信息
        .to_ex_aluop(ex_stage_aluop_i),
        .to_ex_alutype(ex_stage_alutype_i),
        .to_ex_src1(ex_stage_src1_i),
        .to_ex_src2(ex_stage_src2_i),
        .to_ex_wa(ex_stage_wa_i),
        .to_ex_we(ex_stage_we_i),
        .to_ex_link_address(ex_stage_link_address_i),
        .to_ex_is_in_delay_slot(ex_stage_is_in_delay_slot_i),
        .is_in_delay_slot_o(is_in_delay_slot_i),
        .to_ex_inst(ex_stage_inst_i)
    );

    //ex_stage模块例化
    ex_stage ex_stage(
        .rst(rst),

        //从id/ex模块传递过来的信息
        .aluop_i(ex_stage_aluop_i),
        .alutype_i(ex_stage_alutype_i),
        .src1_i(ex_stage_src1_i),
        .src2_i(ex_stage_src2_i),
        .wa_i(ex_stage_wa_i),
        .we_i(ex_stage_we_i),
        .inst_i(ex_stage_inst_i),

        .link_address_i(ex_stage_link_address_i),
        .is_in_delay_slot_i(ex_stage_is_in_delay_slot_i),

        //传递到ex/mem模块的信息
        .wa_o(ex_stage_wa_o),
        .we_o(ex_stage_we_o),
        .wd_o(ex_stage_wd_o),
        
        .aluop_o(ex_stage_aluop_o),
        .mem_address_o(ex_stage_mem_address_o),
        .src2_o(ex_stage_src2_o)
    );

    //ex/mem模块例化
    ex_mem ex_mem(
        .clk(clk),
        .rst(rst),

        //来自执行阶段ex_stage的信息
        .from_ex_wa(ex_stage_wa_o),
        .from_ex_we(ex_stage_we_o),
        .from_ex_wd(ex_stage_wd_o),

        .from_ex_aluop(ex_stage_aluop_o),
        .from_ex_mem_address(ex_stage_mem_address_o),
        .from_ex_src2(ex_stage_src2_o),

        //传递到访存阶段mem_stage的信息
        .to_mem_wa(mem_stage_wa_i),
        .to_mem_we(mem_stage_we_i),
        .to_mem_wd(mem_stage_wd_i),

        .to_mem_aluop(mem_stage_aluop_i),
        .to_mem_mem_address(mem_stage_mem_address_i),
        .to_mem_src2(mem_stage_src2_i)
    );

    //mem_stage模块例化
    mem_stage mem_stage(
        .rst(rst),

        //来自ex/mem模块的信息
        .wa_i(mem_stage_wa_i),
        .we_i(mem_stage_we_i),
        .wd_i(mem_stage_wd_i),

        .aluop_i(mem_stage_aluop_i),
        .mem_address_i(mem_stage_mem_address_i),
        .src2_i(mem_stage_src2_i),

        //来自数据存储器的信息
        .sram_data_i(sram_data_i),

        //来自uart的信息
        .uart_data_i(uart_data_i),

        //送到mem/wb模块的信息
        .wa_o(mem_stage_wa_o),
        .we_o(mem_stage_we_o),
        .wd_o(mem_stage_wd_o),

        //送到数据存储器和uart的信息
        .mem_address_o(ram_address_o),
        .mem_we_o(ram_we_o),
        .mem_select_o(ram_select_o),
        .mem_data_o(ram_data_o),
        .mem_chip_enable_o(ram_chip_enable_o)
    );

    //mem/wb模块例化
    mem_wb mem_wb(
        .clk(clk),
        .rst(rst),

        //来自访存阶段mem_stage模块的信息
        .from_mem_wa(mem_stage_wa_o),
        .from_mem_we(mem_stage_we_o),
        .from_mem_wd(mem_stage_wd_o),

        //送到写回阶段wb_stage的信息
        .to_wb_wa(wb_stage_wa_i),
        .to_wb_we(wb_stage_we_i),
        .to_wb_wd(wb_stage_wd_i)
    );

    //wb_stage模块例化
    wb_stage wb_stage(
        .rst(rst),

        //来自mem/wb模块的信息
        .wa_i(wb_stage_wa_i),
        .we_i(wb_stage_we_i),
        .wd_i(wb_stage_wd_i),

        //送到寄存器堆regfile的信息
        .wa_o(wb_stage_wa_o),
        .we_o(wb_stage_we_o),
        .wd_o(wb_stage_wd_o)
    );

    //流水线暂停控制模块control例化
    control control(
        .clk(clk),
        .rst(rst),
        .stall_request_from_id(stall_request_from_id),
        .stall(stall)
    );
endmodule
