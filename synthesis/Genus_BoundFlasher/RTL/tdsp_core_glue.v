module tdsp_core_glue( 
    addrs_in,
    data_in,
    p_addrs_in,
    p_data_in,
    port_addrs_in,
    port_data_in,
    ar, 
    res_adr, 
    res_port_adr, 
    se_shift_mdr, 
    ze_mdr, 
    alu_out, 
    go_prog,
    read_prog, 
    go_data, 
    read_data, 
    go_port, 
    read_port,
    pc_acc,
    arp, 
    ar1, 
    ar0,
    dp,
    ir,
    pdr,
    opa,
    opb,
    mdr,
    acc,
    pc,
    data_out,
    p_data_out,
    port_data_out,
    top,
    p,
    alu_cmd,
    sel_op_a,
    sel_op_b,
    dec_go_prog,
    enc_go_prog,
    dec_read_prog,
    enc_read_prog,
    dec_go_data,
    enc_go_data,
    dec_read_data,
    enc_read_data,
    dec_go_port,
    enc_go_port,
    dec_read_port,
    enc_read_port,
    dmov_inc
);


`include "tdsp.h"

output [`ADDR:0]   addrs_in;       // Data bus address input
output [`MSB:0]    data_in;        // Data bus input
output [`P_ADDR:0] p_addrs_in;     // Program bus address input
output [`MSB:0]    p_data_in;      // Program bus input
output [`PORT:0]   port_addrs_in;  // Port bus address input
output [`MSB:0]    port_data_in;   // Port bus input
output [`MSB:0]    alu_out;        // Output from ALU function
output [`MSB:0]    ar;             // Selected Auxiliary Register
output [`ADDR:0]   res_adr;        // Resolved data address
output [`ADDR:0]   res_port_adr;   // Resolved port address
output [`HMSB:0]   se_shift_mdr;   // Sign extended; shifted data
output [`HMSB:0]   ze_mdr;         // Zero paded mdr
output [`MSB:0]    mdr;            // Memory Data Register
output [`MSB:0]    pdr;            // Port Data Register
output [`HMSB:0]   opa,            // alu, multiply operand a
                   opb;            // alu, multiply operand b
output go_prog; 
output read_prog; 
output go_data; 
output read_data; 
output go_port; 
output read_port;

input [`ACC:0]    acc;            // Accumulator
input [`MSB:0]    ir;             // Current Execute Instruction register
input [`MSB:0]    pc;             // Program counter
input [`MSB:0]    ar0;            // Auxiliary Register 0
input [`MSB:0]    ar1;            // Auxiliary Register 1
input [`MSB:0]    data_out;       // Data data holding register
input [`MSB:0]    p_data_out;     // Program data holding register
input [`MSB:0]    port_data_out;  // Port data holding register
input [`MSB:0]    top;            // Multiply temporary operand
input [`HMSB:0]   p;              // Multiply product Register
input [`ALUCMD:0] alu_cmd;        // Accumulator Command opcode
input [`OPACMD:0] sel_op_a;       // Accumulator Command opcode
input [`OPBCMD:0] sel_op_b;       // Accumulator Command opcode
input pc_acc;                     // Accumulator
input arp;                        // Auxiliary Register Pointer
input dp;
input dec_go_prog;
input enc_go_prog;
input dec_read_prog;
input enc_read_prog;
input dec_go_data;
input enc_go_data;
input dec_read_data;
input enc_read_data;
input dec_go_port;
input enc_go_port;
input dec_read_port;
input enc_read_port;
input dmov_inc;

reg [`MSB:0]    data_in;        // Data bus input
reg [`HMSB:0]   opa,            // alu, multiply operand a
                opb;            // alu, multiply operand b

wire[`HMSB:0]   shift_acc;      // Shifted accumulator

assign #1 ar = arp ? ar1 : ar0 ;
assign #1 res_adr = ir[7] ? ar : {dp, ir[`S_IADDR]} ;
assign #1 res_port_adr = {`E_PORTA,ir[`OP_PORTA]} ;
assign #1 se_shift_mdr = {{16{mdr[`MSB]}}, mdr} << ir[`OP_SHIFT] ;
assign #1 shift_acc = acc[`HMSB:0] << ir[`OP_ACC_SHFT] ;
assign #1 ze_mdr = {16'h0000, mdr} ;
assign #1 alu_out = (ir[`S_OP] == `SACL) ? acc[`ACCL] : shift_acc[`ACCH] ;
assign #1 go_prog = dec_go_prog | enc_go_prog ;
assign #1 read_prog = dec_read_prog | enc_read_prog ;
assign #1 go_data = dec_go_data | enc_go_data ;
assign #1 read_data = dec_read_data | enc_read_data ;
assign #1 go_port = dec_go_port | enc_go_port ;
assign #1 read_port = dec_read_port | enc_read_port ;

assign #1 p_addrs_in = pc_acc ? acc[`P_ADDR_S] : pc ;
assign #1 p_data_in = data_out ;

assign #1 port_addrs_in = res_port_adr;
assign #1 port_data_in = data_out;
assign #1 pdr = port_data_out;
assign #1 mdr = data_out;

assign #1 addrs_in = (dmov_inc) ? (res_adr + 1) : res_adr ;
 
wire  #1 inst_tbl = ((ir[`S_OP] == `TBLW) || (ir[`S_OP] == `TBLR)) ;
wire  #1 inst_in = (ir[`S_HI_NIB] == `IN_n) ;
wire  #1 inst_sar0 = (ir[`S_OP] == `SAR0) ;
wire  #1 inst_sar1 = (ir[`S_OP] == `SAR1) ;
 
always @( dmov_inc or inst_tbl or inst_in or inst_sar0 or inst_sar1 or
          data_out or p_data_out or port_data_out or alu_out or
          ar0 or ar1 )
begin
    casex ({dmov_inc, inst_tbl, inst_in, inst_sar0, inst_sar1})
    5'b1???? : data_in <= data_out ;
    5'b?1??? : data_in <= p_data_out ;
    5'b??1?? : data_in <= port_data_out ;
    5'b???1? : data_in <= ar0 ;
    5'b????1 : data_in <= ar1 ;
    default  : data_in <= alu_out ;
    endcase
end


always @(sel_op_a or mdr or acc or top or ir)
begin
    case(sel_op_a)
    `OP_A_MDR: begin
        opa <= {{16{mdr[`MSB]}}, mdr} ;
        end
    `OP_A_ACC: begin
        opa <= acc ;
        end
    `OP_A_TOP: begin
        opa <= top ;
        end
    `OP_A_IR: begin
        opa <= ir[`S_IDATA] ;
        end
    default: begin
        opa <= {{16{mdr[`MSB]}}, mdr} ;
        end
    endcase
end

always @(sel_op_b or se_shift_mdr or mdr or ze_mdr or p or ir)
begin
    case(sel_op_b)
    `OP_B_SE: begin
        opb <= se_shift_mdr ;
        end
    `OP_B_MDRH: begin
        opb <= {mdr, {16{1'b0}}} ;
        end
    `OP_B_MDRL: begin
        opb <= {{16{1'b0}}, mdr} ;
        end
    `OP_B_MDR: begin
        opb <= mdr ;
        end
    `OP_B_ZE: begin
        opb <= ze_mdr ;
        end
    `OP_B_P: begin
        opb <= p ;
        end
    `OP_B_EIR: begin
        opb <= {{3{ir[`MSB_MPY_K]}}, ir[`S_MPY_K]} ;
        end
    default: begin
        opb <= se_shift_mdr ;
        end
    endcase
end

endmodule
