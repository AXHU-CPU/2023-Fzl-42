`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: mem.v
//-- DESCRIPTION  : 本模块为 访存模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module mem(    
    input   wire    [31:0]  ram_data_i,
    
    input   wire    mem_reg_wen_i,
    input   wire    [4:0]   mem_waddr_i,
    input   wire    [31:0]  mem_wdata_i,
    
    input   wire    [3:0]   mem_Load_and_Store_op_i,  // 只对load类和store类指令做数据处理
    
    input   wire    [31:0]  memory_Load_AND_Store_addr_i,   // load类指令读存储器的地址 或 store类指令写存储器的地址
    input   wire    [31:0]  reg2_data_i,            // store类指令写存储器的数据（根据具体指令进一步处理）
    
    input   wire    [31:0]  pc_i,
    output  wire    [31:0]  pc_o,
    
    output  wire    mem_reg_wen_o,
    output  wire    [4:0]   mem_reg_waddr_o,
    output  reg     [31:0]  mem_reg_wdata_o,
    
    output  wire    [3:0]   mem_sel_o,      // 读、写 存储器的字节选取，  注意：设计要求低电平有效
    output  wire    [31:0]  memory_Load_AND_Store_addr_o,
    output  wire    [31:0]  mem_memory_wdata_o,
        
    output  wire    stallreq_from_mem,
    
    input   wire    rst,
    input   wire    rom_ce,
    input   wire    mem_memory_wen,     // 注意：这里低电平有效
    input   wire    mem_is_base_ram_i,
    input   wire    mem_is_ext_ram_i,
    input   wire    mem_is_SerialDate_i,
    input   wire    mem_is_SerialStat_i,
    
    output  wire    [3:0]   base_ram_state,
    output  wire    [2:0]   ext_ram_state,
    output  wire    [3:0]   Serial_state
    );
  
  assign pc_o = pc_i;       // 仅调试MEM阶段时，方便观看此时指令的pc所设，并送入WB阶段
    
  // 避免对BaseRam结构冒险，为1确定此时MEM阶段执行的指令需要访问BaseRAM结构（此时IF取值阶段同时也需要访问BaseRam做取值操作）
  // stallreq_from_mem为1，
  //同时需要暂停IF（pc_reg）模块PC改变的和IF/ID模块inst改变（此刻IF阶段pc保持不变，inst为0x00000000），
  //以避免BaseRam造成结构冲突
  assign stallreq_from_mem =  mem_is_base_ram_i;


  assign mem_reg_wen_o = mem_reg_wen_i;
  assign mem_reg_waddr_o = mem_waddr_i;
  
  always @ (*)
    begin
      if(mem_Load_and_Store_op_i == 4'b1_000) // lb
        mem_reg_wdata_o <= ram_data_i;
      else if(mem_Load_and_Store_op_i == 4'b1_001) // lw
        mem_reg_wdata_o <= ram_data_i;
      else
        mem_reg_wdata_o <= mem_wdata_i;
    end
  
  
/***********************      访存RAM(包括串口)状态     **************************/
  assign base_ram_state = rst ? 4'b0001 :
                          mem_is_base_ram_i ? (mem_memory_wen ? 4'b0100 : 4'b1000) : 
                          rom_ce ? 4'b0010 : 4'b0001; 
  // base_ram_state // [3]: (RAM)写数据 ；[2]: (RAM)读数据 ；[1]: (ROM)读指令；[0]: 复位 或 不读不写状态
  
  assign ext_ram_state = rst ? 3'b001 :
                         mem_is_ext_ram_i ? (mem_memory_wen ? 3'b010 : 3'b100) : 3'b001;
  // ext_ram_state // [2]: 写数据；[1]: 读数据；[0]: 复位 或 不读不写状态 
  
  assign Serial_state = rst ? 4'b0001 :
                        mem_is_SerialDate_i ? (mem_memory_wen ? 4'b0010 : 4'b0100) :
                        mem_is_SerialStat_i ? 4'b1000 : 4'b0001;
  // Serial_state // [3]: (显示此时串口状态) ；[2]: 写数据(发送数据) ；[1]: 读数据(接收数据)；[0]: 复位 或 不读不写状态

/*************************    访存传入RAM的数据    ***************************/                             
  assign memory_Load_AND_Store_addr_o = mem_Load_and_Store_op_i[3] ? memory_Load_AND_Store_addr_i : 32'h0;
  
  assign mem_memory_wdata_o = (mem_Load_and_Store_op_i == 4'b1_010) ? {3'd4{reg2_data_i[7:0]}} :
                              (mem_Load_and_Store_op_i == 4'b1_011) ? reg2_data_i : 32'h0;
  
  assign mem_sel_o = (mem_Load_and_Store_op_i == 4'b1_000) ? 
                                                            ((memory_Load_AND_Store_addr_i[1:0] == 2'b00) ? 4'b1110 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b01) ? 4'b1101 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b10) ? 4'b1011 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b11) ? 4'b0111 : 4'b1111) :
                     (mem_Load_and_Store_op_i == 4'b1_001) ? 4'b0000 :
                     (mem_Load_and_Store_op_i == 4'b1_010) ? 
                                                            ((memory_Load_AND_Store_addr_i[1:0] == 2'b00) ? 4'b1110 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b01) ? 4'b1101 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b10) ? 4'b1011 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b11) ? 4'b0111 : 4'b1111) :
                     (mem_Load_and_Store_op_i == 4'b1_011) ? 4'b0000 : 4'b1111;
  

endmodule
