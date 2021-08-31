`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：mem_stage.v
//  简要说明：此文件是mycpu的访存阶段，将来自执行阶段的数据传输到写回阶段，并且负责在运行加载存储指令的时候，
//           与sram和uart进行交互

//******************************************************************************************************************
`include "defines.v"

module mem_stage(
    input wire          rst,

    //来自执行阶段的信息
    input wire[`REG_ADDR_BUS]   wa_i,
    input wire                  we_i,
    input wire[`REG_BUS]        wd_i,

    input wire[`ALUOP_BUS]      aluop_i,
    input wire[`REG_BUS]        mem_address_i,
    input wire[`REG_BUS]        src2_i,

    //来自SRAM的信息
    input wire[`REG_BUS]        sram_data_i,    //SRAM的数据输入

    //来自uart的信息
    input wire[`REG_BUS]        uart_data_i,    //UART的数据输入

    //送到写回阶段的输出
    output reg[`REG_ADDR_BUS]   wa_o,
    output reg                  we_o,
    output reg[`REG_BUS]        wd_o,

    //送到SRAM和UART的输出
    output reg[`REG_BUS]        mem_address_o,     //访问地址
    output reg                  mem_we_o,       //写使能，低电平使能
    output reg[3:0]             mem_select_o,   //字节选择，低电平使能
    output reg[`REG_BUS]        mem_data_o,     //数据输出
    output reg                  mem_chip_enable_o        //芯片使能，低电平使能
    );

    //通过mem_addr_i来从sram_data_i和uart_data_i中挑选出要处理的输入数据
    wire[`REG_BUS] mem_data_i;
    //当mem_addr_i不访问串口的状态和数据时，赋sram_data_i，否则赋uart_data_i
    assign mem_data_i = ((mem_address_i != `SERIAL_STATE_ADDR) && (mem_address_i != `SERIAL_DATA_ADDR)) ? sram_data_i: uart_data_i;

    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            wa_o <= `NOP_REG_ADDR;
            we_o <= `WRITE_DISABLE;
            wd_o <= `ZERO_WORD;
            mem_address_o <= `ZERO_WORD;
            mem_we_o <= `WRITE_DISABLE;
            mem_select_o <= 4'b1111;
            mem_data_o <= `ZERO_WORD;
            mem_chip_enable_o <= `CHIP_DISABLE;
        end
        else begin  //默认值
            wa_o <= wa_i;
            we_o <= we_i;
            wd_o <= wd_i;
            mem_address_o <= `ZERO_WORD;
            mem_we_o <= `WRITE_DISABLE;
            mem_select_o <= 4'b0000;    //字节全部允许
            mem_data_o <= `ZERO_WORD;
            mem_chip_enable_o <= `CHIP_DISABLE;
            case(aluop_i)
                `ALUOP_LB: begin    //lb指令
                    mem_address_o <= mem_address_i;
                    mem_we_o <= `WRITE_DISABLE;
                    mem_chip_enable_o <= `CHIP_ENABLE;
                    //根据地址的后两位，对输入的数据进行处理，取某8位处于wd_o的最低8位，并进行符号扩展
                    case(mem_address_i[1:0])   //小端顺序，低位放在低地址
                        2'b00: begin    
                            wd_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};  //取mem_data_i的低8位
                            mem_select_o <= 4'b1110;
                        end
                        2'b01: begin
                            wd_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};    //取mem_data_i的[15:8]
                            mem_select_o <= 4'b1101;
                        end
                        2'b10: begin
                            wd_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};   //取mem_data_i的[23:16]
                            mem_select_o <= 4'b1011;
                        end
                        2'b11: begin
                            wd_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};   //取mem_data_i的高8位
                            mem_select_o <= 4'b0111;
                        end
                        default: begin
                            wd_o <= `ZERO_WORD;
                        end
                    endcase
                end
                `ALUOP_LW: begin    //lw指令
                    mem_address_o <= mem_address_i;
                    mem_we_o <= `WRITE_DISABLE;
                    wd_o <= mem_data_i;
                    mem_select_o <= 4'b0000;
                    mem_chip_enable_o <= `CHIP_ENABLE;
                end
                `ALUOP_SB: begin    //sb指令
                    mem_address_o <= mem_address_i;
                    mem_we_o <= `WRITE_ENABLE;
                    //将要写的8位数据复制4份，成为32位的输出，再根据字节选择信号，在sram模块决定最后写入哪块sram
                    mem_data_o <= {src2_i[7:0],src2_i[7:0],
                                src2_i[7:0],src2_i[7:0]};
                    mem_chip_enable_o <= `CHIP_ENABLE;
                    case(mem_address_i[1:0])   //小端顺序，低位放在低地址
                        2'b00: begin
                            mem_select_o <= 4'b1110;
                        end
                        2'b01: begin
                            mem_select_o <= 4'b1101;
                        end
                        2'b10: begin
                            mem_select_o <= 4'b1011;
                        end
                        2'b11: begin
                            mem_select_o <= 4'b0111;
                        end
                        default: begin
                            mem_select_o <= 4'b1111;
                        end
                    endcase
                end
                `ALUOP_SW: begin    //sw指令
                    mem_address_o <= mem_address_i;
                    mem_we_o <= `WRITE_ENABLE;
                    mem_data_o <= src2_i;
                    mem_select_o <= 4'b0000;
                    mem_chip_enable_o <= `CHIP_ENABLE;
                end
                default:begin
                end
            endcase
        end
    end
endmodule
