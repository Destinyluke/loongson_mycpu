`timescale 1ns / 1ps
//******************************************************************************************************************

//  文件名：uart.v
//  简要说明：此文件是uart控制器，用于控制串口的接收和发送

//******************************************************************************************************************
`include "defines.v"

module uart(
    input wire          clk, 
    input wire          rst,

    //来自访存阶段mem_stage的部分输入
    input wire[`REG_BUS]    mem_address_i,     //地址输入
    input wire              mem_we_i,       //写使能
    input wire[`REG_BUS]    mem_data_i,     //数据输入

    //串口信号
    input wire          rxd,    //串口接收
    output wire         txd,    //串口发送

    //传输到访存阶段mem_stage的输出
    output reg[`REG_BUS]    uart_data_o      //数据输出    
    );

    //一些与接收有关的信号
    wire[`BYTE_BUS] ext_uart_rx;  //串行接收到的数据转换为并行数据
    wire ext_uart_ready;            //接收完成，标志位置1
    reg ext_uart_clear;            //标志位清0

    //一些与发送有关的信号
    reg[`BYTE_BUS] ext_uart_tx;   //需要发送的并行数据
    wire ext_uart_busy;             //发送器是否忙碌
    reg ext_uart_start;             //是否开始发送

    // //一些与接收FIFO有关的信号
    // wire[`BYTE_BUS] rxd_fifo_din;
    // wire rxd_fifo_wr_en;
    // wire rxd_fifo_rd_en;
    // wire[`BYTE_BUS] rxd_fifo_dout;
    // wire rxd_fifo_full;
    // wire rxd_fifo_empty;

    // //一些与发送FIFO有关的信号
    // wire[`BYTE_BUS] txd_fifo_din;
    // wire txd_fifo_wr_en;
    // wire txd_fifo_rd_en;
    // wire[`BYTE_BUS] txd_fifo_dout;
    // wire txd_fifo_full;
    // wire txd_fifo_empty;

    //例化接收机
    async_receiver #(.ClkFrequency(54600000),.Baud(9600))   //接收模块，波特率9600，频率54.6MHz，无校验位
        ext_uart_r(
            .clk(clk),      //外部时钟信号
            .RxD(rxd),      //外部串行信号输入
            .RxD_data_ready(ext_uart_ready),    //数据接收到标志
            .RxD_clear(ext_uart_clear),         //清除接收标志
            .RxD_data(ext_uart_rx)              //接收到的一字节数据
        );
    
    //例化发送机
    async_transmitter #(.ClkFrequency(54600000),.Baud(9600))    //发送模块，波特率9600，频率54.6MHz，无校验位
        ext_uart_t(
            .clk(clk),      //外部时钟信号
            .TxD(txd),      //串行信号输出
            .TxD_busy(ext_uart_busy),   //发送器忙状态指示
            .TxD_start(ext_uart_start), //开始发送信号
            .TxD_data(ext_uart_tx)      //待发送的数据
        );

    // //例化接收FIFO
    // fifo_generator_0 rxd_fifo(
    //     .clk(clk),
    //     .rst(rst),
    //     .din(rxd_fifo_din),
    //     .wr_en(rxd_fifo_wr_en),
    //     .rd_en(rxd_fifo_rd_en),
    //     .dout(rxd_fifo_dout),
    //     .full(rxd_fifo_full),
    //     .empty(rxd_fifo_empty)
    // );

    // //例化发送FIFO
    // fifo_generator_0 txd_fifo(
    //     .clk(clk),
    //     .rst(rst),
    //     .din(txd_fifo_din),
    //     .wr_en(txd_fifo_wr_en),
    //     .rd_en(txd_fifo_rd_en),
    //     .dout(txd_fifo_dout),
    //     .full(txd_fifo_full),
    //     .empty(txd_fifo_empty)
    // );
    
    // assign rxd_fifo_din = ext_uart_rx;   //将串行数据转换为8位并行数据后，输入rxd_fifo
    // assign rxd_fifo_wr_en = ext_uart_clear;  //当对接收机进行清0时，允许写rxd_fifo
    // assign rxd_fifo_rd_en = (mem_address_i == `SERIAL_DATA_ADDR) && (mem_we_i == `WRITE_DISABLE);   //当要访问数据，并且是读操作时，允许读rxd_fifo

    // assign txd_fifo_din = ext_uart_tx;   //将要串行发送的并行8位数据，输入txd_fifo
    // assign txd_fifo_wr_en = (mem_address_i == `SERIAL_DATA_ADDR) && (mem_we_i == `WRITE_ENABLE);    //当要访问数据，并且是写操作时，允许写txd_fifo
    // assign txd_fifo_rd_en = ext_uart_start;      //开始发送时，允许串口读txd_fifo

    always @(*) begin
        if(rst ==`RST_SIGNAL_ENABLE) begin
           ext_uart_start <= `SERIAL_NOT_SEND;
           ext_uart_tx <= `ZERO_BYTE;
           uart_data_o <= `ZERO_WORD;
        end
        else if(mem_address_i == `SERIAL_STATE_ADDR) begin
            ext_uart_start <= `SERIAL_NOT_SEND; //此时读状态，不发送
            ext_uart_tx <= `ZERO_BYTE;  
            //[0]为1时表示串口空闲可发送数据，[1]为1时表示串口收到数据
            // uart_data_o <= {{30{1'b0}},!rxd_fifo_empty,!txd_fifo_full};  //采用了fifo
            uart_data_o <= {{30{1'b0}},ext_uart_ready,!ext_uart_busy};  //没有采用fifo
        end
        else if(mem_address_i == `SERIAL_DATA_ADDR) begin
            if(mem_we_i == `WRITE_DISABLE) begin    //此时读数据
                ext_uart_start <= `SERIAL_NOT_SEND;
                ext_uart_tx <= `ZERO_BYTE;
                // uart_data_o <= {24'h000000,rxd_fifo_dout};  //采用了fifo
                uart_data_o <= {24'h000000,ext_uart_rx};       //没有采用fifo，串口读到的8位数据放在低8位
            end
            // else if(!ext_uart_busy && !txd_fifo_empty) begin
            else begin  //此时写数据
                ext_uart_start <= `SERIAL_SEND; //开始发送
                ext_uart_tx <= mem_data_i[7:0]; //写输入数据的低8位
                uart_data_o <= `ZERO_WORD;
            end
        end
        else begin  //其它情况
            ext_uart_start <= `SERIAL_NOT_SEND;
            ext_uart_tx <= `ZERO_BYTE;
            uart_data_o <= `ZERO_WORD;
        end
    end

    //处理clear部分（此处不能像模板代码一样直接用一句assign）
    wire already_read;  //判断数据是否成功被读走了
    //当成功接收，并且是读数据状态时，数据成功被读走(此时没有采用fifo)
    assign already_read = ext_uart_ready && mem_address_i == `SERIAL_DATA_ADDR
                        && mem_we_i == `WRITE_DISABLE;
    
    //当成功接收，并且rxd_fifo未满时，便可清除标志位，继续读数(此时采用了fifo)
    // assign already_read = ext_uart_ready && !rxd_fifo_full;
    
    //判断下一个时钟沿是否要清除标志位
    reg ext_uart_clear_next_clk;

    always @(negedge clk) begin     //在下降沿判断
        if(rst == `RST_SIGNAL_ENABLE) begin
            ext_uart_clear_next_clk <= `NOT_CLEAR_STATE;    //不清除标志位
        end
        else begin
            if(already_read && ext_uart_clear_next_clk == `NOT_CLEAR_STATE) begin   //数据已经读走了，并且ext_uart_clear_next_clk为不清除，需要清除
                ext_uart_clear_next_clk <= `CLEAR_STATE;
            end
            else if(ext_uart_clear == `CLEAR_STATE) begin   //标志位已经清零了，所以下个时钟沿不用再清除
                ext_uart_clear_next_clk <= `NOT_CLEAR_STATE;
            end
        end
    end

    always @(posedge clk) begin     //在上升沿改变clear的值
        if(rst == `RST_SIGNAL_ENABLE) begin
            ext_uart_clear <= `NOT_CLEAR_STATE;
        end
        else begin
            ext_uart_clear <= ext_uart_clear_next_clk;
        end
    end
endmodule
