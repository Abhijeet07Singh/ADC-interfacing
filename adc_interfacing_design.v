*/INTERFACING ONBOARD ADC WITH SPARTAN3E
--------------------------------------------------------------------
1.Here 1st amp_cs=1 and then amp_cs=0 for gain setting 
2.after gain setting is done amp_cs-1.There is no required to set the gain
 again.
3.Next make adc_conv=1, which starts conversion process of analog data for 
both the channel.
4.next adc_conv=0;After 34 clock cycles starting from adc conv=1, the
conversion process is over and digital data is
available for both the channel only after next adc conv=1..
5. Repeat the above process

--------------------------------------------------------------------/*
module adc

(clk,clkout,spi_sck,enable,amp_cs,adc_conv,spi_miso,spi_mosi,amp_shdn,spi_ss_
b, 
sf_ceo,fpga_init_b,dac_cs,adc_data1,adc_data2,adc_data,a1,a2);

input clk, enable;
input spi_miso; // ADC OUPUT AND INPUT TO MASTER
output clkout;
output a1,a2;
output reg spi_sck; // SPI CLOCK
output reg amp_cs; // AMPLIFIER SELECT 
output reg adc_conv; // ADC CONVERSION CONTROLLER SIGNAL
output reg spi_mosi;
output reg amp_shdn; // AMPLIFIER SHUTDOWN 
output spi_ss_b,sf_ceo,fpga_init_b,dac_cs; // DISABLING SIGNAL

reg adc_sent=0;

reg [2:0]cnt=0;
reg [3:0]clk_10_count=0;
reg [6:0]adc_clk_count=0; // FOR 34 CLOCK PULSE
reg [5:0]adc_bit_count=17; // COUNT FOR 16 CLOCK PULSE
reg [3:0]gain_count=8; // GAIN COUNT OF 8 BIT
reg [4:0]pos_count,neg_count;

output reg [13:0]adc_data1; // ADC OUTPUT1
output reg [13:0]adc_data2; // ADC OUTPUT2

output [15:0]adc_data;

reg [7:0]data_gain=8'b00010001; // GAIN SETTING=-1//INITIALIZATION OF
AMPLIFIER GAIN

reg [5:0]state=6'b000000;

// DISBALING OTHER PERIPHERAL COMMUNICATING WITH SPI BUS

assign spi_ss_b=0; //SPI Serial Flash
assign sf_ce0=1;  // StrataFlash Parallel Flash PROM
assign fpga_init_b=1; //Platform Flash PROM
assign dac_cs=1; //DAC 

// CLOCK DIVISION BY 25 // clk=50mhz

always @(posedge clk or posedge enable)

begin
 if (enable)
begin
 pos_count <0;
end
 else
begin
if (pos_count =24) pos_count <= 0;
 else pos_count<= pos_count +1;
end
end

always @(negedge clk or posedge enable)
begin
 if (enable)
begin
 neg_count <=0;
end

 else
begin
 if (neg_count ==24) neg_count <= 0;
 else neg_count <= neg_count +1;
end
 end

assign clkout = ((pos_count > (25>>1)) | (neg_count > (25>>1)));
assign al=amp_cs;
assign a2=adc_conv;

//assign clk2-spi_sch;
//he sampled analog value is converted to digital data 32 SPI_SCK cycles
after asserting AD_CONV

assign adc_data=(2'b00, adc_data1); // 16bit

always@(posedge clkout or posedge enable)
begin
if(enable)

begin
spi_sck<=0;
amp_shdn=0; I
adc_conv<=0;
amp_cs<=1;
spi_mosi<=0;
//adc_data1<=14'b10110010000111;
state<=1;
end
else
begin 

case(state)   // STATES OF ADC

1:begin
state<=2;
end 
2:begin
spi_sck<=0;
amp_cs<=0; 
state<=3;
end

3:begin
  spi_sck<=0;
    state<=4;
end


4:begin  // GAIN SETTING

spi_sck<=0; 
amp_shdn<=0;
amp_cs<=0;
spi_mosi<=data_gain[gain_count-1];
gain_count<=gain_count-1;
state<=5;//////////////////
end

5:begin

amp_cs<=0;
spi_sck<=1;
if(gain_count>0)|
begin
state<=6;
end

else
begin
spi_sck<=1;
amp_shdn<=0;
amp_cs<=0;
gain_count<=8;
state<=7;
end
end

6:begin 
spi_sck<=1;
state<=3;
end

7:begin
amp_cs<=0;
spi_sck<=1;
state <=8;
end 


8:begin
spi_sck<=0;
state<=9; 
end

9:begin
spi_sck<=0;
state<=10;
end

10:begin
if(cnt>5) // DELAY ente-entri,
begin
spi_sck<=0; 
state<=11;
cnt<=0;
end
else
cnt<=cnt+1;
spi_sckc=0;
begin
end
end

11:begin
amp_cs<=1; // DISABLING GAIN SETTING AFTER GAIN SETTING 
spi_sck<=0;
state<=12;
end

12:begin
spi_sck<=0;
state<=13;
end

13:begin
spi_sck<=1;
state<=14;
end

14:begin
spi_sck<=1;
state<=15;
end

15:begin
spi_sck<=0;
state<=30;
end
30:begin
spi_sck<=0;
state<=16;
end

16:begin
adc_conv<=1; //START ADCs from here
spi_sck<=0;
state<=17;
end

17:begin
spi_sck=0;
state<=18;
end

18:begin
adc_conv<=0;
spi_sck<=0;
state<=19;
end

19:begin
if(cnt>3) // DELAY
begin
spi_sck<=0; 
cnt<=0;
state<=20;///////////////////////////////
end
else
begin
cnt<=cnt+1;
state<=19;
end end
20:begin 
spi_sck<=0; 
state<=21;

end


//adc_start 
21:begin

spi_sck<=0; 
adc_conv<=0;
adc_clk_count<-adc_clk_count+1;
adc_bit_counte-adc_bit_count-1;
state<-22;
end

22:begin
 spi_sck<=1;
 state<=23;
end

//aac_result
23:begin

spi_sche<=1;

if(adc_clk_count==34)
begin
adc_sent<=1;
//spi_sche=0; 
state<=24;
end

else if(adc_clk_count <=2) // // FIRST TWO CLOCK, WHERE ADC OUTPUT=Z; 
begin
//spi_sck<=0;
state<=20;
end

else if((adc_clk_count>2) && (adc_clk_count<=16))  // FOR FIRST 14 BIT
DATA (CHANNEL 1)
begin
//spi_sck<=0;
adc_data1[adc_bit_count-1]<=spi_miso;  // OUTPUT OF ADC1
state<=20;
end

else if((adc_clk_count>16) && (adc_clk_count <=18)) // HERE ADC OUTPUT=Z, AS
PREVIOUS
begin
//spi_sck<=0;
adc_bit_count<=15;
state<=20;
end

else if((adc_clk_count>18) && (adc_clk_count<=32)) // FOR ANOTHER 14 BIT
DATA (CHANNEL 2)
begin
//spi_sck<=0;

adc_data2[adc_bit_count-1]<=spi_miso;
statec<=20;
end

else if(adc_clk_count==33) // 33 CLOCK PULSE
begin
//spi_sck<=0; 
state<=20;

end 
end

24:begin
adc_clk_count<=0;
adc_bit_count<=17;
spi_sck<=0;
state<=25;
end
25:begin
spi_sch<=0;
adc_sent<=0;
//adc_conv<=1;
state<=26;
end

26:begin 
spi_sck<=1;
amp_shdn<=0;
state<=27;
end

27:begin 
spi_sck<=1;
state<=28;
end
28:begin 
if(cnt>4)
begin
spi_sck<=0;
state<=16; // GETTING ADC OUTPUT IN 2 CHANNELS SIMULTANEOUSLY  
           //AFTER 34 CLOCK CYCLES AND WHEN ADC_CONV=1'b1 AGAIN FOR 2ND

TIME
cnt<=0;
end
else
begin
cnt<=cnt+1;
spi_sck<=0;
state<=28;
end
end

endcase
end
end


endmodule


