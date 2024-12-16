`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: id.v
//-- DESCRIPTION  : 本模块为 译码模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////



module id(
    input   wire    [31:0]  pc_i,  
    output  wire    [31:0]  pc_o,     
    input   wire    [31:0]  inst_i,
    output  wire    [31:0]  inst_o,
        
    /* 执行阶段EX写寄存器的信息， 用于解决数据相关 */
    input   wire    ex_reg_wen_i,           // 写使能
    input   wire    [4:0]   ex_waddr_i,     // 写地址
    input   wire    [31:0]  ex_wdata_i,     // 写数据
    
    /* 送到执行阶段EX的信息 */
    output  reg     [2:0]   aluop_o,        // 运算的子类型（准确类型）
    output  wire    [2:0]   alusel_o,       // 运算的类型，例如逻辑、算数、移位
    output  wire    [31:0]  reg1_data_o,    // 源操作数1
    output  wire    [31:0]  reg2_data_o,    // 源操作数2
    output  wire    reg_wen_o,              // 写使能，能否写入目的寄存器
    output  wire    [4:0]   waddr_o,        // 写地址
    
    
    /* 访存阶段MEM写寄存器的信息， 用于解决数据相关 */
    input   wire    mem_reg_wen_i,          // 写使能
    input   wire    [4:0]   mem_waddr_i,    // 写地址
    input   wire    [31:0]  mem_wdata_i,    // 写数据
    
    /* 寄存器regfile送来的信息， 用于解决数据相关 */
    input   wire    [31:0]  reg1_data_i,
    input   wire    [31:0]  reg2_data_i,
    
    /* 伪·cache送来的信息， 用于解决数据相关 */
    input   wire    hit_dcache_i,
    input   wire    [31:0]  hit_extram_data_i,
    
    input   wire    ex_inst_is_load_i,      //EX阶段 是否执行load指令
    input   wire    [31:0]  ex_memory_Load_AND_Store_addr_i, 
    input   wire    [31:0]  mem_last_memorystore_addr_i,  
    input   wire    [31:0]  mem_last_memorystore_data_i,   
        
    
    /* 送到寄存器regfile的信息 */
    output  wire    reg1_ren_o,             // 读使能
    output  wire    reg2_ren_o,
    output  wire    [4:0]   reg1_addr_o,    // 读地址
    output  wire    [4:0]   reg2_addr_o,
    
    /*送到取值阶段IF的信息*/
    output  wire    [4:0]   j_inst_sign_o,
    output  wire    [31:0]  j_address_temp_o,
    output  wire    [31:0]  branch_address_temp_o,
    
    output  reg     [31:0]  link_addr_o,        // 寄存 jal, jalr 指令专用写寄存器的值
    
    output  wire    stallreq_from_id         //ID模块存在load数据相关，需要发射流水线暂停信号 
    );
    
    
  /* 对指令inst各字段进行分割 */
  wire  [5:0]   op  = inst_i[31:26];
  wire  [4:0]   rs_code = inst_i[25:21];
  wire  [4:0]   rt_code = inst_i[20:16];
  wire  [4:0]   rd_code = inst_i[15:11];
  wire  [4:0]   shamt = inst_i[10:6];
  wire  [5:0]   func = inst_i[5:0];
  
  wire  [31:0]  pc_plus_4;      // 用作j、jal，  beq、ben、bgtz 指令跳转地址的一部分
  wire  [31:0]  pc_plus_8;      // 作jal、 jalr写寄存器的值（当前PC）
  assign pc_plus_4 = pc_i + 4;  
  assign pc_plus_8 = pc_i + 8;  
  
  
  assign branch_address_temp_o = {{14{inst_i[15]}}, inst_i[15:0], 2'b00} + pc_plus_4;   // 分支指令的(如果可以跳转)转移地址
  assign j_address_temp_o = {pc_plus_4[31:28], inst_i[25:0], 2'b00};            // 跳转指令的转移地址
  
  assign inst_o = inst_i;       // 送入 EX阶段，用于load记载指令计算读取memory数据的地址
  assign pc_o = pc_i;           // 仅调试ID阶段时，方便观看此时指令的pc所设，并送入EX阶段
  
  
  /*******************************  指令分类识别  ********************************/
  wire [31:0]  imm;    // 立即数
  wire imm_sign1;        // 操作数1读取立即数的标志
  wire imm_sign2;        // 操作数2读取立即数的标志
  wire op_is_zero;
  wire rs_is_zero;
  wire rt_is_zero;
  wire shamt_is_zero;
  assign op_is_zero = (op == 6'b000_000);
  assign rs_is_zero = (rs_code == 5'b00000);
  assign rt_is_zero = (rt_code == 5'b00000);
  assign shamt_is_zero = (shamt == 5'b00000);
  
  wire logic;      // 逻辑指令 : and, andi, or, ori, lui, xor, xori
  wire shift;      // 移位指令 : sll, srl, sra
  wire arithmetic; // 算术指令 : addu, addiu, slt
  wire mul;        // 乘法指令 : mul
  wire jump;       // 转移指令 : j, jal, jr, jalr, beq, bne, bgtz
  wire load_and_store;//访存指令 : lb, lw, sb, sw
  wire inst_valid;                  //指令是否有效
  
  assign logic = op_is_zero ? 
                            (shamt_is_zero ? 
                                            ((func == 6'b100_100) ? 1'b1 :                  // and
                                             (func == 6'b100_101) ? 1'b1 :                  // or
                                             (func == 6'b100_110) ? 1'b1 : 1'b0) : 1'b0) :  // xor
                (op == 6'b001_100) ? 1'b1 :         // andi
                (op == 6'b001_101) ? 1'b1 :         // ori
                (op == 6'b001_110) ? 1'b1 :         // xori
                (op == 6'b001_111) ? 1'b1 : 1'b0;   // lui
  
  assign shift = op_is_zero ? 
                            (rs_is_zero ? 
                                        ((func == 6'b000_000) ? 1'b1 :                          // sll 
                                         (func == 6'b000_010) ? 1'b1 :                          // srl
                                         (func == 6'b000_011) ? 1'b1 : 1'b0) : 1'b0) : 1'b0 ;   // sra
  
  assign arithmetic = op_is_zero ? 
                                (shamt_is_zero ? 
                                                ((func == 6'b100_001) ? 1'b1 :                  // addu
                                                 (func == 6'b101_010) ? 1'b1 : 1'b0) : 1'b0) :  // slt
                      (op == 6'b001_001) ? 1'b1 : 1'b0;         // addiu
  
  assign mul = (op == 6'b011_100) ? 
                                  (shamt_is_zero ? 
                                                 ((func == 6'b000_010) ? 1'b1 : 1'b0) : 1'b0) : 1'b0;   //mul
  
  assign jump = op_is_zero ? 
                           ((inst_i[20:0] == 21'b00000_00000_00000_001000) ? 1'b1 :                                              // jr
                            (rt_is_zero ?                                                                                       
                                        (shamt_is_zero ?                                                                        
                                                        ((func == 6'b001_001) ? 1'b1 : 1'b0) : 1'b0) :1'b0)) :    // jalr
                (op == 6'b000_010) ? 1'b1 :         // j
                (op == 6'b000_011) ? 1'b1 :         // jal
                (op == 6'b000_100) ? 1'b1 :         // beq
                (op == 6'b000_101) ? 1'b1 :         // bne
                (op == 6'b000_111) ? 
                                    (rt_is_zero ? 1'b1 : 1'b0) : 1'b0;   // bgtz
  
  assign load_and_store = (op == 6'b100_000) ? 1'b1 :           // lb
                          (op == 6'b100_011) ? 1'b1 :           // lw
                          (op == 6'b101_000) ? 1'b1 :           // sb
                          (op == 6'b101_011) ? 1'b1 : 1'b0;     // sw
  
  
  
  // NOP空指令： alusel_o = 3'b000 
  assign alusel_o = logic ? 3'b001 : shift ? 3'b010 : arithmetic ? 3'b100 : 
                    mul ? 3'b101 : jump ? 3'b110 : load_and_store ? 3'b111 : 3'b000;
  
  assign inst_valid = (alusel_o != 3'b000);
  
  
  /************************* 立即数修改 *****************************/
  assign imm = logic ? 
                    ((op == 6'b001_111) ? {inst_i[15:0], 16'h0} :               // lui
                    (op_is_zero == 1'b0) ? {16'h0, inst_i[15:0]} : 32'h0) :     // andi, ori, xori
               shift ? {27'h0, shamt} :                                         // sll, srl, sra
               (op == 6'b001_001) ? {{16{inst_i[15]}}, inst_i[15:0]} : 32'h0;   // addiu
  
  assign imm_sign1 = shift ? 1'b1 : 1'b0;   //sll, srl, sra
  
  assign imm_sign2 = logic ? 
                            ((op_is_zero == 1'b0) ? 1'b1 : 1'b0) :      // andi, ori, xori
                    (op == 6'b001_001) ? 1'b1 : 1'b0;                   // addiu

  
 /********************  JAL、JALR跳转指令写寄存器的值修改  **********************/
  always @ (*)
    begin
      if( (op == 6'b000_011)                                                         // jal
        || (op_is_zero && rt_is_zero && shamt_is_zero && (func == 6'b001_001)) )    // jalr
        link_addr_o = pc_plus_8;   
      else
        link_addr_o = 32'h0000_0000;
    end
  
    /****************************** 跳转指令标志 *****************************/
  
  assign j_inst_sign_o = jump ? 
                            ((op == 6'b000_010) ? 5'b00001 :            // j
                             (op == 6'b000_011) ? 5'b00001 :            // jal
                             op_is_zero ?  5'b00010 :                   // jr, jalr
                             (op == 6'b000_100) ? 5'b00100 :            // beq
                             (op == 6'b000_101) ? 5'b01000 :            // bne
                             (op == 6'b000_111) ? 5'b10000 : 5'b00000) : 5'b00000;  // bgtz      
  
  
  /*****************************************************************************/
  
  assign reg_wen_o = inst_valid ? 
                                (jump ? 
                                       ((op == 6'b000_011) ? 1'b1 :           // 转移指令 仅jal，jalr写寄存器
                                        op_is_zero ? 
                                                    ((func == 6'b001_001) ? 1'b1 : 1'b0) : 1'b0) :  
                                (op == 6'b101_000) ? 1'b0 :                   // 访存指令 仅sb，sw不写寄存器
                                (op == 6'b101_011) ? 1'b0 : 1'b1) : 1'b0;       // 其余指令均写寄存器
  
  assign waddr_o = (op == 6'b000_011) ? 5'd31 :     // 写31号寄存器: jal
                    op_is_zero ? rd_code : 
                        //写Rd号寄存器: and, or, xor // sll, srl, sra // addu, slt // jr(不写),jalr
                    mul ? rd_code : rt_code;        //写Rd号寄存器: mul
                        // 其余均写Rt号寄存器
  
  assign reg1_addr_o = inst_i[25:21];
  assign reg2_addr_o = inst_i[20:16];
  
  assign reg1_ren_o = shift ? 1'b0 :                        // sll, srl, sra
                      (op == 6'b000_010) ? 1'b0 :           // j
                      (op == 6'b000_011) ? 1'b0 :           // jal
                      (inst_valid == 1'b0) ? 1'b0 : 1'b1;
  
  assign reg2_ren_o = logic ?           
                            (op_is_zero ? 1'b1 : 1'b0) :    // and, or, xor
                      shift ? 1'b1:                         // sll, srl, sra
                      arithmetic ? 
                            (op_is_zero ? 1'b1 : 1'b0) :    // addu, slt
                      mul ? 1'b1 :                          // mul
                      (op == 6'b000_100) ? 1'b1 :           // beq
                      (op == 6'b000_101) ? 1'b1 :           // bne
                      (op == 6'b101_000) ? 1'b1 :           // sb
                      (op == 6'b101_011) ? 1'b1 : 1'b0;     // sw

  always @ (*)
    begin     
          aluop_o <= 3'b000;    //  ALU 每种运算类型对应的子类型， {alusel_o， aluop_o}即为ALU准确运算类型          
     
      if(op_is_zero && rs_is_zero)
        begin
          if(func == 6'b000_010)         // srl
              aluop_o <= 3'b001;
          else if(func == 6'b000_011)         // sra
              aluop_o <= 3'b010;
        end
        
      if((op == 6'b001_111) && rs_is_zero)  // lui     
          aluop_o <= 3'b001;     
           
      if((op == 6'b011_100) && shamt_is_zero && (func == 6'b000_010))   // mul
          aluop_o <= 3'b000;
          
          case(op)
            6'b000_000:
                begin
                  case(shamt)
                    5'b00000:
                            begin
                              case(func)
                                6'b100_101:     // or
                                      aluop_o <= 3'b001;
                                6'b100_110:     // xor
                                      aluop_o <= 3'b010;
                                6'b101_010:     // slt
                                      aluop_o <= 3'b001;
                              endcase
                            end
                  endcase
                end
            6'b001_101:     // ori
                  aluop_o <= 3'b001;
            6'b001_110:     // xori
                  aluop_o <= 3'b010;
            6'b100_011:     // lw
                  aluop_o <= 3'b001;
            6'b101_000:     // sb
                  aluop_o <= 3'b010;
            6'b101_011:     // sw
                  aluop_o <= 3'b011;
          endcase//endcase(op)
        end



assign reg1_data_o = reg1_ren_o ? 
                        ((ex_inst_is_load_i && (ex_waddr_i == reg1_addr_o)) ? 
                            ((ex_memory_Load_AND_Store_addr_i == mem_last_memorystore_addr_i) ? mem_last_memorystore_data_i :
                            //（上一条指令）在EX 阶段执行：load指令  
                            //（上一条指令）EX阶段_load写寄存器地址 = （正在执行指令）ID阶段_操作数地址（操作数确定读取）
                            // EX阶段_load读存储器地址 = MEM阶段_最近一次store写存储器地址
                            // 以上属于小优化
                            hit_dcache_i ? hit_extram_data_i : 32'h0000_0000) :
                         (ex_reg_wen_i && (ex_waddr_i == reg1_addr_o)) ? ex_wdata_i :
                            // 与上一条指令同写一个寄存器地址
                         (mem_reg_wen_i && (mem_waddr_i == reg1_addr_o)) ? mem_wdata_i : reg1_data_i) :
                            // 与上上一条指令同写一个寄存器地址         //正常赋值，需要读操作数1，赋值寄存器里的数据1
                      imm_sign1 ? imm : 32'h0000_0000;
                      //正常赋值，需要读立即数，赋值经过扩展或其他操作的立即数
                      
assign reg2_data_o = reg2_ren_o ? 
                        ((ex_inst_is_load_i && (ex_waddr_i == reg2_addr_o)) ? 
                            ((ex_memory_Load_AND_Store_addr_i == mem_last_memorystore_addr_i) ? mem_last_memorystore_data_i :
                            hit_dcache_i ? hit_extram_data_i : 32'h0000_0000) :
                         (ex_reg_wen_i && (ex_waddr_i == reg2_addr_o)) ? ex_wdata_i :
                         (mem_reg_wen_i && (mem_waddr_i == reg2_addr_o)) ? mem_wdata_i : reg2_data_i) :
                      imm_sign2 ? imm : 32'h0000_0000;                   
                         

 
  
// ID数据相关 成立条件： EX阶段执行加载指令（lw、lb）, EX阶段写地址 = ID阶段的读操作数地址， ID阶段读地址使能有效
wire stallreq_for_reg1_loadrelate;
assign stallreq_for_reg1_loadrelate  = 
        (reg1_ren_o && ex_inst_is_load_i && (ex_waddr_i == reg1_addr_o)) ? 
        ((ex_memory_Load_AND_Store_addr_i == mem_last_memorystore_addr_i) ? 1'b0 : 
          hit_dcache_i ? 1'b0 : 1'b1) : 1'b0;  
        // 若EX阶段_load读存储器地址 = MEM阶段_最近一次store写存储器地址， 则命中存储的最近一次store写存储器的数据
        // 此时流水线无需阻塞

wire stallreq_for_reg2_loadrelate; 
assign stallreq_for_reg2_loadrelate  = 
        (reg2_ren_o && ex_inst_is_load_i && (ex_waddr_i == reg2_addr_o)) ? 
        ((ex_memory_Load_AND_Store_addr_i == mem_last_memorystore_addr_i) ? 1'b0 : 
         hit_dcache_i ? 1'b0 : 1'b1) : 1'b0;  

// 若ID模块数据相关，需要暂停流水线
assign stallreq_from_id = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

  
endmodule
