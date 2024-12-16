`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: serial.v
//-- DESCRIPTION  : 本模块为 串口的处理模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module serial(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    rxd,  //直连串口接收端
    output  wire    txd,  //直连串口发送端
        
    input   wire    [3:0]   Serial_state,
    input   wire    [31:0]  ram_data_i,
    
    output  reg     [31:0]  serial_o
    );
  

  
/*****************************************************************************
                                串口通信模块
*****************************************************************************/

 wire RxD_data_ready;   // UART 数据接收完标志， 可作为 UART 清除接收标志 条件判断之一
                        // RxD_FIFO 写入使能： UART 数据接收完 即可 立即写入RxD_FIFO
 wire RxD_clear;
 wire [7:0] RxD_data;   // UART 接受的 8 bit数据
                        // RxD_FIFO 写入数据
                        
 wire RxD_FIFO_full;    // RxD_FIFO 已满或将满， 不能向 RxD_FIFO 写入数据
 
 wire RxD_FIFO_ren;      // RxD_FIFO 读取使能
 wire [7:0] RxD_FIFO_dout;  // RxD_FIFO 读取数据
 wire RxD_FIFO_empty;   // RxD_FIFO 已空， 不能向 RxD_FIFO 读取数据
 
 //清除串口接收标志： UART数据接收完标志 且 RxD_FIFO队列空间未满 ==> 接收完毕后，停止接收数据
    //当 rxd 一位一位接收， 接收完 8 Bit数据后存储到 RxD_data 中，RxD_data_ready会自动为1，说明接收完毕
 assign RxD_clear = rst ? 1'b1 : RxD_data_ready  ? (RxD_FIFO_full ? 1'b0 : 1'b1) : 1'b0;
 
 async_receiver #(.ClkFrequency(63870000),.Baud(9600)) //接收模块，9600无检验位
                ext_uart_r(
                    .clk(clk),                  //i：外部时钟信号
                    .RxD(rxd),                      //i：外部串行信号输入
                    .RxD_clear(RxD_clear),          //i：清除接收标志
                    .RxD_data_ready(RxD_data_ready),//o：数据接收完标志
                    .RxD_data(RxD_data)             //o：接收到的一字节数据
                );
 
 fifo_generator_0 RxD_FIFO (
                             .clk(clk),      
                             .rst(rst),      
                             // write
                             .wr_en(RxD_data_ready), // i：FIFO 写入使能：UART 数据接收完， 即可 写入 FIFO
                             .din(RxD_data),         // i：FIFO 写入数据
                             .full(RxD_FIFO_full),      // o：FIFO 已满或将满 标志， 此时不能写入数据
                             // read    
                             .rd_en(RxD_FIFO_ren),  // i：FIFO 读取使能
                             .dout(RxD_FIFO_dout),      // o：FIFO 读取数据
                             .empty(RxD_FIFO_empty)     // o：FIFO 已空 标志， 此时不能读取数据
                           );
 
 wire [7:0] TxD_data;   // UART 发送的 8 bit数据
                        // TxD_FIFO 读取数据
                        
 wire TxD_busy;     // UART 发送器繁忙状态指示，可作为 UART 开始数据发送信号 条件判断之一
 wire TxD_start;    
 
 wire TxD_FIFO_wen;  // TxD_FIFO 写入使能： UART 数据发送完 即可 立即写入TxD_FIFO
 wire [7:0] TxD_FIFO_din;    // TxD_FIFO 写入数据
 wire TxD_FIFO_full;    // TxD_FIFO 已满或将满， 不能向 TxD_FIFO 写入数据
 wire TxD_FIFO_empty;   // TxD_FIFO 已空， 不能向 TxD_FIFO 读取数据
 
 //开始发送信号标志： UART发送器状态指示空闲  且 TxD_FIFO队列空间未空 ==> 发送完毕后，停止发送数据
    //当 TxD_data 里的 8 Bit数据后一位一位 发送到 txd中，TxD_busy会自动为0，说明发送完毕
 // TxD_FIFO 读取使能： UART 开始数据发送， 即可 立即读取TxD_FIFO
 assign TxD_start = TxD_busy ? 1'b0 : (TxD_FIFO_empty ? 1'b0 : 1'b1);
 
 async_transmitter #(.ClkFrequency(63870000),.Baud(9600)) //发送模块，9600无检验位
                   ext_uart_t(
                       .clk(clk),            //i：外部时钟信号
                       .TxD_data(TxD_data),      //i：待发送的数据
                       .TxD_start(TxD_start),    //i：开始发送信号标志
                       .TxD_busy(TxD_busy),      //o：发送器繁忙状态指示
                       .TxD(txd)                 //o：串行信号输出
                   );
 
 fifo_generator_0 TxD_FIFO (
                             .clk(clk),      
                             .rst(rst),      
                             // write
                             .wr_en(TxD_FIFO_wen),  // i：FIFO 写入使能：UART 数据发送完， 即可 写入 FIFO
                             .din(TxD_FIFO_din),    // i：FIFO 写入数据   
                             .full(TxD_FIFO_full),      // o：FIFO 已满或将满 标志， 此时不能写入数据
                             // read    
                             .rd_en(TxD_start),     // i：FIFO 读取使能
                             .dout(TxD_data),           // o：FIFO 读取数据
                             .empty(TxD_FIFO_empty)     // o：FIFO 已空 标志， 此时不能读取数据  
                           );
   
  wire    [1:0]   state;
  //   state
  //    00：RxD_FIFO 已空,  TxD_FIFO 已满或将满 
  //    01：RxD_FIFO 已空,  TxD_FIFO 未满      
  //    10：RxD_FIFO 未空,  TxD_FIFO 已满或将满
  //    11：RxD_FIFO 未空,  TxD_FIFO 未满      
  
  // state[1]：只读，为1时表示串口收到数据
  // state[0]：只读，为1时表示串口空闲，可发送数据
  
  assign state[1] = RxD_FIFO_empty ? 1'b0 : 1'b1;
  assign state[0] = TxD_FIFO_full  ? 1'b0 : 1'b1; 

  
   /// 处理串口
 // Serial_state
 // [0] : rst                       复位 或 不读不写状态 
 // [1] : is_SerialDate && ram_we_n     读数据(接收数据)
 // [2] : is_SerialDate && !ram_we_n    写数据(发送数据)
 // [3] : is_SerialStat                 (显示此时串口状态)
 
 assign RxD_FIFO_ren = Serial_state[1] ? 1'b1 : 1'b0;
 
 assign TxD_FIFO_wen = Serial_state[2] ? 1'b1 : 1'b0;
 
 assign TxD_FIFO_din = Serial_state[2] ? ram_data_i[7:0] : 8'h00;

        
        // 处理 串口 rxd 接收的数据，便于传给 CPU 执行load指令写入寄存器
 always @ (*)
   begin
     if(Serial_state[0])
       serial_o = 32'h0000_0000;
     else if(Serial_state[3])           /// 获取串口状态
       serial_o = {30'h0, state};
     else if(Serial_state[1])
             /// 获取（或发送）串口数据情况下， 读数据，即接收串口数据 源自  rxd
       serial_o = {24'b0, RxD_FIFO_dout};
     else
       serial_o = 32'h0000_0000;
   end


  
endmodule
