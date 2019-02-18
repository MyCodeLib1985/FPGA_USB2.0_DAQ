module ft232ram_send(
	adbus,
	txe,
	wr,
	clockout,
	siwu,
	
	data,
	rd_clk,
	rd_add,
	
	tr_go,
	tr_done,
	rst_n
	);
	
	
	
	output[7:0] adbus;//D7 to D0 bidirectional FIFO data. This bus is normally input unless OE# is low. 
	input txe;//When high, do not write data into the FIFO
	output wr;//Enables the data byte on the D0...D7 pins to be written into the transmit FIFO buffer
	input clockout;//60 MHz Clock driven from the chip
	output siwu;
	
	/*FPGA 端FIFO  缓冲数据 处理跨时钟域*/
	input[7:0]data;
	output rd_clk;
//	output reg [8:0]rd_add;
	output [10:0]rd_add;
	
	input tr_go; //开始传输 高有效 持续一个周期
	output reg tr_done;
	input rst_n;
	reg r_txe;
	

	
	reg[11:0]cnt;
	reg cnt_en;
	reg next_txe;//将上升沿变低tx  同步到下降沿变化
	
	localparam[11:0]data_len = 12'd2048;
//	parameter buf_len=32768; //数据缓冲区的长度
	
	assign adbus = data;
	assign rd_clk = clockout;
	assign rd_add = cnt[10:0];
	assign siwu = 1'b1;
	
//	assign wr = ~(cnt_en &(~txe)&(~r_txe)&(rst_n)&(~next_txe));
	
	
	assign wr = ~(cnt_en &(~txe)&(~r_txe)&(rst_n));
	
	always@(posedge clockout or negedge rst_n)
	if(!rst_n)
		r_txe <= 1'b1;
	else 	
		r_txe <= txe;
	
	always@(posedge clockout or negedge rst_n)
	if(!rst_n)
		next_txe <= 1'b1;
	else 	
		next_txe <= r_txe;
	
	/*发送计数使能*/
	always@(posedge clockout or negedge rst_n)
	if(!rst_n)
		cnt_en <= 1'b0;
	else if(tr_go)
		cnt_en <= 1'b1;
	else if(cnt == (data_len - 1'b1) )
		cnt_en <= 1'b0;
	

	
	
	always@(posedge clockout or negedge rst_n)
	if(!rst_n)
		cnt <= 12'd0;
	else if(cnt < data_len) begin
			if(cnt_en &(~txe)&(~r_txe)&(rst_n) )//允许发送
				cnt <= cnt + 1'b1;
		end
	else 
		cnt <= 12'd0;
	
	

	
	
	/*传输完毕指示*/
	always@(posedge clockout or negedge rst_n )
	if(!rst_n)
		tr_done <= 1'b0;
	else if((cnt == (data_len - 1'b1))|(cnt == data_len))  //持续两个时钟周期 以方便低频率时钟采样
		tr_done <= 1'b1;
	else 
		tr_done <= 1'b0;
		
		
endmodule
