`timescale 1ns / 1ps
//********************************************************************

//  文件名：defines.v
//  简要说明：此文件是整个设计的宏定义模块

//********************************************************************

/**************************全局的宏定义**********************/
`define RST_SIGNAL_ENABLE      1'b1            //复位信号有效
`define RST_SIGNAL_DISABLE     1'b0            //复位信号无效
`define ZERO_WORD       32'h00000000           //32位的数值0

`define WRITE_ENABLE    1'b0            //写使能
`define WRITE_DISABLE   1'b1            //写禁止
`define READ_ENABLE     1'b0            //读使能
`define READ_DISABLE    1'b1            //读禁止

`define ALUOP_BUS       7:0             //aluop的宽度
`define ALUTYPE_BUS     2:0             //alutype的宽度
`define INSTRUCTION_VALID      1'b1     //指令有效
`define INSTRUCTION_INVALID    1'b0     //指令无效
`define STOP            1'b1            //流水线暂停
`define NO_STOP         1'b0            //流水线不暂停
`define IN_DELAY_SLOT   1'b1            //指令处于延迟槽
`define NOT_IN_DELAY_SLOT 1'b0          //指令不处于延迟槽
`define JUMP            1'b1            //要跳转
`define NOT_JUMP        1'b0            //不跳转
`define CHIP_ENABLE     1'b0            //芯片使能
`define CHIP_DISABLE    1'b1            //芯片禁止
`define INSTRUCTION_ADDR_BUS   31:0     //地址总线宽度
`define INSTRUCTION_BUS        31:0     //数据总线宽度
`define BYTE_BUS      7:0             //一个字节的宽度为8位
`define HALF_WORD_BUS 15:0            //一个半字的宽度为16位

/**************************与串口有关的宏定义**********************/
`define SERIAL_STATE_ADDR   32'hBFD003FC    //串口标志位，[0]为1时表示串口空闲可发送数据，[1]为1时表示串口收到数据
`define SERIAL_DATA_ADDR    32'hBFD003F8    //[7:0]，读写地址分别表示串口接收、发送一个字节
`define SERIAL_SEND         1'b1            //开始发送
`define SERIAL_NOT_SEND     1'b0            //不开始发送
`define ZERO_BYTE           8'b00000000     //8位的数值0
`define CLEAR_STATE         1'b1            //清除标志位
`define NOT_CLEAR_STATE     1'b0            //不清除标志位

/**************************与SRAM有关的宏定义**********************/
`define USE_BASE_RAM        1'b1            //使用base_ram
`define NOT_USE_BASE_RAM    1'b0            //不使用base_ram
`define USE_EXT_RAM         1'b1            //使用ext_ram
`define NOT_USE_EXT_RAM     1'b0            //不使用ext_ram
`define HIGH_RESISTANCE     32'hzzzzzzzz    //32位高阻态

/**************************与booth乘法器有关的宏定义**********************/
`define CODE_BUS            2:0             //booth编码的宽度
`define COEFFICIENT_BUS     1:0             //系数宽度
`define NEGATIVE            1'b1            //部分和为负数
`define POSITIVE            1'b0            //部分和为正数
`define ZERO                2'b00           //输出系数为0
`define ONE                 2'b01           //输出系数为1
`define TWO                 2'b10           //输出系数为2

/************************与具体指令有关的宏定义********************/
`define MYCPU_AND_FUNC       6'b100100       //指令and的功能码
`define MYCPU_OR_FUNC        6'b100101       //指令or的功能码
`define MYCPU_XOR_FUNC       6'b100110       //指令xor的功能码

`define MYCPU_ANDI_OPCODE      6'b001100       //指令andi的指令码
`define MYCPU_ORI_OPCODE       6'b001101       //指令ori的指令码
`define MYCPU_XORI_OPCODE      6'b001110       //指令xori的指令码
`define MYCPU_LUI_OPCODE       6'b001111       //指令lui的指令码

`define MYCPU_SLL_FUNC       6'b000000       //指令sll的功能码
`define MYCPU_SRL_FUNC       6'b000010       //指令srl的功能码
`define MYCPU_SLLV_FUNC      6'b000100       //指令sllv的功能码
`define MYCPU_SRLV_FUNC      6'b000110       //指令srlv的功能码
`define MYCPU_SRA_FUNC       6'b000011       //指令sra的功能码
`define MYCPU_SRAV_FUNC      6'b000111       //指令srav的功能码

`define MYCPU_SLT_FUNC       6'b101010       //指令slt的功能码
// `define MYCPU_SLTU_FUNC      6'b101011       //指令sltu的功能码
`define MYCPU_ADDU_FUNC      6'b100001       //指令addu的功能码
`define MYCPU_SUBU_FUNC      6'b100011       //指令subu的功能码

`define MYCPU_ADDIU_OPCODE   6'b001001       //指令addiu的指令码

`define MYCPU_CLZ_FUNC       6'b100000       //指令clz的功能码
`define MYCPU_CLO_FUNC       6'b100001       //指令clo的功能码
`define MYCPU_MUL_FUNC       6'b000010       //指令mul的功能码     

