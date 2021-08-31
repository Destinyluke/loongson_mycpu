`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：control.v
//  简要说明：此文件是mycpu的暂停控制器，用于接收译码阶段的暂停请求，在执行加载存储指令的时候，将if_stage和if_id暂停4个时钟周期
//           暂停4个时钟周期的原因是，需要让加载存储指令完全执行完后，才能继续取指令，否则base_ram会出错

//******************************************************************************************************************
`include "defines.v"

module control(
    input wire          clk,
    input wire          rst,
    input wire          stall_request_from_id,   //来自译码阶段的暂停请求
    output reg[1:0]     stall
    );
    reg[2:0] cycle; //暂停需要持续4个时钟周期，直到加载存储指令完成，此变量用于状态机计时
    //定义状态变量
    parameter s0 = 3'b000,  //采用格雷码编码，防止毛刺
              s1 = 3'b001,
              s2 = 3'b011,
              s3 = 3'b010,
              s4 = 3'b110;
    always @(negedge clk) begin     //在下降沿进行判断
        if(rst == `RST_SIGNAL_ENABLE) begin
            stall <= 2'b00;
            cycle <= s0;
        end
        else if(stall_request_from_id == `STOP) begin    //此时开始暂停
            stall <= 2'b11;
            cycle <= s1;
        end
        else begin  //状态机，等待四个时钟周期
            case(cycle)
                s1: begin
                    cycle <= s2;    //第二个时钟周期
                    stall <= 2'b11;
                end
                s2: begin
                    cycle <= s3;    //第三个时钟周期
                    stall <= 2'b11;
                end
                s3: begin
                    cycle <= s4;    //第四个时钟周期
                    stall <= 2'b11;
                end
                s4: begin           //流水线恢复
                    cycle <= s0;
                    stall <= 2'b00;
                end
                default: begin
                    cycle <= s0;
                    stall <= 2'b00;
                end
            endcase
        end
    end
endmodule
