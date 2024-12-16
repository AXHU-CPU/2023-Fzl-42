`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: serial.v
//-- DESCRIPTION  : ��ģ��Ϊ ���ڵĴ���ģ��
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10		  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////


module serial(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    rxd,  //ֱ�����ڽ��ն�
    output  wire    txd,  //ֱ�����ڷ��Ͷ�
        
    input   wire    [3:0]   Serial_state,
    input   wire    [31:0]  ram_data_i,
    
    output  reg     [31:0]  serial_o
    );
  

  
/*****************************************************************************
                                ����ͨ��ģ��
*****************************************************************************/

 wire RxD_data_ready;   // UART ���ݽ������־�� ����Ϊ UART ������ձ�־ �����ж�֮һ
                        // RxD_FIFO д��ʹ�ܣ� UART ���ݽ����� ���� ����д��RxD_FIFO
 wire RxD_clear;
 wire [7:0] RxD_data;   // UART ���ܵ� 8 bit����
                        // RxD_FIFO д������
                        
 wire RxD_FIFO_full;    // RxD_FIFO ���������� ������ RxD_FIFO д������
 
 wire RxD_FIFO_ren;      // RxD_FIFO ��ȡʹ��
 wire [7:0] RxD_FIFO_dout;  // RxD_FIFO ��ȡ����
 wire RxD_FIFO_empty;   // RxD_FIFO �ѿգ� ������ RxD_FIFO ��ȡ����
 
 //������ڽ��ձ�־�� UART���ݽ������־ �� RxD_FIFO���пռ�δ�� ==> ������Ϻ�ֹͣ��������
    //�� rxd һλһλ���գ� ������ 8 Bit���ݺ�洢�� RxD_data �У�RxD_data_ready���Զ�Ϊ1��˵���������
 assign RxD_clear = rst ? 1'b1 : RxD_data_ready  ? (RxD_FIFO_full ? 1'b0 : 1'b1) : 1'b0;
 
 async_receiver #(.ClkFrequency(63870000),.Baud(9600)) //����ģ�飬9600�޼���λ
                ext_uart_r(
                    .clk(clk),                  //i���ⲿʱ���ź�
                    .RxD(rxd),                      //i���ⲿ�����ź�����
                    .RxD_clear(RxD_clear),          //i��������ձ�־
                    .RxD_data_ready(RxD_data_ready),//o�����ݽ������־
                    .RxD_data(RxD_data)             //o�����յ���һ�ֽ�����
                );
 
 fifo_generator_0 RxD_FIFO (
                             .clk(clk),      
                             .rst(rst),      
                             // write
                             .wr_en(RxD_data_ready), // i��FIFO д��ʹ�ܣ�UART ���ݽ����꣬ ���� д�� FIFO
                             .din(RxD_data),         // i��FIFO д������
                             .full(RxD_FIFO_full),      // o��FIFO �������� ��־�� ��ʱ����д������
                             // read    
                             .rd_en(RxD_FIFO_ren),  // i��FIFO ��ȡʹ��
                             .dout(RxD_FIFO_dout),      // o��FIFO ��ȡ����
                             .empty(RxD_FIFO_empty)     // o��FIFO �ѿ� ��־�� ��ʱ���ܶ�ȡ����
                           );
 
 wire [7:0] TxD_data;   // UART ���͵� 8 bit����
                        // TxD_FIFO ��ȡ����
                        
 wire TxD_busy;     // UART ��������æ״ָ̬ʾ������Ϊ UART ��ʼ���ݷ����ź� �����ж�֮һ
 wire TxD_start;    
 
 wire TxD_FIFO_wen;  // TxD_FIFO д��ʹ�ܣ� UART ���ݷ����� ���� ����д��TxD_FIFO
 wire [7:0] TxD_FIFO_din;    // TxD_FIFO д������
 wire TxD_FIFO_full;    // TxD_FIFO ���������� ������ TxD_FIFO д������
 wire TxD_FIFO_empty;   // TxD_FIFO �ѿգ� ������ TxD_FIFO ��ȡ����
 
 //��ʼ�����źű�־�� UART������״ָ̬ʾ����  �� TxD_FIFO���пռ�δ�� ==> ������Ϻ�ֹͣ��������
    //�� TxD_data ��� 8 Bit���ݺ�һλһλ ���͵� txd�У�TxD_busy���Զ�Ϊ0��˵���������
 // TxD_FIFO ��ȡʹ�ܣ� UART ��ʼ���ݷ��ͣ� ���� ������ȡTxD_FIFO
 assign TxD_start = TxD_busy ? 1'b0 : (TxD_FIFO_empty ? 1'b0 : 1'b1);
 
 async_transmitter #(.ClkFrequency(63870000),.Baud(9600)) //����ģ�飬9600�޼���λ
                   ext_uart_t(
                       .clk(clk),            //i���ⲿʱ���ź�
                       .TxD_data(TxD_data),      //i�������͵�����
                       .TxD_start(TxD_start),    //i����ʼ�����źű�־
                       .TxD_busy(TxD_busy),      //o����������æ״ָ̬ʾ
                       .TxD(txd)                 //o�������ź����
                   );
 
 fifo_generator_0 TxD_FIFO (
                             .clk(clk),      
                             .rst(rst),      
                             // write
                             .wr_en(TxD_FIFO_wen),  // i��FIFO д��ʹ�ܣ�UART ���ݷ����꣬ ���� д�� FIFO
                             .din(TxD_FIFO_din),    // i��FIFO д������   
                             .full(TxD_FIFO_full),      // o��FIFO �������� ��־�� ��ʱ����д������
                             // read    
                             .rd_en(TxD_start),     // i��FIFO ��ȡʹ��
                             .dout(TxD_data),           // o��FIFO ��ȡ����
                             .empty(TxD_FIFO_empty)     // o��FIFO �ѿ� ��־�� ��ʱ���ܶ�ȡ����  
                           );
   
  wire    [1:0]   state;
  //   state
  //    00��RxD_FIFO �ѿ�,  TxD_FIFO �������� 
  //    01��RxD_FIFO �ѿ�,  TxD_FIFO δ��      
  //    10��RxD_FIFO δ��,  TxD_FIFO ��������
  //    11��RxD_FIFO δ��,  TxD_FIFO δ��      
  
  // state[1]��ֻ����Ϊ1ʱ��ʾ�����յ�����
  // state[0]��ֻ����Ϊ1ʱ��ʾ���ڿ��У��ɷ�������
  
  assign state[1] = RxD_FIFO_empty ? 1'b0 : 1'b1;
  assign state[0] = TxD_FIFO_full  ? 1'b0 : 1'b1; 

  
   /// ������
 // Serial_state
 // [0] : rst                       ��λ �� ������д״̬ 
 // [1] : is_SerialDate && ram_we_n     ������(��������)
 // [2] : is_SerialDate && !ram_we_n    д����(��������)
 // [3] : is_SerialStat                 (��ʾ��ʱ����״̬)
 
 assign RxD_FIFO_ren = Serial_state[1] ? 1'b1 : 1'b0;
 
 assign TxD_FIFO_wen = Serial_state[2] ? 1'b1 : 1'b0;
 
 assign TxD_FIFO_din = Serial_state[2] ? ram_data_i[7:0] : 8'h00;

        
        // ���� ���� rxd ���յ����ݣ����ڴ��� CPU ִ��loadָ��д��Ĵ���
 always @ (*)
   begin
     if(Serial_state[0])
       serial_o = 32'h0000_0000;
     else if(Serial_state[3])           /// ��ȡ����״̬
       serial_o = {30'h0, state};
     else if(Serial_state[1])
             /// ��ȡ�����ͣ�������������£� �����ݣ������մ������� Դ��  rxd
       serial_o = {24'b0, RxD_FIFO_dout};
     else
       serial_o = 32'h0000_0000;
   end


  
endmodule
