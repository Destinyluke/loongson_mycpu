`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：ex_stage.v
//  简要说明：此文件是mycpu的执行阶段，根据aluop对源操作数进行相应的运算，并根据alutype选出最终输出的数据，传输给访存阶段

//******************************************************************************************************************
`include "defines.v"

module ex_stage(
    input wire              rst,

    //来自译码阶段的信息
    input wire[`ALUOP_BUS]      aluop_i,
    input wire[`ALUTYPE_BUS]    alutype_i,
    input wire[`REG_BUS]        src1_i,
    input wire[`REG_BUS]        src2_i,
    input wire[`REG_ADDR_BUS]   wa_i,
    input wire                  we_i,

    input wire[`REG_BUS]        inst_i,

    //处于执行阶段的转移指令要保存的返回地址
    input wire[`REG_BUS]        link_address_i,

    //当前执行阶段的指令是否位于延迟槽
    input wire                  is_in_delay_slot_i,

    //执行阶段的输出
    output reg[`REG_ADDR_BUS]   wa_o,   //写地址
    output reg                  we_o,   //写使能
    output reg[`REG_BUS]        wd_o,   //写数据

    //用于加载存储指令
    output wire[`ALUOP_BUS]     aluop_o,    //aluop的值
    output wire[`REG_BUS]       mem_address_o, //需要访问的sram或uart的地址
    output wire[`REG_BUS]       src2_o      //存储指令的操作数
    );

    reg[`REG_BUS] logicout;     //保存逻辑运算输出
    reg[`REG_BUS] shiftout;     //保存移位运算输出
    reg[`REG_BUS] arithmeticout;    //保存算术运算输出
    reg[`DOUBLE_REG_BUS] mulout;    //保存乘法运算64位结果

    wire[`REG_BUS] src2_i_mux;    //保存输入的第二个操作数的补码
    wire[`REG_BUS] src1_i_not;    //保存输入的第一个操作数的反码
    wire[`REG_BUS] sum_result;    //保存加法结果
    wire reg1_less_than_reg2;  //判断第一个操作数是否小于第二个操作数

    wire[`REG_BUS] mult_data1;  //乘法中的被乘数
    wire[`REG_BUS] mult_data2;  //乘法中的乘数
    wire[`DOUBLE_REG_BUS] mul_temp; //临时保存乘法结果

    assign src2_i_mux = ((aluop_i == `ALUOP_SLT) || (aluop_i == `ALUOP_SUBU)) ? (~src2_i)+1 : src2_i;

    assign src1_i_not = ~src1_i;

    assign sum_result = src1_i + src2_i_mux;
    
    assign reg1_less_than_reg2 = ((src1_i[31] && !src2_i[31]) ||
                        (!src1_i[31] && !src2_i[31] && sum_result[31]) ||
                        (src1_i[31] && src2_i[31] && sum_result[31]));

    //下面得到三个用于加载存储指令的结果
    assign aluop_o = aluop_i;          
    assign mem_address_o = src1_i + {{16{inst_i[15]}},inst_i[15:0]}; //数据存储器地址为基址加上offset符号扩展为32位后的值
    assign src2_o = src2_i;        

    /******************第一部分：根据aluop的类型进行运算*****************/
    //逻辑运算
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            logicout <= `ZERO_WORD;
        end
        else begin
            case(aluop_i)
                `ALUOP_OR,`ALUOP_ORI,`ALUOP_LUI: begin       //逻辑或运算
                    logicout <= src1_i | src2_i;
                end
                `ALUOP_AND,`ALUOP_ANDI: begin     //逻辑与运算
                    logicout <= src1_i & src2_i;    
                end
                `ALUOP_XOR,`ALUOP_XORI: begin     //逻辑异或运算
                    logicout <= src1_i ^ src2_i;
                end
                default: begin
                    logicout <= `ZERO_WORD;    
                end
            endcase //endcase
        end //endif
    end //endalways

    //移位运算
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            shiftout <= `ZERO_WORD;
        end
        else begin
            case(aluop_i)
                `ALUOP_SLL,`ALUOP_SLLV: begin  
                    shiftout <= src2_i << src1_i[4:0];  //逻辑左移
                end
                `ALUOP_SRL: begin
                    shiftout <= src2_i >> src1_i[4:0];  //逻辑右移
                end
                default: begin
                    shiftout <= `ZERO_WORD;
                end
            endcase //endcase
        end //endif
    end //endalways

    //算术运算
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            arithmeticout <= `ZERO_WORD;
        end
        else begin
            case(aluop_i)
                `ALUOP_SLT: begin
                    arithmeticout <= reg1_less_than_reg2;  //比较运算
                end
                `ALUOP_SUBU: begin
                    arithmeticout <= sum_result;    //减法运算
                end
                `ALUOP_ADDU,`ALUOP_ADDIU: begin
                    arithmeticout <= sum_result;    //加法运算
                end
                `ALUOP_CLZ: begin   //计数运算clz
                    arithmeticout <= src1_i[31] ? 0 : src1_i[30] ? 1 :
                                   src1_i[29] ? 2 : src1_i[28] ? 3 :
                                   src1_i[27] ? 4 : src1_i[26] ? 5 :
                                   src1_i[25] ? 6 : src1_i[24] ? 7 : 
                                   src1_i[23] ? 8 : src1_i[22] ? 9 :
                                   src1_i[21] ? 10 : src1_i[20] ? 11 :
                                   src1_i[19] ? 12 : src1_i[18] ? 13 :
                                   src1_i[17] ? 14 : src1_i[16] ? 15 :
                                   src1_i[15] ? 16 : src1_i[14] ? 17 :
                                   src1_i[13] ? 18 : src1_i[12] ? 19 :
                                   src1_i[11] ? 20 : src1_i[10] ? 21 :
                                   src1_i[9] ? 22 : src1_i[8] ? 23 :
                                   src1_i[7] ? 24 : src1_i[6] ? 25 :
                                   src1_i[5] ? 26 : src1_i[4] ? 27 :
                                   src1_i[3] ? 28 : src1_i[2] ? 29 :
                                   src1_i[1] ? 30 : src1_i[0] ? 31 : 32;
                end
                `ALUOP_CLO: begin   //计数运算clo
                    arithmeticout <= src1_i_not[31] ? 0 : src1_i_not[30] ? 1 :
                                    src1_i_not[29] ? 2 : src1_i_not[28] ? 3 :
                                    src1_i_not[27] ? 4 : src1_i_not[26] ? 5 :
                                    src1_i_not[25] ? 6 : src1_i_not[24] ? 7 :
                                    src1_i_not[23] ? 8 : src1_i_not[22] ? 9 :
                                    src1_i_not[21] ? 10 : src1_i_not[20] ? 11 :
                                    src1_i_not[19] ? 12 : src1_i_not[18] ? 13 :
                                    src1_i_not[17] ? 14 : src1_i_not[16] ? 15 :
                                    src1_i_not[15] ? 16 : src1_i_not[14] ? 17 :
                                    src1_i_not[13] ? 18 : src1_i_not[12] ? 19 :
                                    src1_i_not[11] ? 20 : src1_i_not[10] ? 21 :
                                    src1_i_not[9] ? 22 : src1_i_not[8] ? 23 :
                                    src1_i_not[7] ? 24 : src1_i_not[6] ? 25 :
                                    src1_i_not[5] ? 26 : src1_i_not[4] ? 27 :
                                    src1_i_not[3] ? 28 : src1_i_not[2] ? 29 :
                                    src1_i_not[1] ? 30 : src1_i_not[0] ? 31 : 32;
                end
                default: begin
                    arithmeticout <= `ZERO_WORD; 
                end 
            endcase //endcase
        end //endif
    end //endalways

    // 乘法运算(这里采用了让vivado自动综合的乘法实现方法)
    assign mult_data1 = ((aluop_i == `ALUOP_MUL) &&     //若被乘数是正数，则mult_data1为被乘数原值；若被乘数是负数，则mult_data2为被乘数补码
                    (src1_i[31] == 1'b1)) ? (~src1_i + 1) : src1_i;

    assign mult_data2 = ((aluop_i == `ALUOP_MUL) &&     //若乘数是正数，则mult_data2为乘数原值；若乘数是负数，则mult_data2为乘数补码
                    (src2_i[31] == 1'b1)) ? (~src2_i + 1) : src2_i;

    assign mul_temp = mult_data1 * mult_data2;      //直接采用了*号，让vivado自动综合出乘法器电路

    //对乘法结果作出修正
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            mulout <= {`ZERO_WORD,`ZERO_WORD};
        end
        else if(aluop_i == `ALUOP_MUL) begin
            if(src1_i[31] ^ src2_i[31]) begin   //若两乘数异号，则乘法结果应是mul_temp的补码
                mulout <= ~mul_temp + 1;
            end
            else begin  //若两乘数同号，则乘法结果就是mul_temp
                mulout <= mul_temp;
            end
        end
        else begin
            mulout <= {`ZERO_WORD,`ZERO_WORD};
        end
    end   

    // // 乘法运算(这里采用了电路级实现乘法器的方法，调用32位booth乘法模块，输入的是补码)    
    // assign mult_data1 = (aluop_i == `ALUOP_MUL)? (~src1_i) + 1'b1: src1_i;   //得到源操作数1的补码
    // assign mult_data2 = (aluop_i == `ALUOP_MUL)? (~src2_i) + 1'b1: src2_i;   //得到源操作数2的补码 
      
    // booth_top booth_top0(
    //     .A(mult_data1),
    //     .B(mult_data2),
    //     .P(mul_temp)
    // );


    /******************第二部分：根据alutype的类型选择最终结果*****************/
    always @(*) begin
        wa_o <= wa_i;   //写目的寄存器地址
        we_o <= we_i;   //判断是否要写目的寄存器
        case(alutype_i)
            `LOGIC: begin
                wd_o <= logicout;   //选择逻辑运算结果为最后输出
            end
            `SHIFT: begin
                wd_o <= shiftout;   //选择移位运算结果为最后输出
            end
            `ARITHMETIC: begin
                wd_o <= arithmeticout;  //选择算术操作结果为最后输出
            end
            `MUL: begin
                wd_o <= mulout[31:0];   //选择乘法运算结果低32位为最后输出
                // wd_o <= mul_temp[31:0];

            end
            `BRANCH: begin     
                wd_o <= link_address_i;     //选择加载存储指令默认写地址为最后输出
            end
            default: begin
                wd_o <= `ZERO_WORD;
            end
        endcase
    end
endmodule
