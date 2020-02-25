
`timescale 1ns/1ns 

module dds_cap_top_tb;
reg clk,rst,rxd;
wire txd ;
always #5 clk = ~clk ; 
initial begin 
{clk,rst,rxd} = 0 ;
rst = 1;
#100 rst = 0;  
end 

  dds_cap_top   dds_cap_top (
  .clk(clk), 
  .rst(rst),
  .txd(txd),
  .rxd(rxd)
);

   initial begin

      $dumpfile("dds_cap_top_tb.vcd");
      $dumpvars( 0 , dds_cap_top );
		#2000000;
     // for (k=0; k<8; k=k+1)
       // #10 $display("done testing case %d", k);

      $finish;

   end
   
   

endmodule 




module dds_cap_top#( parameter ClkFrequency = 100*1000*1000,// 100MHz
parameter aw = 14,
parameter Baud = 115200*8)(
input clk , rst,
output txd,
input rxd
);

// assign  txd =  rxd ;

reg [11:0] cnt ;always @(posedge clk)  cnt <=(rst)?0: cnt+4;

reg  [11:0]  i1,q1,i2,q2;

always @ (posedge clk ) i1 <= cnt     ;
always @ (posedge clk ) q1 <= cnt + 1 ;
always @ (posedge clk ) i2 <= cnt + 2 ;
always @ (posedge clk ) q2 <= cnt + 3 ; 

 dds_cap#( .ClkFrequency(ClkFrequency),// 100MHz
.aw (aw),
.Baud ( Baud))dds_cap_i (
.bb_clk(clk),
.rst(rst),
.i1(i1),
.q1(q1),
.i2(i2),
.q2(q2),
.if_clk(clk),
.txd(txd),
.rxd(rxd)
);

endmodule 

module dds_cap#( 
parameter ClkFrequency = 100*1000*1000,// 100MHz
parameter aw = 12,
parameter Baud = 115200)(
input bb_clk,rst,
input  [11:0]  i1,q1,i2,q2,
input if_clk,
output txd,
input rxd
);

wire [47:0] w48 ;
wire  [1:0] rd_level;

reg dc_rd = 0 ;      always @(posedge  if_clk)  if (rst)dc_rd<=0;else if (rd_level[1]==0) dc_rd <=1;
reg [3:0] dc_rd_r ;always @(posedge if_clk ) dc_rd_r[3:0] <= {dc_rd_r[2:0],dc_rd} ;
reg sc_fifo_wr ;always @(posedge if_clk )sc_fifo_wr <= dc_rd_r[3] ;
reg [47:0] sc_fifo_d48 ;always @(posedge if_clk )sc_fifo_d48 <= w48  ;


generic_fifo_dc_gray  #(.aw(3),.dw(48))generic_fifo_dc_gray (	
.rd_clk(  if_clk),  .wr_clk(bb_clk  ), .rst( ~rst ), .clr(1'b0), .din({i1,q1,i2,q2}), .we(~dc_full),
                                 .dout(w48 ), .re( dc_rd ), .full( dc_full ), .empty( ), .wr_level( ), .rd_level( rd_level ) );


wire [15:0] rx_end_cnt ;
wire rx_upload ,  rx_trig_en ,rx_start,rx_force_start,rx_do_rst;
wire [2:0]  rx_txmux ;

 rx2cmd  #(
.ClkFrequency (ClkFrequency),	 
.Baud(Baud)
)rx2cmd (
.clk( if_clk ),
.rxd( rxd ),
.rst( rst ),
.upload( rx_upload ),
.end_cnt( rx_end_cnt  ),
.trig_en( rx_trig_en ),
.start( rx_start ),
.force_start( rx_force_start ),
.do_rst( rx_do_rst ),
.txmux( rx_txmux  ) 
);

wire [15:0]  sc_fifo_cnt ;
wire sc_fifo_empty;
wire sc_fifo_full;

reg [7:0] rd_st; 

always @(posedge if_clk)if (rst)rd_st<=0;else 
case (rd_st)
0:if (dc_rd) rd_st<=1;
1:if (rx_trig_en==0) rd_st<=2;
2:if (rx_trig_en==1) rd_st<=3;
3: if (sc_fifo_wr)  rd_st<=10 ;
10:if (sc_fifo_full || sc_fifo_cnt >= rx_end_cnt)rd_st<=11;// write state 
11:rd_st<=1;
default rd_st <=0;
endcase 
wire do_wr_sc_fifo  = rd_st == 10 ;

wire [47:0]sc_fifo_q48 ;
wire rd_sc_fifo ;

 sc_fifo#(.AW(aw),.DW(48))sc_fifo(
.clk( if_clk ),
.rst( rst ),
.din( sc_fifo_d48 ),
.wr( do_wr_sc_fifo  ),
.full(sc_fifo_full ),
.dout(sc_fifo_q48 ),
.rd( rd_sc_fifo),
.empty( sc_fifo_empty),
.fwft_dout( ),
.fifo_cntr(sc_fifo_cnt  ) 
);

fifo2tx  #(
.ClkFrequency (ClkFrequency),	 
.Baud(Baud)
)fifo2tx(
.clk (if_clk),  
.rst(rst) ,
.fifo_in( sc_fifo_q48),
.fifo_emp(sc_fifo_empty),
.rd_fifo(rd_sc_fifo),
.tx(txd) 
); 


endmodule 


