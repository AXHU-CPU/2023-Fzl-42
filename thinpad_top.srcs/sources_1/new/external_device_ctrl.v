`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: external_device_ctrl.v
//-- DESCRIPTION  : 本模块为 外部存储器数据选择 模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module external_device_ctrl(
    input   wire    rst,
        
    input   wire    [3:0]   base_ram_state,
    input   wire    [2:0]   ext_ram_state,
    input   wire    [3:0]   Serial_state,
    
    
    input   wire    [3:0]   ram_sel_i,
    input   wire    [31:0]  serial_i,
    input   wire    [31:0]  base_ram_i,
    input   wire    [31:0]  ext_ram_i,
    output  wire    [31:0]  ram_data_o
    );
 
 assign ram_data_o = rst ? 32'h0000_0000 : 
                     Serial_state[3] ? serial_i :
                     Serial_state[1] ? serial_i :
                     base_ram_state[2] ? 
                        ((ram_sel_i == 4'b1110) ? {{24{base_ram_i[7]}},   base_ram_i[7:0]}   :
                         (ram_sel_i == 4'b1101) ? {{24{base_ram_i[15]}},  base_ram_i[15:8]}  :
                         (ram_sel_i == 4'b1011) ? {{24{base_ram_i[23]}},  base_ram_i[23:16]} :
                         (ram_sel_i == 4'b0111) ? {{24{base_ram_i[31]}},  base_ram_i[31:24]} : base_ram_i) : 
                     ext_ram_state[1] ? 
                        ((ram_sel_i == 4'b1110) ? {{24{ext_ram_i[7]}},   ext_ram_i[7:0]}   :
                         (ram_sel_i == 4'b1101) ? {{24{ext_ram_i[15]}},  ext_ram_i[15:8]}  :
                         (ram_sel_i == 4'b1011) ? {{24{ext_ram_i[23]}},  ext_ram_i[23:16]} :
                         (ram_sel_i == 4'b0111) ? {{24{ext_ram_i[31]}},  ext_ram_i[31:24]} : ext_ram_i) :
                     32'h0000_0000;
                     
 /* 
   /// 确认传给CPU  MEM阶段 的数据
 always @ (*) 
   begin
     if(rst)
       ram_data_o = 32'h0000_0000;
     else if(Serial_state[3])         // is_SerialStat 状态
       ram_data_o = serial_i;
     else if(Serial_state[1])         // is_SerialDate 接收数据 状态
       ram_data_o = serial_i;
     else if (base_ram_state[2])                       // baseram数据
       case (ram_sel_i)
           4'b1110: ram_data_o = {{24{base_ram_i[7]}},  base_ram_i[7:0]};
           4'b1101: ram_data_o = {{24{base_ram_i[15]}}, base_ram_i[15:8]};
           4'b1011: ram_data_o = {{24{base_ram_i[23]}}, base_ram_i[23:16]};
           4'b0111: ram_data_o = {{24{base_ram_i[31]}}, base_ram_i[31:24]};
           default: ram_data_o = base_ram_i;
       endcase
     else if (ext_ram_state[1])                        // extram数据
       case (ram_sel_i)
           4'b1110: ram_data_o = {{24{ext_ram_i[7]}},  ext_ram_i[7:0]};
           4'b1101: ram_data_o = {{24{ext_ram_i[15]}}, ext_ram_i[15:8]};
           4'b1011: ram_data_o = {{24{ext_ram_i[23]}}, ext_ram_i[23:16]};
           4'b0111: ram_data_o = {{24{ext_ram_i[31]}}, ext_ram_i[31:24]};
           default: ram_data_o = ext_ram_i;
       endcase
     else
       ram_data_o = 32'h0000_0000;
 end
  */
  
  
endmodule
