

module rx2cmd_ #(
parameter ClkFrequency = 25000000,	// 25MHz
parameter Baud = 115200
)(
input clk,rxd,rst,
output reg  upload,
output reg [15:0] end_cnt,
output reg  trig_en,start,force_start,do_rst,
output reg [2:0] txmux
);


parameter HI_BIT =  12  ;

reg [HI_BIT:0]d  = 0 ;

always@(posedge clk)if (rst) d<=0;else if (d[HI_BIT]==0)d<=d+1;
always@(posedge clk)trig_en <=  d[HI_BIT] ;
always@(posedge clk){start,force_start,do_rst} <=0  ;
always@(posedge clk)end_cnt <=  1024 ; 


endmodule 


/*
 rx2cmd  rx2cmd (
.clk(  ),
.rxd(  ),
.rst(  ),
.upload(  ),
.end_cnt(  ),
.trig_en(  ),
.start(  ),
.force_start(  ),
.do_rst(  ),
.txmux(  ) 
);
*/

module rx2cmd #(
parameter ClkFrequency = 25000000,	// 25MHz
parameter Baud = 115200
)(
input clk,rxd,rst,
output reg  upload,
output reg [15:0] end_cnt,
output reg  trig_en,start,force_start,do_rst,
output reg [2:0] txmux
);

wire [7:0]  u8 ;
wire rx_valid ;
////////////////////////////////////////////////////////

async_receiver #(  .ClkFrequency (ClkFrequency ),   .Baud  (Baud)) async_receiver(
	 .clk( clk ) ,
	 .RxD( rxd  ) ,
     .RxD_data_ready( rx_valid ) ,
	 .RxD_data(u8  ) ,  
	 .RxD_idle(  ) , 
	 .RxD_endofpacket(  )
);




		

reg [7:0]  u8r , st , sum ;
reg [15:0]end_cnt_s  ;
reg [31:0] cmd;
reg [23:0] pad;
always @ (posedge clk)   if (rx_valid)u8r<= u8 ;

always @ (posedge clk)   if (rst)st <= 0 ;
else case (st)
0 : st<=1;
1 : st<=2;
2: if (rx_valid )  st<=( u8 == 'haa)?3:1; 
3: if (rx_valid )  st<=( u8 == 'h55)?4:1; 
4: if (rx_valid )  st<=5;  // end_cnt_s [7:0]
5: if (rx_valid )  st<=6;  // end_cnt_s [15:8]

6: if (rx_valid )  st<=7;    // cmd[7:0]
7: if (rx_valid )  st<=8;    // cmd[15:8]
8: if (rx_valid )  st<=9;    // cmd[23:16]
9: if (rx_valid )  st<=10;   // cmd[31:24]

10: if (rx_valid )  st<=11;        //pad[7:0] 
11: if (rx_valid )  st<=12;        // pad[15:8] 
12: if (rx_valid )  st<=13;        // pad[23:16] 
13: if (rx_valid )  st<=20;        //check_sum 

20:st<=21;
21: if (u8r == sum ) st<=22;else st<=23;
22: st<=1; // set upload 
23: st<=1; // 
default st<=0;
endcase

always @ ( posedge clk ) if(st==4) end_cnt_s[7:0]  <= u8;
always @ ( posedge clk ) if(st==5) end_cnt_s[8+7:8+0]  <= u8;

always@(posedge clk)  if (st==6)   cmd[7:0] <= u8 ; 
always@(posedge clk)  if (st==7)   cmd[15:8] <= u8 ; 
always@(posedge clk)  if (st==8)   cmd[23:16] <= u8 ; 
always@(posedge clk)  if (st==9)   cmd[31:24] <= u8 ; 

always@(posedge clk)  if (st==10)  pad[7:0]  <= u8 ; 
always@(posedge clk)  if (st==11)  pad[15:8]  <= u8 ; 
always@(posedge clk)  if (st==12)  pad[23:16] <= u8 ; 

always @ ( posedge clk ) upload <= (st==22) ;
always @ ( posedge clk ) sum <= end_cnt_s[7:0] + end_cnt_s[15:8] +  cmd[7:0] + cmd[15:8] + pad[7:0] + pad[15:8] + pad[23:16]   ; 
always @ ( posedge clk ) if (upload) end_cnt <= end_cnt_s ;
always @ ( posedge clk ) if (upload)  txmux <= cmd[5:4]; 
always @ ( posedge clk ) if (upload)  do_rst <= cmd[3];
always @ ( posedge clk ) if (upload)  start <= cmd[2];
always @ ( posedge clk ) if (upload)  force_start <= cmd[1];
always @ ( posedge clk ) if (upload)  trig_en <= cmd[0];
 
   ILA ILA_i(
	    .clk(clk),
        .probe0(end_cnt),
        .probe1(upload),
        .probe2(trig_en) 
		);
	 
		
		
		
endmodule 
  
  
