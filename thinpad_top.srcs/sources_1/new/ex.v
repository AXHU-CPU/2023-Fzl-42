`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: ex.v
//-- DESCRIPTION  : 本模块为 执行模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////



module ex(
    input   wire    [31:0]  inst_i,     //用于计算load指令地址
    input   wire    [31:0]  pc_i,
    output  wire    [31:0]  pc_o,
    
    
    input   wire    [2:0]   alusel_i, 
    input   wire    [2:0]   aluop_i,
    output  wire    [3:0]   Load_and_Store_op_o,  //送入MEM阶段，可识别为加载指令和存储指令的类型 
    output  wire    ex_inst_is_load_o,  //送入ID模块，作load数据冲突判断一部分，EX阶段是否执行load类指令
    output  wire    [31:0]  ex_memory_Load_AND_Store_addr_o,
    output  wire    [31:0]  reg2_data_o,
    
    input   wire    reg_wen_i,
    output  wire    reg_wen_o,             
    input   wire    [4:0]   waddr_i,
    output  wire    [4:0]   waddr_o,
            
    input   wire    [31:0]  reg1_data_i,
    input   wire    [31:0]  reg2_data_i,
    
    input   wire    [31:0]  link_address_i,     // 寄存 jal, jalr 指令专用写寄存器的值
    output  reg     [31:0]  wdata_o,
    
    output  wire    ex_memory_wen_o,
    output  wire    ex_is_base_ram_o,
    output  wire    ex_is_ext_ram_o,
    output  wire    ex_is_SerialDate_o,
    output  wire    ex_is_SerialStat_o     
    );
    
  assign pc_o = pc_i;       // 仅调试EX阶段时，方便观看此时指令的pc所设，并送入MEM阶段
  
  
  wire [5:0] aluselop;
  assign aluselop = {alusel_i, aluop_i};        //ALU准确运算类型
  assign Load_and_Store_op_o = {(alusel_i==3'b111), aluop_i};   //送入MEM阶段，可识别为加载指令和存储指令的类型
  
  assign ex_inst_is_load_o = (aluselop == 6'b111_000) ? 1'b1 :
                             (aluselop == 6'b111_001) ? 1'b1 : 1'b0;  
            //送入ID模块，作 EX阶段 是否执行load类指令，供ID模块load竞争冒险（数据相关）条件判断
  assign ex_memory_Load_AND_Store_addr_o = 
                (alusel_i==3'b111) ? reg1_data_i + {{16{inst_i[15]}}, inst_i[15:0]} : 32'h0;
            // 计算 加载指令从存储器所读数据地址 或者是 存储指令写入存储器的地址
  assign reg2_data_o = reg2_data_i;
            // 送入MEM阶段，作存储指令写入存储器数据
  
  
  wire [31:0] reg1_lt_reg2;         // slt指令 数据大小判断
  assign reg1_lt_reg2 = (($signed(reg1_data_i)) < ($signed(reg2_data_i))) ? 32'd1 : 32'd0;    //slt指令
  
  wire [31:0] mulres = reg1_data_i * reg2_data_i;
  
  wire [31:0] wdata_temp;
  assign wdata_temp = (aluselop == 6'b001_000) ? reg1_data_i & reg2_data_i :   // and, andi
                   (aluselop == 6'b001_001) ? reg1_data_i | reg2_data_i :   // or,  ori, lui
                   (aluselop == 6'b001_010) ? reg1_data_i ^ reg2_data_i :   // xor, xori
                   (aluselop == 6'b010_000) ? reg2_data_i << reg1_data_i[4:0] :             // sll
                   (aluselop == 6'b010_001) ? reg2_data_i >> reg1_data_i[4:0] :             // srl
                   (aluselop == 6'b010_010) ? //($signed(reg2_data_i)) >>> reg1_data_i[4:0] : // sra
                        (({32{reg2_data_i[31]}} << (6'd32-{1'b0, reg1_data_i[4:0]})) | reg2_data_i >> reg1_data_i[4:0]) :
                   (aluselop == 6'b100_000) ? reg1_data_i + reg2_data_i :   // addu, addiu
                   (aluselop == 6'b100_001) ? reg1_lt_reg2 :                // slt
                   //(aluselop == 6'b101_000) ? reg1_data_i * reg2_data_i :   // mul
                   (aluselop == 6'b110_000) ? link_address_i :
                                               32'h0;
    always @ (*)
      begin
        if(alusel_i == 3'b101)
          wdata_o = mulres;
        else
          wdata_o = wdata_temp;
      end
    
    assign waddr_o = waddr_i;
    assign reg_wen_o = reg_wen_i;
  
  
  
  
  
  // EX阶段 提前 判断访存 写状态，避免在MEM计算时延迟开始访存时间
            // 注意：这里 ex_memory_wen_o 是低电平有效
  assign ex_memory_wen_o = (aluselop == 6'b111_010) ? 1'b0 :
                           (aluselop == 6'b111_011) ? 1'b0 : 1'b1;
  
  /// EX阶段 提前 处理读取或者写入的数据范围，方便传给 MEM阶段 时作 访存状态改变
  assign ex_is_base_ram_o = 
        (ex_memory_Load_AND_Store_addr_o >= 32'h80000000) && (ex_memory_Load_AND_Store_addr_o < 32'h80400000);
        // load 或 store指令 访存 BaseRAM
  assign ex_is_ext_ram_o =  
        (ex_memory_Load_AND_Store_addr_o >= 32'h80400000) && (ex_memory_Load_AND_Store_addr_o < 32'h80800000);
        // load 或 store指令 访存 ExtRAM
  assign ex_is_SerialStat_o = (ex_memory_Load_AND_Store_addr_o == 32'hBFD003FC);     
  assign ex_is_SerialDate_o = (ex_memory_Load_AND_Store_addr_o == 32'hBFD003F8);

endmodule
