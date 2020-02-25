
////////////////////////////////////////////////////////
// RS-232 example
// Compiles with Microsoft Visual C++ 5.0/6.0
// (c) fpga4fun.com KNJN LLC - 2003, 2004, 2005, 2006

#include<windows.h>
#include<stdio.h>
#include<conio.h>
#include<time.h>

////////////////////////////////////////////////////////
HANDLE hCom ;
void OpenCom(int com_no)
{
    DCB dcb ;
    COMMTIMEOUTS ct ;
    static char cmd_name[20];
    sprintf(cmd_name,"COMD%d:",com_no);
    hCom=CreateFile("COM9:",GENERIC_READ|GENERIC_WRITE,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
    if(hCom==INVALID_HANDLE_VALUE)exit(1);
    if(!SetupComm(hCom,4096,4096))exit(1);
    
    if(!GetCommState(hCom,&dcb))exit(1);
    dcb.BaudRate=115200*8 ;
    ((DWORD*)(&dcb))[2]=0x1001 ;
    // set port properties for TXDI + no flow-control
    dcb.ByteSize=8 ;
    dcb.Parity=NOPARITY ;
    dcb.StopBits=2 ;
    if(!SetCommState(hCom,&dcb))exit(1);
    
    // set the timeouts to 0
    ct.ReadIntervalTimeout=MAXDWORD ;
    ct.ReadTotalTimeoutMultiplier=0 ;
    ct.ReadTotalTimeoutConstant=0 ;
    ct.WriteTotalTimeoutMultiplier=0 ;
    ct.WriteTotalTimeoutConstant=0 ;
    if(!SetCommTimeouts(hCom,&ct))exit(1);
}
void OpenCom_()
{
    DCB dcb ;
    COMMTIMEOUTS ct ;
    
    hCom=CreateFile("COM9:",GENERIC_READ|GENERIC_WRITE,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
    if(hCom==INVALID_HANDLE_VALUE)exit(1);
    if(!SetupComm(hCom,4096,4096))exit(1);
    
    if(!GetCommState(hCom,&dcb))exit(1);
    dcb.BaudRate=115200 ;
    ((DWORD*)(&dcb))[2]=0x1001 ;
    // set port properties for TXDI + no flow-control
    dcb.ByteSize=8 ;
    
    dcb.StopBits=2 ;
    dcb.Parity=1 ;
    //
    /*
    	https://www.open-open.com/doc/9c5616108bb94c24af88faf5a15f876c.html
    	DWORD BaudRate：串口波特率
    
    DWORD fParity：为1的话激活奇偶校验检查
    
    DWORD Parity：校验方式，值0~4分别对应无校验:0、奇校验:1、偶校验:2、校验置位:3、校验清零:4
    
    
    DWORD ByteSize：一个字节的数据位个数，范围是5~8
    
    DWORD StopBits：停止位个数，0~2分别对应1位、1.5位、2位停止位
    */
    
    
    if(!SetCommState(hCom,&dcb))exit(1);
    
    // set the timeouts to 0
    ct.ReadIntervalTimeout=MAXDWORD ;
    ct.ReadTotalTimeoutMultiplier=0 ;
    ct.ReadTotalTimeoutConstant=0 ;
    ct.WriteTotalTimeoutMultiplier=0 ;
    ct.WriteTotalTimeoutConstant=0 ;
    if(!SetCommTimeouts(hCom,&ct))exit(1);
}

void CloseCom()
{
    CloseHandle(hCom);
}

DWORD WriteCom(char*buf,int len)
{
    DWORD nSend ;
    if(!WriteFile(hCom,buf,len,&nSend,NULL))exit(1);
    
    return nSend ;
}

void WriteComChar(char b)
{
    WriteCom(&b,1);
}

int ReadCom(char*buf,int len)
{
    DWORD nRec ;
    if(!ReadFile(hCom,buf,len,&nRec,NULL))exit(1);
    return(int)nRec ;
}

#define ERR_DRIVER 1 
#define ERR_TIMEOUT 2 
#define ERR_PACK_SUM 3 

char ReadComChar(int ms,int*err)
{
    int now_clk,end_clk ;
    DWORD nRec ;
    char c ;
    *err=0 ;
    end_clk=clock()+ms ;
    while(1)
    {
        now_clk=clock();
        if(now_clk>=end_clk)
        {
            *err=ERR_TIMEOUT ;
            break ;
        }
        if(!ReadFile(hCom,&c,1,&nRec,NULL))
        {
            *err=ERR_DRIVER ;
            exit(1);
        }
        if(nRec)break ;
    }
    return c ;
}


void invalid_incoming_char(int ms)
{
    unsigned char c ;
    int err ;
    int i=0 ;
    while(1)
    {
        c=ReadComChar(ms,&err);
        if(err==ERR_TIMEOUT)return ;
        // printf("0x%02x ",c);++i;if (i==6) {i=0;printf("\n");}
    }
}



void get_iq(int ms,int*err,unsigned short*i1,unsigned short*q1,unsigned short*i2,unsigned short*q2)
{
    unsigned char c[10],sum=0 ;
    unsigned short t[10];
    int i=0 ;
    /*
    
    r48 = din({i1,q1,i2,q2})
     11:r8<=r48[ 07 : 00 ];
     16:r8<=r48[ 15 : 08 ];
     21:r8<=r48[ 23 : 16 ];
     26:r8<=r48[ 31 : 24 ];
     31:r8<=r48[ 39 : 32 ];
     36:r8<=r48[ 47 : 40 ]; // r48
     41:r8<= 0 ; //padding now
     46:r8<= sum ; // check sum
     */
    
    // while(1)
    {
        c[0]=ReadComChar(ms,err);
        if(*err!=0)return ;
        c[1]=ReadComChar(ms,err);
        if(*err!=0)return ;
        c[2]=ReadComChar(ms,err);
        if(*err!=0)return ;
        c[3]=ReadComChar(ms,err);
        if(*err!=0)return ;
        c[4]=ReadComChar(ms,err);
        if(*err!=0)return ;
        c[5]=ReadComChar(ms,err);
        if(*err!=0)return ;
        c[6]=ReadComChar(ms,err);
        if(*err!=0)return ;
        c[7]=ReadComChar(ms,err);
        if(*err!=0)return ;
        // retuen with error
        
        for(sum=0,i=0;i<=6;++i)sum+=c[i];
        if(c[7]!=sum)
        {
            *err=ERR_PACK_SUM ;
            printf("X");
            return ;
        }
        
        //      for(i=0;i<6;++i) printf("%02x ",c[i]);
        
        //          printf("V");
        //     printf("\n");
        
        
        
        for(i=0;i<10;++i)t[i]=c[i];
        t[4]&=0xf ;
        t[4]<<=8 ;
        t[4]|=t[5];
        if(q2)*q2=t[4];
        //          printf("q2 = %03x\n",*q2);
        for(i=0;i<10;++i)t[i]=c[i];
        t[4]>>=4 ;
        t[3]<<=4 ;
        t[3]|=t[4];
        if(i2)*i2=t[3];
        //          printf("i2 = %03x\n",*i2);
        
        for(i=0;i<10;++i)t[i]=c[i];
        t[4-3]&=0xf ;
        t[4-3]<<=8 ;
        t[4-3]|=t[5-3];
        if(q1)*q1=t[4-3];
        //      printf("q1 = %03x\n",*q1);
        for(i=0;i<10;++i)t[i]=c[i];
        t[4-3]>>=4 ;
        t[3-3]<<=4 ;
        t[3-3]|=t[4-3];
        if(i1)*i1=t[3-3];
        //     printf("i1 = %03x\n",*i1);
        
        
        
        
        
        ///if (err==ERR_TIMEOUT)return ; // this package error
        // printf("0x%02x ",c);++i;if (i==6) {i=0;printf("\n");}
        
        
        
    }
}




int ReadComChar2(char*c)
{
    int nRec ;
    if(!ReadFile(hCom,c,1,&nRec,NULL))exit(1);
    return nRec ;
}
/*
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


always @ ( posedge clk ) if (upload)  txmux = cmd[5:4];
always @ ( posedge clk ) if (upload)  do_rst = cmd[3];
always @ ( posedge clk ) if (upload)  start = cmd[2];
always @ ( posedge clk ) if (upload)  force_start = cmd[1];
always @ ( posedge clk ) if (upload)  trig_en = cmd[0];



*/
void send_cmd(unsigned short end_cnt,int trig_en)
{
    int i=0 ;
    static unsigned char str[32];
    unsigned char sum=0 ;
    str[0]=0xaa ;
    str[1]=0x55 ;
    str[2]=end_cnt&0xff ;
    end_cnt>>=8 ;
    str[3]=end_cnt&0xff ;
    
    str[4]=(trig_en!=0)?1:0 ;
    // cmd[7:0]
    str[5]=0 ;
    // cmd[15:8]
    str[6]=0 ;
    // cmd[23:16]
    str[7]=0 ;
    // cmd[31:24]
    
    
    str[8]=0 ;
    //pad[7:0]
    str[9]=0 ;
    // pad[15:8]
    str[10]=0 ;
    // pad[23:16]
    
    for(i=2;i<=10;++i)sum+=str[i];
    
    str[11]=sum ;
    // sum
    
    WriteCom(str,12);
}

void send_cmd_start(unsigned short end_cnt)
{
    send_cmd(end_cnt,0);
    send_cmd(end_cnt,1);
}

char*u12tostr(char*s,unsigned short v,char*id)
{
    // static char s[30] ;
    int i=12 ;
    s[0]='b' ;
    s[1]=0 ;
    while(i--)
    {
        if(v&(1<<i))strcat(s,"1");
        else strcat(s,"0");
    }
    strcat(s,id);
    return s ;
}

////////////////////////////////////////////////////////
void main()
{
    char c,s[256];
    int len ;
    int idx=0 ;
    unsigned short i1,q1,i2,q2 ;
    char i1s[30],q1s[30],i2s[30],q2s[30];
    int err ;
    OpenCom(9);
    invalid_incoming_char(1000);
    
    
    
    puts("$comment Created in LIWEI_IQ $end");
    puts("$date 2020-1-1 17:12:28 $end");
    puts("$timescale 10 ns $end");
    puts("$scope module BB_WAVE $end");
    puts("$var real 1 * sample $end");
    puts("$var reg 12 A I1[11:0] $end");
    puts("$var reg 12 B Q1[11:0] $end");
    puts("$var reg 12 C I2[11:0] $end");
    puts("$var reg 12 D Q2[11:0] $end");
    puts("$upscope $end");
    puts("$enddefinitions $end");
    
    send_cmd_start(1024*1024);
    // get this all samples in fifo
    idx=0 ;
    
    
    do 
    {
        err=0 ;
        get_iq(5000,&err,&i1,&q1,&i2,&q2);
        if(err!=0)break ;
        u12tostr(i1s,i1," A");
        u12tostr(i2s,i2," B");
        u12tostr(q1s,q1," C");
        u12tostr(q2s,q2," D");
        
        printf("#%d \nr%d * \n",idx,idx);
        idx++;
        puts(i1s);
        puts(q1s);
        puts(i2s);
        puts(q2s);
        
    }
    while(1);
    
    
    if(idx)
    {
        printf("#%d \nr%d * \n",idx,idx);
        idx++;
        puts(i1s);
        puts(q1s);
        puts(i2s);
        puts(q2s);
        
    }
    
    CloseCom();
    
    printf("Press a key to exit");
    
    
    
    
}