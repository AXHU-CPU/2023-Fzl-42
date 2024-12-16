`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: myCPU.v
//-- DESCRIPTION  : 本模块为 CPU的顶层文件（不包括对SRAM、串口的处理）
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module myCPU(
    input   wire    clk, 
    input   wire    rst,
    
    output  wire    [3:0]   base_ram_state,
    output  wire    [2:0]   ext_ram_state,
    output  wire    [3:0]   Serial_state,
    
    input   wire    [31:0]  inst_i,       // BaseRAM里的指令
    output  wire    [31:0]  rom_addr_o, 
		    
	input   wire    [31:0]  ram_data_i, 
	output  wire    [31:0]  ram_addr_o, 
	output  wire    [31:0]  ram_data_o, 
	output  wire    [3:0]   ram_sel_n  
    );
  
  wire rom_ce;
  wire stall;
  wire [4:0] j_inst_sign_o;
  wire [31:0] branch_address_temp_o;
  wire [31:0] j_address_temp_o;
  wire [31:0] id_reg1_data_o;
  wire [31:0] id_reg2_data_o;
    
    pc_reg  IF(
                .clk                    (clk),
                .rst                    (rst),
                
                .stall                  (stall),
                
                .j_inst_sign_i          (j_inst_sign_o),
                .j_address_temp_i       (j_address_temp_o),
                .branch_address_temp_i  (branch_address_temp_o),
                .id_reg1_data_i         (id_reg1_data_o),
                .id_reg2_data_i         (id_reg2_data_o),
                
                .pc                     (rom_addr_o),
                .ce                     (rom_ce)
                );
    
  wire [31:0] id_pc;
  wire [31:0] id_inst;
  
    if_id   IF_ID(
                .clk        (clk),
                .rst        (rst),
                
                .stall      (stall),
                .if_pc      (rom_addr_o),
                .if_inst    (inst_i),
                .id_pc      (id_pc),
                .id_inst    (id_inst)
                );
  
  wire mem_memory_wen_i;
  wire ex_is_ext_ram_o;
  wire ex_inst_is_load_o;
  wire hit_dcache;
  wire [31:0] hit_extram_data;
  wire [31:0] ex_memory_Load_AND_Store_addr_o;
  
    extram_cache Dcache(
                .clk                (clk),
                .rst                (rst),
                
                .ext_ram_state      (ext_ram_state),
                .ram_addr_i         (ram_addr_o),
                .ram_wdata_i        (ram_data_o),
               
                .is_ext_ram_i       (ex_is_ext_ram_o),
                .hit_ren_i          (ex_inst_is_load_o),
                .hit_extram_addr    (ex_memory_Load_AND_Store_addr_o), 
                .hit_extram_data    (hit_extram_data),
                .hit_dcache         (hit_dcache)
                );
    
    
  
  wire [5:0] exop_o;
  wire ex_reg_wen_o;
  wire [31:0] ex_wdata_o;
  wire [4:0] ex_waddr_o;
  
  wire [2:0] id_aluop_o;
  wire [2:0] id_alusel_o;
  wire id_reg_wen_o;
  wire [4:0] id_waddr_o;

  wire [31:0] id_inst_o;
  
  wire mem_reg_we_o; 
  wire [4:0] mem_reg_waddr_o;
  wire [31:0] mem_reg_wdata_o;
  
  wire [31:0] mem_last_memorystore_addr_o;
  wire [31:0] mem_last_memorystore_data_o;
  
  wire [31:0] reg1_data_i;
  wire [31:0] reg2_data_i;
  wire reg1_ren_o;
  wire reg2_ren_o;
  wire [31:0] reg1_addr_o;
  wire [31:0] reg2_addr_o;
  
  wire [31:0] id_link_addr_o;
  wire [31:0] id_pc_o;
  
  wire stallreq_from_id;
  
  wire hit_dcache_sign_o;
  wire [31:0] mem_dcache_data_o;
    id      ID(
                .pc_i                               (id_pc),
                .pc_o                               (id_pc_o),
                .inst_i                             (id_inst),
                
                .ex_reg_wen_i                       (ex_reg_wen_o),
                .ex_wdata_i                         (ex_wdata_o),
                .ex_waddr_i                         (ex_waddr_o),
                .aluop_o                            (id_aluop_o),
                .alusel_o                           (id_alusel_o),
                .reg_wen_o                          (id_reg_wen_o),
                .waddr_o                            (id_waddr_o),
                .reg1_data_o                        (id_reg1_data_o),
                .reg2_data_o                        (id_reg2_data_o),
                .inst_o                             (id_inst_o),
                
                .mem_reg_wen_i                      (mem_reg_we_o),
                .mem_waddr_i                        (mem_reg_waddr_o),
                .mem_wdata_i                        (mem_reg_wdata_o),
                
                .hit_dcache_i                       (hit_dcache),
                .hit_extram_data_i                  (hit_extram_data),
                
                .ex_inst_is_load_i                  (ex_inst_is_load_o),
                .ex_memory_Load_AND_Store_addr_i    (ex_memory_Load_AND_Store_addr_o),
                .mem_last_memorystore_addr_i        (mem_last_memorystore_addr_o),
                .mem_last_memorystore_data_i        (mem_last_memorystore_data_o),
                
                .reg1_data_i                        (reg1_data_i),
                .reg2_data_i                        (reg2_data_i),
                .reg1_ren_o                         (reg1_ren_o),
                .reg2_ren_o                         (reg2_ren_o),
                .reg1_addr_o                        (reg1_addr_o),
                .reg2_addr_o                        (reg2_addr_o),
                
                .j_inst_sign_o                      (j_inst_sign_o),
                .j_address_temp_o                   (j_address_temp_o),
                .branch_address_temp_o              (branch_address_temp_o),
                .link_addr_o                        (id_link_addr_o),
                
                .stallreq_from_id                   (stallreq_from_id)
                );
  
  
  
  wire [2:0] ex_aluop_i;
  wire [2:0] ex_alusel_i;
  wire [31:0] ex_reg1_data_i;
  wire [31:0] ex_reg2_data_i;
  wire [31:0] ex_reg_wen_i;
  wire [31:0] ex_waddr_i;
  wire [31:0] ex_link_addr_i;
  wire [31:0] ex_inst_i;
  wire [31:0] ex_pc_i;
  
    id_ex   ID_EX(
                .clk                        (clk),
                .rst                        (rst),
                
                .stall                      (stall),
                
                .id_aluop                   (id_aluop_o),
                .id_alusel                  (id_alusel_o),
                .id_reg1_data               (id_reg1_data_o),
                .id_reg2_data               (id_reg2_data_o),
                .id_waddr                   (id_waddr_o),
                .id_reg_wen                 (id_reg_wen_o),
                .id_link_addr               (id_link_addr_o),
                .id_inst                    (id_inst_o),
                .id_pc                      (id_pc_o),
                
                .ex_aluop                   (ex_aluop_i),
                .ex_alusel                  (ex_alusel_i),
                .ex_reg1_data               (ex_reg1_data_i),
                .ex_reg2_data               (ex_reg2_data_i),
                .ex_waddr                   (ex_waddr_i),
                .ex_reg_wen                 (ex_reg_wen_i),
                .ex_link_addr               (ex_link_addr_i),
                .ex_inst                    (ex_inst_i),
                .ex_pc                      (ex_pc_i)
                );
    
  wire [3:0] ex_Load_and_Store_op_o;  
  wire [31:0] ex_reg2_data_o;
  wire [31:0] ex_pc_o;
  
  wire ex_memory_wen_o;
  wire ex_is_base_ram_o;
  wire ex_is_SerialDate_o;
  wire ex_is_SerialStat_o;
  
    ex      EX(
                .inst_i                             (ex_inst_i),
                .pc_i                               (ex_pc_i),
                .pc_o                               (ex_pc_o),
                
                
                .alusel_i                           (ex_alusel_i),
                .aluop_i                            (ex_aluop_i),
                .Load_and_Store_op_o                (ex_Load_and_Store_op_o),
                .reg_wen_i                          (ex_reg_wen_i),
                .reg_wen_o                          (ex_reg_wen_o),
                .waddr_i                            (ex_waddr_i),
                .waddr_o                            (ex_waddr_o),
                .reg1_data_i                        (ex_reg1_data_i),
                .reg2_data_i                        (ex_reg2_data_i),
                .link_address_i                     (ex_link_addr_i),
                .wdata_o                            (ex_wdata_o),
                                
                .ex_inst_is_load_o                  (ex_inst_is_load_o),
                .ex_memory_Load_AND_Store_addr_o    (ex_memory_Load_AND_Store_addr_o),
                .reg2_data_o                        (ex_reg2_data_o),
                
                .ex_memory_wen_o                    (ex_memory_wen_o),
                .ex_is_base_ram_o                   (ex_is_base_ram_o),
                .ex_is_ext_ram_o                    (ex_is_ext_ram_o),
                .ex_is_SerialDate_o                 (ex_is_SerialDate_o),
                .ex_is_SerialStat_o                 (ex_is_SerialStat_o)  
                );
  
  wire [3:0] mem_Load_and_Store_op_i;              
  wire [4:0] mem_waddr_i;
  wire mem_reg_wen_i;
  wire [31:0] mem_wdata_i;
  wire [31:0] mem_memory_Load_AND_Store_addr_i;
  wire [31:0] mem_reg2_data_i;
  wire [31:0] mem_pc_i;
  
  wire mem_is_base_ram_i;
  wire mem_is_ext_ram_i;
  wire mem_is_SerialDate_i;
  wire mem_is_SerialStat_i;
  
    ex_mem  EX_MEM(
                .clk                                (clk),
                .rst                                (rst),
                                
                .ex_Load_and_Store_op               (ex_Load_and_Store_op_o),
                .ex_reg_wen                         (ex_reg_wen_o),
                .ex_waddr                           (ex_waddr_o),
                .ex_wdata                           (ex_wdata_o),
                
                .ex_memory_Load_AND_Store_addr      (ex_memory_Load_AND_Store_addr_o),
                .ex_reg2_data                       (ex_reg2_data_o),
                                
                .ex_pc                              (ex_pc_o),
                
                .ex_memory_wen                     (ex_memory_wen_o),
                .ex_is_base_ram                    (ex_is_base_ram_o),
                .ex_is_ext_ram                     (ex_is_ext_ram_o),
                .ex_is_SerialDate                  (ex_is_SerialDate_o),
                .ex_is_SerialStat                  (ex_is_SerialStat_o),
                
                .mem_Load_and_Store_op              (mem_Load_and_Store_op_i),
                .mem_reg_wen                        (mem_reg_wen_i),
                .mem_waddr                          (mem_waddr_i),
                .mem_wdata                          (mem_wdata_i),
                
                .mem_memory_Load_AND_Store_addr     (mem_memory_Load_AND_Store_addr_i),
                .mem_reg2_data                      (mem_reg2_data_i),
                
                .mem_pc                             (mem_pc_i),
                
                .mem_memory_wen                     (mem_memory_wen_i),
                .mem_is_base_ram                    (mem_is_base_ram_i),
                .mem_is_ext_ram                     (mem_is_ext_ram_i),
                .mem_is_SerialDate                  (mem_is_SerialDate_i),
                .mem_is_SerialStat                  (mem_is_SerialStat_i),
                
                
                .mem_last_memorystore_addr          (mem_last_memorystore_addr_o),
                .mem_last_memorystore_data          (mem_last_memorystore_data_o)
                );
    
  wire [31:0] mem_pc_o;
  wire stallreq_from_mem;
  
    mem     MEM(
                .ram_data_i                     (ram_data_i),
                
                .mem_reg_wen_i                  (mem_reg_wen_i),
                .mem_waddr_i                    (mem_waddr_i),
                .mem_wdata_i                    (mem_wdata_i),
                
                .mem_Load_and_Store_op_i        (mem_Load_and_Store_op_i),
                
                .memory_Load_AND_Store_addr_i   (mem_memory_Load_AND_Store_addr_i),
                .reg2_data_i                    (mem_reg2_data_i),
                                
                .pc_i                           (mem_pc_i),
                .pc_o                           (mem_pc_o),
                
                .mem_reg_wen_o                  (mem_reg_we_o),
                .mem_reg_waddr_o                (mem_reg_waddr_o),
                .mem_reg_wdata_o                (mem_reg_wdata_o),
                
                .mem_sel_o                      (ram_sel_n),
                .memory_Load_AND_Store_addr_o   (ram_addr_o),
                .mem_memory_wdata_o             (ram_data_o),
                                
                .stallreq_from_mem              (stallreq_from_mem),
                
                .rst                            (rst),
                .rom_ce                         (rom_ce),
                .mem_memory_wen                 (mem_memory_wen_i),
                .mem_is_base_ram_i              (mem_is_base_ram_i),
                .mem_is_ext_ram_i               (mem_is_ext_ram_i),
                .mem_is_SerialDate_i            (mem_is_SerialDate_i),
                .mem_is_SerialStat_i            (mem_is_SerialStat_i),
                
                .base_ram_state                 (base_ram_state),
                .ext_ram_state                  (ext_ram_state),
                .Serial_state                   (Serial_state)
                );
      
  
  wire [31:0] wb_pc;
  wire wb_reg_wen;
  wire [4:0] wb_reg_waddr;
  wire [31:0] wb_reg_wdata;
  
    mem_wb  MEM_WB(
                .clk            (clk),
                .rst            (rst),
                
                .mem_pc         (mem_pc_o),                
                .mem_reg_wen    (mem_reg_we_o),
                .mem_reg_waddr  (mem_reg_waddr_o),
                .mem_reg_wdata  (mem_reg_wdata_o),
                
                .wb_pc          (wb_pc),
                .wb_reg_wen     (wb_reg_wen),
                .wb_reg_waddr   (wb_reg_waddr),
                .wb_reg_wdata   (wb_reg_wdata)
                );
    
    
    regfile REG_FILE(
                .clk        (clk),
                .rst        (rst),
                
                .we         (wb_reg_wen),
                .waddr      (wb_reg_waddr),
                .wdata      (wb_reg_wdata),
                
                .re1        (reg1_ren_o),
                .raddr1     (reg1_addr_o),
                .rdata1     (reg1_data_i),
                
                .re2        (reg2_ren_o),
                .raddr2     (reg2_addr_o),
                .rdata2     (reg2_data_i)
                );
    
    
    
    
    stall_ctrl STALL_CTRL(
                .rst                (rst),
                .stallreq_from_id   (stallreq_from_id),
                .stallreq_from_mem  (stallreq_from_mem),
                .stall              (stall)
                );


endmodule