`define MYCPU_J_OPCODE         6'b000010       //指令j的指令码
`define MYCPU_JAL_OPCODE       6'b000011       //指令jal的指令码

`define MYCPU_JR_FUNC          6'b001000       //指令jr的功能码

`define MYCPU_BEQ_OPCODE       6'b000100       //指令beq的指令码
`define MYCPU_BNE_OPCODE       6'b000101       //指令bne的指令码
`define MYCPU_BGTZ_OPCODE      6'b000111       //指令bgtz的指令码
`define MYCPU_BGEZ             5'b00001
`define MYCPU_BLTZ             5'b00000
`define MYCPU_BLEZ_OPCODE      6'b000110       //指令blez的指令码

`define MYCPU_LB_OPCODE        6'b100000       //指令lb的指令码
`define MYCPU_LW_OPCODE        6'b100011       //指令lw的指令码
`define MYCPU_SB_OPCODE        6'b101000       //指令sb的指令码
`define MYCPU_SW_OPCODE        6'b101011       //指令sw的指令码

`define MYCPU_NOP       6'b000000

`define MYCPU_SPECIAL_INSTRUCTION  6'b000000    //special类
`define MYCPU_SPECIAL2_INSTRUCTION 6'b011100    //special2类
`define MYCPU_SPECIAL3_INSTRUCTION   6'b000001  //special3类



//aluop
`define ALUOP_AND      8'b00100100  //指令and的alu码
`define ALUOP_OR       8'b00100101  //指令or的alu码
`define ALUOP_XOR      8'b00100110  //指令xor的alu码
`define ALUOP_ANDI     8'b01011001  //指令andi的alu码
`define ALUOP_ORI      8'b01011010  //指令ori的alu码
`define ALUOP_XORI     8'b01011011  //指令xor的alu码
`define ALUOP_LUI      8'b01011100  //指令lui的alu码

`define ALUOP_SLL      8'b01111100  //指令sll的alu码
`define ALUOP_SRL      8'b00000010  //指令srl的alu码
`define ALUOP_SLLV     8'b00000100  //指令sllv的alu码
`define ALUOP_SRLV     8'b00000110  //指令srlv的alu码
`define ALUOP_SRA      8'b00000011  //指令sra的alu码
`define ALUOP_SRAV     8'b00000111  //指令srav的alu码

`define ALUOP_SLT      8'b00101010  //指令slt的alu码
// `define ALUOP_SLTU     8'b00101011  //指令sltu的alu码
`define ALUOP_ADDU     8'b00100001  //指令addu的alu码
`define ALUOP_ADDIU    8'b01010110  //指令addiu的alu码
`define ALUOP_SUBU     8'b00100011  //指令subu的alu码
`define ALUOP_MUL      8'b10101001  //指令mul的alu码
`define ALUOP_CLZ      8'b10110000  //指令clz的alu码
`define ALUOP_CLO      8'b10110001  //指令clo的alu码

`define ALUOP_J        8'b01001111  //指令j的alu码
`define ALUOP_JAL      8'b01010000  //指令jal的alu码
`define ALUOP_JR       8'b00001000  //指令jr的alu码
`define ALUOP_BEQ      8'b01010001  //指令beq的alu码
`define ALUOP_BNE      8'b01010010  //指令bne的alu码
`define ALUOP_BGTZ     8'b01010100  //指令bgtz的alu码
`define ALUOP_BGEZ     8'b01000001  //指令bgez的alu码
`define ALUOP_BLTZ     8'b01000000  //指令bltz的alu码
`define ALUOP_BLEZ     8'b01010011  //指令blez的alu码

`define ALUOP_LB       8'b11100000  //指令lb的alu码
`define ALUOP_LW       8'b11100011  //指令lw的alu码
`define ALUOP_SB       8'b11101000  //指令sb的alu码
`define ALUOP_SW       8'b11101011  //指令sw的alu码

`define ALUOP_NOP      8'b00000000  //指令nop的alu码

//alutype
`define NOP             3'b000
`define LOGIC           3'b001
`define SHIFT           3'b010
`define ARITHMETIC      3'b011
`define MUL             3'b100
`define BRANCH          3'b101
`define LOAD_STORE      3'b110

/***********************与通用寄存器堆有关的宏定义*********************/
`define REG_ADDR_BUS    4:0             //regfile模块的地址线宽度
`define REG_BUS         31:0            //regfile模块的数据线宽度
`define REG_WIDTH       32              //通用寄存器的宽度
`define DOUBLE_REG_WIDTH    64          //两倍通用寄存器的宽度
`define DOUBLE_REG_BUS  63:0            //两倍的通用寄存器的数据线宽度
`define REG_NUM         32              //通用寄存器的数量
`define REG_ADDR_NUM    5               //寻址通用寄存器使用的地址位数
`define NOP_REG_ADDR    5'b00000        //空地址

