`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：id_stage.v
//  简要说明：此文件是mycpu的译码阶段，用于对指令进行译码，并将相应的数据传输给执行阶段运算

//******************************************************************************************************************
`include "defines.v"

module id_stage(
    input wire                  rst,
    input wire[`INSTRUCTION_ADDR_BUS]  pc_i,
    input wire[`INSTRUCTION_BUS]       inst_i,

    //读取的regfile的值
    input wire[`REG_BUS]        reg1_data_i,
    input wire[`REG_BUS]        reg2_data_i,

    //处于执行阶段的指令的运算结果，用于解决执行-译码相关
    input wire                  ex_we_i,    //写使能
    input wire[`REG_BUS]        ex_wd_i,    //写数据
    input wire[`REG_ADDR_BUS]   ex_wa_i,    //写地址

    //处于访存阶段的指令的运算结果，用于解决访存-译码相关
    input wire                  mem_we_i,   //写使能
    input wire[`REG_BUS]        mem_wd_i,   //写数据
    input wire[`REG_ADDR_BUS]   mem_wa_i,   //写地址

    input wire                  is_in_delay_slot_i,     //当前指令是否处于延迟槽中

    output reg                  next_in_delay_slot_o,   //下条指令是否处于延迟槽

    output reg                  jump_flag_o,    //跳转标志
    output reg[`REG_BUS]        jump_address_o,    //跳转地址
    output reg[`REG_BUS]        link_address_o,    //跳转指令写回地址
    output reg                  is_in_delay_slot_o, //此条指令是否处于延迟槽

    //输出到regfile的信息
    output reg                  reg1_read_o,    //reg1读使能
    output reg                  reg2_read_o,    //reg2读使能
    output reg[`REG_ADDR_BUS]   reg1_address_o,    //reg1地址
    output reg[`REG_ADDR_BUS]   reg2_address_o,    //reg2地址

    //输出到执行阶段的信息
    output reg[`ALUOP_BUS]      aluop_o,    //译码得到的aluop
    output reg[`ALUTYPE_BUS]    alutype_o,  //译码得到的alutype
    output reg[`REG_BUS]        src1_o,     //译码得到的源操作数1
    output reg[`REG_BUS]        src2_o,     //译码得到的源操作数2
    output reg[`REG_ADDR_BUS]   wa_o,       //译码得到的写地址
    output reg                  we_o,       //译码得到的写使能

    //暂停请求信号，当运行加载存储指令时，请求流水线暂停
    output reg                 stall_request_from_id,

    output wire[`REG_BUS]       inst_o  //输出指令
    );

    //取得指令的指令码，功能码等
    wire[5:0] opcode = inst_i[31:26];  //指令码
    wire[4:0] op2 = inst_i[20:16];
    wire[4:0] op3 = inst_i[10:6];
    wire[5:0] func = inst_i[5:0];    //功能码

    //保存指令执行需要的立即数
    reg[`REG_BUS]   immediate;

    //指示指令是否有效
    reg instvalid;

    wire[`REG_BUS] pc_plus_8;   //当前pc值加8后的值
    wire[`REG_BUS] pc_plus_4;   //当前pc值加4后的值

    wire[`REG_BUS] immediate_sll2_signed; //立即数左移两位后，再进行符号扩展的值

    assign pc_plus_4 = pc_i + 4;
    assign pc_plus_8 = pc_i + 8;
    
    assign immediate_sll2_signed = {{14{inst_i[15]}},inst_i[15:0],2'b00};

    assign inst_o = inst_i; //得到译码阶段的指令  

    /*******************第一部分：对指令进行译码*****************/
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            aluop_o <= `ALUOP_NOP;
            alutype_o <= `NOP;
            wa_o <= `NOP_REG_ADDR;
            we_o <= `WRITE_DISABLE;
            instvalid <= `INSTRUCTION_VALID;
            reg1_read_o <= `READ_DISABLE;
            reg2_read_o <= `READ_DISABLE;
            reg1_address_o <= `NOP_REG_ADDR;
            reg2_address_o <= `NOP_REG_ADDR;
            immediate <= 32'h00000000;
            link_address_o <= `ZERO_WORD;
            jump_address_o <= `ZERO_WORD;
            jump_flag_o <= `NOT_JUMP;
            next_in_delay_slot_o <= `NOT_IN_DELAY_SLOT;
            stall_request_from_id <= `NO_STOP;
        end
        else begin  //默认值
            aluop_o <= `ALUOP_NOP;
            alutype_o <= `NOP;
            wa_o <= inst_i[15:11];
            we_o <= `WRITE_DISABLE;
            instvalid <= `INSTRUCTION_INVALID;
            reg1_read_o <= `READ_DISABLE;
            reg2_read_o <= `READ_DISABLE;
            reg1_address_o <= inst_i[25:21];   //默认通过regfile读端口1读取的寄存器地址rs
            reg2_address_o <= inst_i[20:16];   //默认通过regfile读端口2读取的寄存器地址rt
            immediate <= `ZERO_WORD;
            link_address_o <= `ZERO_WORD;
            jump_address_o <= `ZERO_WORD;
            jump_flag_o <= `NOT_JUMP;
            next_in_delay_slot_o <= `NOT_IN_DELAY_SLOT;
            stall_request_from_id <= `NO_STOP;

            case(opcode)
                `MYCPU_SPECIAL_INSTRUCTION: begin
                    case(op3)
                        5'b00000: begin
                            case(func)   //依据功能码判断
                               `MYCPU_ADDU_FUNC: begin  //addu指令
                                    aluop_o <= `ALUOP_ADDU;
                                    alutype_o <= `ARITHMETIC;
                                    we_o <= `WRITE_ENABLE;
                                    instvalid <= `INSTRUCTION_VALID;
                                    reg1_read_o <= `READ_ENABLE;
                                    reg2_read_o <= `READ_ENABLE;
                                end
                                `MYCPU_SUBU_FUNC: begin
                                    aluop_o <= `ALUOP_SUBU;
                                    alutype_o <= `ARITHMETIC;
                                    we_o <= `WRITE_ENABLE;
                                    instvalid <= `INSTRUCTION_VALID;
                                    reg1_read_o <= `READ_ENABLE;
                                    reg2_read_o <= `READ_ENABLE;
                                end
                                 `MYCPU_AND_FUNC: begin   //and指令
                                    aluop_o <= `ALUOP_AND;
                                    alutype_o <= `LOGIC;
                                    we_o <= `WRITE_ENABLE;
                                    instvalid <= `INSTRUCTION_VALID;
                                    reg1_read_o <= `READ_ENABLE;
                                    reg2_read_o <= `READ_ENABLE;
                                end
                                `MYCPU_OR_FUNC: begin    //or指令
                                    aluop_o <= `ALUOP_OR;
                                    alutype_o <= `LOGIC;
                                    we_o <= `WRITE_ENABLE;  
                                    instvalid <= `INSTRUCTION_VALID;
                                    reg1_read_o <= `READ_ENABLE;
                                    reg2_read_o <= `READ_ENABLE;
                                end
                                `MYCPU_XOR_FUNC: begin   //xor指令
                                    aluop_o <= `ALUOP_XOR;
                                    alutype_o <= `LOGIC;
                                    we_o <= `WRITE_ENABLE;
                                    instvalid <= `INSTRUCTION_VALID;
                                    reg1_read_o <= `READ_ENABLE;
                                    reg2_read_o <= `READ_ENABLE;
                                end
                                `MYCPU_JR_FUNC: begin    //jr指令
                                    aluop_o <= `ALUOP_JR;
                                    alutype_o <= `BRANCH;
                                    we_o <= `WRITE_DISABLE;
                                    instvalid <= `INSTRUCTION_VALID;
                                    reg1_read_o <= `READ_ENABLE;
                                    reg2_read_o <= `READ_DISABLE;
                                    link_address_o <= `ZERO_WORD;
                                    jump_address_o <= src1_o;
                                    jump_flag_o <= `JUMP;
                                    next_in_delay_slot_o <= `IN_DELAY_SLOT;
                                end
                                `MYCPU_SLT_FUNC: begin   //slt指令
                                    aluop_o <= `ALUOP_SLT;
                                    alutype_o <= `ARITHMETIC;
                                    we_o <= `WRITE_ENABLE;
                                    instvalid <= `INSTRUCTION_VALID;
                                    reg1_read_o <= `READ_ENABLE;
                                    reg2_read_o <= `READ_ENABLE;
                                end
                                `MYCPU_SLLV_FUNC: begin  //sllv指令
                                    aluop_o <= `ALUOP_SLLV;
                                    alutype_o <= `SHIFT;
                                    we_o <= `WRITE_ENABLE;
                                    instvalid <= `INSTRUCTION_VALID;
                                    reg1_read_o <= `READ_ENABLE;
                                    reg2_read_o <= `READ_ENABLE;
                                end
                                default: begin
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end
                `MYCPU_SPECIAL2_INSTRUCTION: begin     //op1为SPECIAL2
                    case(func)
                        `MYCPU_MUL_FUNC: begin   //mul指令
                            aluop_o <= `ALUOP_MUL;
                            alutype_o <= `MUL;
                            we_o <= `WRITE_ENABLE;
                            instvalid <= `INSTRUCTION_VALID;
                            reg1_read_o <= `READ_ENABLE;
                            reg2_read_o <= `READ_ENABLE;
                        end
                        `MYCPU_CLZ_FUNC: begin  //clz指令
                            aluop_o <= `ALUOP_CLZ;
                            alutype_o <= `ARITHMETIC;
                            we_o <= `WRITE_ENABLE;
                            instvalid <= `INSTRUCTION_VALID;
                            reg1_read_o <= `READ_ENABLE;
                            reg2_read_o <= `READ_DISABLE;
                        end
                        `MYCPU_CLO_FUNC: begin  //clo指令
                            aluop_o <= `ALUOP_CLO;
                            alutype_o <= `ARITHMETIC;
                            we_o <= `WRITE_ENABLE;
                            instvalid <= `INSTRUCTION_VALID;
                            reg1_read_o <= `READ_ENABLE;
                            reg2_read_o <= `READ_DISABLE;
                        end
                        default:begin
                        end
                    endcase //MYCPU_SPECIAL2_INSTRUCTION
                end
                `MYCPU_ADDIU_OPCODE: begin     //addiu指令
                    aluop_o <= `ALUOP_ADDIU;
                    alutype_o <= `ARITHMETIC;
                    wa_o <= inst_i[20:16];
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    immediate <= {{16{inst_i[15]}},inst_i[15:0]};
                end
                `MYCPU_ANDI_OPCODE: begin      //andi指令
                    aluop_o <= `ALUOP_ANDI;
                    alutype_o <= `LOGIC;
                    wa_o <= inst_i[20:16];
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    immediate <= {16'h0,inst_i[15:0]};
                end
                `MYCPU_LUI_OPCODE: begin       //lui指令
                    aluop_o <= `ALUOP_LUI;
                    alutype_o <= `LOGIC;
                    wa_o <= inst_i[20:16];
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    immediate <= {inst_i[15:0],16'h0};
                end
                `MYCPU_ORI_OPCODE: begin     //ori指令
                    aluop_o <= `ALUOP_ORI;
                    alutype_o <= `LOGIC;
                    wa_o <= inst_i[20:16];
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    immediate <= {16'h0,inst_i[15:0]};
                end
                `MYCPU_XORI_OPCODE: begin      //xori指令
                    aluop_o <= `ALUOP_XORI;
                    alutype_o <= `LOGIC;
                    wa_o <= inst_i[20:16];
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    immediate <= {16'h0,inst_i[15:0]};
                end
                `MYCPU_BEQ_OPCODE: begin   //beq指令
                    aluop_o <= `ALUOP_BEQ;
                    alutype_o <= `BRANCH;
                    we_o <= `WRITE_DISABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_ENABLE;
                    if(src1_o == src2_o) begin
                        jump_address_o <= pc_plus_4 + immediate_sll2_signed;
                        jump_flag_o <= `JUMP;
                        next_in_delay_slot_o <= `IN_DELAY_SLOT;
                    end
                end
                `MYCPU_BNE_OPCODE: begin   //bne指令
                    aluop_o <= `ALUOP_BNE;
                    alutype_o <= `BRANCH;
                    we_o <= `WRITE_DISABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_ENABLE;
                    if(src1_o != src2_o) begin
                        jump_address_o <= pc_plus_4 + immediate_sll2_signed;
                        jump_flag_o <= `JUMP;
                        next_in_delay_slot_o <= `IN_DELAY_SLOT;
                    end
                end
                `MYCPU_BGTZ_OPCODE: begin  //bgtz指令
                    aluop_o <= `ALUOP_BGTZ;
                    alutype_o <= `BRANCH;
                    we_o <= `WRITE_DISABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    if((src1_o[31] == 1'b0) && (src1_o != `ZERO_WORD)) begin
                        jump_address_o <= pc_plus_4 + immediate_sll2_signed;
                        jump_flag_o <= `JUMP;
                        next_in_delay_slot_o <= `IN_DELAY_SLOT;
                    end
                end
                `MYCPU_BLEZ_OPCODE: begin   //blez指令
                    aluop_o <= `ALUOP_BLEZ;
                    alutype_o <= `BRANCH;
                    we_o <= `WRITE_DISABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    if((src1_o[31] == 1'b1) || (src1_o == `ZERO_WORD)) begin
                        jump_address_o <= pc_plus_4 + immediate_sll2_signed;
                        jump_flag_o <= `JUMP;
                        next_in_delay_slot_o <= `IN_DELAY_SLOT;
                    end
                end
                `MYCPU_J_OPCODE: begin     //j指令
                    aluop_o <= `ALUOP_J;
                    alutype_o <= `BRANCH;
                    we_o <= `WRITE_DISABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_DISABLE;
                    reg2_read_o <= `READ_DISABLE;
                    link_address_o <= `ZERO_WORD;
                    jump_flag_o <= `JUMP;
                    next_in_delay_slot_o <= `IN_DELAY_SLOT;
                    jump_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};
                end
                `MYCPU_JAL_OPCODE: begin   //jal指令
                    aluop_o <= `ALUOP_JAL;
                    alutype_o <= `BRANCH;
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_DISABLE;
                    reg2_read_o <= `READ_DISABLE;
                    wa_o <= 5'b11111;
                    link_address_o <= pc_plus_8;
                    jump_flag_o <= `JUMP;
                    next_in_delay_slot_o <= `IN_DELAY_SLOT;
                    jump_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};
                end
                `MYCPU_LB_OPCODE: begin    //lb指令
                    aluop_o <= `ALUOP_LB;
                    alutype_o <= `LOAD_STORE;
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    wa_o <= inst_i[20:16];
                    stall_request_from_id <= `STOP;
                end
                `MYCPU_LW_OPCODE: begin    //lw指令
                    aluop_o <= `ALUOP_LW;
                    alutype_o <= `LOAD_STORE;
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_DISABLE;
                    wa_o <= inst_i[20:16];
                    stall_request_from_id <= `STOP;
                end
                `MYCPU_SB_OPCODE: begin    //sb指令
                    aluop_o <= `ALUOP_SB;
                    alutype_o <= `LOAD_STORE;
                    we_o <= `WRITE_DISABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_ENABLE;
                    stall_request_from_id <= `STOP;
                end
                `MYCPU_SW_OPCODE: begin    //sw指令
                    aluop_o <= `ALUOP_SW;
                    alutype_o <= `LOAD_STORE;
                    we_o <= `WRITE_DISABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_ENABLE;
                    reg2_read_o <= `READ_ENABLE;
                    stall_request_from_id <= `STOP;
                end
                `MYCPU_SPECIAL3_INSTRUCTION: begin
                    case(op2)
                        `MYCPU_BLTZ: begin  //bltz指令
                            aluop_o <= `ALUOP_BLTZ;
                            alutype_o <= `BRANCH;
                            we_o <= `WRITE_DISABLE;
                            instvalid <= `INSTRUCTION_VALID;
                            reg1_read_o <= `READ_ENABLE;
                            reg2_read_o <= `READ_DISABLE;
                            if(src1_o[31] == 1'b1) begin
                                jump_address_o <= pc_plus_4 + immediate_sll2_signed;
                                jump_flag_o <= `JUMP;
                                next_in_delay_slot_o <= `IN_DELAY_SLOT;
                            end
                        end
                        `MYCPU_BGEZ: begin  //bgez指令
                            aluop_o <= `ALUOP_BGEZ;
                            alutype_o <= `BRANCH;
                            we_o <= `WRITE_DISABLE;
                            instvalid <= `INSTRUCTION_VALID;
                            reg1_read_o <= `READ_ENABLE;
                            reg2_read_o <= `READ_DISABLE;
                            if(src1_o[31] == 1'b0) begin
                                jump_address_o <= pc_plus_4 + immediate_sll2_signed;
                                jump_flag_o <= `JUMP;
                                next_in_delay_slot_o <= `IN_DELAY_SLOT;
                            end
                        end
                    endcase
                end
                default:begin
                end
            endcase     //case opcode

            if(inst_i[31:21] == 11'b00000000000) begin
                if(func == `MYCPU_SLL_FUNC) begin     //sll指令
                    aluop_o <= `ALUOP_SLL;
                    alutype_o <= `SHIFT;
                    wa_o <= inst_i[15:11];
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_DISABLE;
                    reg2_read_o <= `READ_ENABLE;
                    immediate[4:0] <= inst_i[10:6];
                end
                else if(func == `MYCPU_SRL_FUNC) begin    //srl指令
                    aluop_o <= `ALUOP_SRL;
                    alutype_o <= `SHIFT;
                    wa_o <= inst_i[15:11];
                    we_o <= `WRITE_ENABLE;
                    instvalid <= `INSTRUCTION_VALID;
                    reg1_read_o <= `READ_DISABLE;
                    reg2_read_o <= `READ_ENABLE;
                    immediate[4:0] <= inst_i[10:6];
                end
            end
        end
    end

    //输出变量is_in_delay_slot_o表示当前译码阶段指令是否是延迟槽指令
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            is_in_delay_slot_o <= `NOT_IN_DELAY_SLOT;
        end
        else begin  //延迟槽判断输出就等于延迟槽判断输入
            is_in_delay_slot_o <= is_in_delay_slot_i;
        end
    end

    /*******************第二部分：确定源操作数1*****************/
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            src1_o <= `ZERO_WORD;
        end
        else if((reg1_read_o == `READ_ENABLE) && (ex_we_i == `WRITE_ENABLE)
                    && (ex_wa_i == reg1_address_o)) begin
            src1_o <= ex_wd_i;      //执行-译码相关                
        end
        else if((reg1_read_o == `READ_ENABLE) && (mem_we_i == `WRITE_ENABLE)
                    && (mem_wa_i == reg1_address_o)) begin
            src1_o <= mem_wd_i;     //访存-译码相关               
        end
        else if(reg1_read_o == `READ_ENABLE) begin
            src1_o <= reg1_data_i;      //regfile读端口1的输出值
        end
        else if(reg1_read_o == `READ_DISABLE) begin
            src1_o <= immediate;      //立即数
        end
        else begin
            src1_o <= `ZERO_WORD;
        end
    end

    /*******************第三部分：确定源操作数2*****************/
    always @(*) begin
        if(rst == `RST_SIGNAL_ENABLE) begin
            src2_o <= `ZERO_WORD;
        end
        else if((reg2_read_o == `READ_ENABLE) && (ex_we_i == `WRITE_ENABLE)
                    && (ex_wa_i == reg2_address_o)) begin
            src2_o <= ex_wd_i;      //执行-译码相关                
        end
        else if((reg2_read_o == `READ_ENABLE) && (mem_we_i == `WRITE_ENABLE)
                    && (mem_wa_i == reg2_address_o)) begin
            src2_o <= mem_wd_i;     //访存-译码相关                
        end
        else if(reg2_read_o == `READ_ENABLE) begin
            src2_o <= reg2_data_i;      //regfile读端口2的输出值
        end
        else if(reg2_read_o == `READ_DISABLE) begin
            src2_o <= immediate;      //立即数
        end
        else begin
            src2_o <= `ZERO_WORD;
        end
    end
endmodule
