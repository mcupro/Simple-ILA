


module fifo2tx #(
parameter ClkFrequency = 25000000,	// 25MHz
parameter Baud = 115200
)(
input clk ,  rst ,
input [47:0]fifo_in,
input fifo_emp,
output reg rd_fifo,
output  tx 
);

reg [7:0]st ; 

always @(posedge clk) rd_fifo <= st==2 ;  

reg [48-1:0]r48;
always @(posedge clk) if (st==3)r48 <=  fifo_in  ;  

reg [7:0]r8 ;
always @(posedge clk) if (rst) st<=0;else 
case (st)
0:st<=1;
1:if ( ~fifo_emp & ~tx_busy )st<=2;
2:st<=3;//  rd_fifo 
3:st<=4; // save data   
4:st<=10;

 10: if( ~tx_busy ) st<= 11 ; 11:st<= 12; 12:st<= 13; 13:st<= 14; 14:st<= 15; //   11:r8<=r48[ 07 : 00 ];
 15: if( ~tx_busy ) st<= 16 ; 16:st<= 17; 17:st<= 18; 18:st<= 19; 19:st<= 20;// 16:r8<=r48[ 15 : 08 ];
 20: if( ~tx_busy ) st<= 21 ; 21:st<= 22; 22:st<= 23; 23:st<= 24; 24:st<= 25;// 21:r8<=r48[ 23 : 16 ];
 25: if( ~tx_busy ) st<= 26 ; 26:st<= 27; 27:st<= 28; 28:st<= 29; 29:st<= 30;// 26:r8<=r48[ 31 : 24 ];
 30: if( ~tx_busy ) st<= 31 ; 31:st<= 32; 32:st<= 33; 33:st<= 34; 34:st<= 35;// 31:r8<=r48[ 39 : 32 ];
 35: if( ~tx_busy ) st<= 36 ; 36:st<= 37; 37:st<= 38; 38:st<= 39; 39:st<= 40;// 36:r8<=r48[ 47 : 40 ]; 
 40: if( ~tx_busy ) st<= 41 ; 41:st<= 42; 42:st<= 43; 43:st<= 44; 44:st<= 45;// other data 
 45: if( ~tx_busy ) st<= 46 ; 46:st<= 47; 47:st<= 48; 48:st<= 49; 49:st<= 50;// check sum 

 
 50: st<=1 ; 
 default st<=0;
endcase 
 


reg [7:0]  sum ;
always @ (posedge clk) 
sum <= r48[ 07 : 00 ] + r48[ 15 : 08 ]+r48[ 23 : 16 ]+r48[ 31 : 24 ]+r48[ 39 : 32 ]+r48[ 47 : 40 ]+ 0 ;


always @ (posedge clk)
case (st)
 /*
 11:r8<=r48[ 07 : 00 ];
 16:r8<=r48[ 15 : 08 ];
 21:r8<=r48[ 23 : 16 ];
 26:r8<=r48[ 31 : 24 ];
 31:r8<=r48[ 39 : 32 ];
 36:r8<=r48[ 47 : 40 ]; // r48 
 */
 
 36:r8<=r48[ 07 : 00 ];
 31:r8<=r48[ 15 : 08 ];
 26:r8<=r48[ 23 : 16 ];
 21:r8<=r48[ 31 : 24 ];
 16:r8<=r48[ 39 : 32 ];
 11:r8<=r48[ 47 : 40 ]; // r48 
 
 
 41:r8<= 0 ; //padding now 
 46:r8<= sum ; // check sum 
endcase 

reg tx_start ;
always @ (posedge clk)case (st)
 11,16,21,26,31,36,41,46:tx_start<= 1'b1 ; // check sum 
 default tx_start<=0;
endcase 
  
async_transmitter #(.ClkFrequency(ClkFrequency ),.Baud( Baud) )async_transmitter(
	.clk(clk ),
	.TxD_start(  tx_start),
	.TxD_data( r8 ),
	.TxD(tx ),
	.TxD_busy( tx_busy )
);

endmodule 


 