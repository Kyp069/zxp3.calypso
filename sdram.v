//-------------------------------------------------------------------------------------------------
// This file is part of the ZX Spectrum +3 project for Calypso board
// https://github.com/kyp069/zxp3.calypso
//-------------------------------------------------------------------------------------------------
module sdram
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	output reg        ready,

	input  wire       rfsh,
	input  wire[21:0] a,
	input  wire[15:0] d,
	output reg [15:0] q,
	input  wire       rd,
	input  wire       wr,

	output reg        dramCe,
	output reg        dramCs,
	output reg        dramWe,
	output reg        dramRas,
	output reg        dramCas,
	output reg [ 1:0] dramDQM,
	inout  reg [15:0] dramDQ,
	output reg [ 1:0] dramBA,
	output reg [11:0] dramA
);
//-------------------------------------------------------------------------------------------------
`include "sdram_cmd.v"
//-------------------------------------------------------------------------------------------------

reg rdd = 1'b0, rdp = 1'b0;
always @(negedge clock) begin rdd <= rd; rdp <= rd && !rdd; end

reg wrd = 1'b0, wrp = 1'b0;
always @(negedge clock) begin wrd <= wr; wrp <= wr && !wrd; end

reg rfshd = 1'b1, rfshp = 1'b0;
always @(negedge clock) begin rfshd <= rfsh; rfshp <= !rfsh && rfshd; end

//-------------------------------------------------------------------------------------------------

initial ready = 1'b0;

localparam sIDLE = 0;
localparam sREAD = 1;
localparam sWRITE = 2;
localparam sREFRESH = 3;

reg counting = 1'b0;
reg[13:0] count = 1'd0;
reg[ 2:0] state = 1'd0;

always @(posedge clock) begin
	NOP;
	if(counting) count <= count+1'd1; else count <= 1'd0;
	if(!ready) begin
		counting <= 1'b1;
		case(count)
			12000: PRECHARGE(2'b00, 1'b1);
			12008: LMR(14'b0000_1_00_010_0_000); // LDM: CL = 2, BT = seq, BL = 1, 20ns
			12016: REFRESH;
			12024: REFRESH;
			12032: REFRESH;
			12040: REFRESH;
			12048: REFRESH;
			12056: REFRESH;
			12064: REFRESH;
			12072: REFRESH;
			12080: ready <= 1'b1;
		endcase
	end
	else begin
		case(state)
			sIDLE: begin
				counting <= 1'b0;
				if(rdp) begin ACTIVE(a[21:20], a[19:8]); state <= sREAD; end else
				if(wrp) begin ACTIVE(a[21:20], a[19:8]); state <= sWRITE; end else
				if(rfshp) begin REFRESH; state <= sREFRESH; end
			end
			sREAD: begin
				counting <= 1'b1;
				case(count)
					0: READ(a[21:20], a[7:0], 2'b00, 1'b1);
					2: begin q <= dramDQ; state <= sIDLE; end
				endcase
			end
			sWRITE: begin
				counting <= 1'b1;
				case(count)
					0: WRITE(a[21:20], a[7:0], d, 2'b00, 1'b1);
					2: state <= sIDLE;
				endcase
			end
			sREFRESH: begin
				counting <= 1'b1;
				case(count)
					2: state <= sIDLE;
				endcase
			end
		endcase
	end
end

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
