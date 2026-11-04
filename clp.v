`default_nettype none
//-------------------------------------------------------------------------------------------------
// This file is part of the ZX Spectrum +3 project for Calypso board
// https://github.com/kyp069/zxp3.calypso
//-------------------------------------------------------------------------------------------------
module clp
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock12,

	output wire[ 7:0] led,

	output wire       dramCk,
	output wire       dramCe,
	output wire       dramCs,
	output wire       dramWe,
	output wire       dramRas,
	output wire       dramCas,
	output wire[ 1:0] dramDQM,
	inout  wire[15:0] dramDQ,
	output wire[ 1:0] dramBA,
	output wire[11:0] dramA,

	output wire[ 1:0] sync,
	output wire[11:0] rgb,

	input  wire       tape,

	output wire       i2sCk,
	output wire       i2sWs,
	output wire       i2sD,

	output wire       midi,   // cyc_aux4 = J14 (mreq)
	input  wire       midiCk, // cyc_aux7 = F16 <-> gp14 = rp_aux0 (nmi)
	input  wire       midiWs, // cyc_aux6 = F13 <-> gp15 = rp_aux1 (a11)
	input  wire       midiD,  // cyc_aux5 = L2  <-> gp12 = rp_aux2 (int)

	input  wire       spiCk,
	input  wire       spiSs1,
	input  wire       spiSs2,
	input  wire       spiSs3,
	input  wire       spiMosi,
	output wire       spiMiso
);
//--- clock ---------------------------------------------------------------------------------------

	wire clockga, powerga;
	pll pll(clock12, clockga, powerga); // 56.7504 MHz

	wire clockula, powerula;
	pll1 pll1(clock12, clockula, powerula); // 56.0000 MHz

	wire clock = timing ? clockula : clockga;
	wire power = powerga && powerula;

	reg[3:0] ce;
	always @(negedge clock, negedge power) if(!power) ce <= 1'd0; else ce <= ce+1'd1;

	wire ne7M0 = ce[2:0] == 7;
	wire pe7M0 = ce[2:0] == 3;
	wire ne3M5 = ce[3:0] == 15;
	wire pe3M5 = ce[3:0] == 7;

//--- video ---------------------------------------------------------------------------------------

	wire r;
	wire g;
	wire b;
	wire i;
	wire hsync;
	wire vsync;

//--- midi ----------------------------------------------------------------------------------------

	wire[7:0] midiQ;
	wire      midiS;

	serial_packer #(.CLK_SYS_HZ(56000000)) midi_packer(clock, midi, midiQ, midiS);

//--- audio ---------------------------------------------------------------------------------------

	wire[15:0] lmidi;
	wire[15:0] rmidi;

	i2s_decoder i2s_decoder(clock, lmidi, rmidi, midiCk, midiWs, midiD);

	wire[14:0] left;
	wire[14:0] right;

	wire[15:0] lmix = { 1'b0, lmidi[15:1] }^16'h4000+{ 1'd0,  left }+{ 4'd0, {12{ status[3] && ear}} };
	wire[15:0] rmix = { 1'b0, rmidi[15:1] }^16'h4000+{ 1'd0, right }+{ 4'd0, {12{ status[3] && ear}} };

	i2s i2s(clock, lmix, rmix, i2sCk, i2sWs, i2sD);

//--- mist ----------------------------------------------------------------------------------------

	wire[63:0] status;

	wire ps2kCk;
	wire ps2kD;

	wire[ 7:0] joy1;
	wire[ 7:0] joy2;

	wire[ 2:0] mbtns;
	wire[ 7:0] xaxis;
	wire[ 7:0] yaxis;

	wire       dioEn;
	wire[ 7:0] dioIx;
	wire[31:0] dioSz;
	wire[26:0] dioA;
	wire[ 7:0] dioD;
	wire       dioW;

	wire sdcCs;
	wire sdcCk;
	wire sdcMosi;
	wire sdcMiso;

	wire       fddCe;
	wire       fddRd;
	wire       fddWr;
	wire       fddA;
	wire[ 7:0] fddD;
	wire[ 7:0] fddQ;
	wire       fddMtr;

	wire       tapeBusy;
	wire       tapeEar;

	mist #(.RGBW(4)) mist
	(
		.clock  (clock  ),
		.power  (power  ),
		.spiCk  (spiCk  ),
		.spiSs1 (spiSs1 ),
		.spiSs2 (spiSs2 ),
		.spiSs3 (spiSs3 ),
		.spiMosi(spiMosi),
		.spiMiso(spiMiso),
		.status (status ),
		.r      (r      ),
		.g      (g      ),
		.b      (b      ),
		.i      (i      ),
		.hsync  (hsync  ),
		.vsync  (vsync  ),
		.rgb    (rgb    ),
		.sync   (sync   ),
		.midiQ  (midiQ  ),
		.midiS  (midiS  ),
		.ps2kCk (ps2kCk ),
		.ps2kD  (ps2kD  ),
		.joy1   (joy1   ),
		.joy2   (joy2   ),
		.mbtns  (mbtns  ),
		.xaxis  (xaxis  ),
		.yaxis  (yaxis  ),
		.dioEn  (dioEn  ),
		.dioIx  (dioIx  ),
		.dioSz  (dioSz  ),
		.dioA   (dioA   ),
		.dioD   (dioD   ),
		.dioW   (dioW   ),
		.sdcCs  (sdcCs  ),
		.sdcCk  (sdcCk  ),
		.sdcMosi(sdcMosi),
		.sdcMiso(sdcMiso),
		.fddCe  (fddCe  ),
		.fddRd  (fddRd  ),
		.fddWr  (fddWr  ),
		.fddA   (fddA   ),
		.fddD   (fddD   ),
		.fddQ   (fddQ   ),
		.fddMtr (fddMtr ),
		.tapePlay(~play ),
		.tapeStop(~stop ),
		.tapeBusy(tapeBusy),
		.tapeEar (tapeEar)
	);

//--- keyboard ------------------------------------------------------------------------------------

	wire      strb;
	wire[7:0] code;

	ps2k ps2k(clock, ps2kCk, ps2kD, strb, code);

	wire[7:0] row;
	wire[4:0] col;
	wire play;
	wire stop;
	wire F5;
	wire F9;

	matrix matrix(clock, strb, code, ~joy1[4:0], ~joy2[4:0], row, col, play, stop, F5, F9);

//--- memory --------------------------------------------------------------------------------------

	wire ready;
	wire rfsh;

	wire[13:0] a1;
	wire[ 7:0] q1;
	wire       w1;

	wire[18:0] a2;
	wire[ 7:0] d2;
	wire[ 7:0] q2 = sdrQ[7:0];
	wire       r2;
	wire       w2;

	dprs #(16) drp(clock, a1, q1, clock, { a2[15], a2[12:0] }, d2, w1 && a2[18:17] == 2);

	reg r2p;
	always @(posedge clock, negedge power) if(!power) r2p <= 1'd0; else if(pe3M5) r2p <= r2;

	// reg dioEnp;
	// reg romLoaded = 0;
	// always @(posedge clock) begin dioEnp <= dioEn; if(dioEn && !dioEnp) romLoaded <= 1'b0; if(!dioEn && dioEnp) romLoaded <= 1'b1; end

	// reg [16:0] clrA;
	// wire       clrE = !clrA[16];
	// wire       clrW = clrA[0];

	// always @(posedge clock, posedge romLoaded) if(romLoaded) clrA <= 1'd0; else if(pe3M5) if(clrE) clrA <= clrA+1'd1;

	wire clrE = 0;
	wire clrW = 0;
	wire[16:0] clrA = 0;
	wire romLoaded = 1'b1;

	wire[21:0] sdrA = { 3'd0, dioEn ? dioA[18:0] : clrE ? { 2'd1, 2'd0, clrA[15:1] } : a2 };
	wire[15:0] sdrD = { 8'hFF, dioEn ? dioD : clrE ? 8'hFF : d2 };
	wire[15:0] sdrQ;
	wire       sdrR = r2p;
	wire       sdrW = dioEn ? dioW : clrE ? clrW : w2;

	sdram sdram
	(
		.clock  (clock  ),
		.ready  (ready  ),
		.rfsh   (rfsh   ),
		.a      (sdrA   ),
		.d      (sdrD   ),
		.q      (sdrQ   ),
		.rd     (sdrR   ),
		.wr     (sdrW   ),
		.dramCe (dramCe ),
		.dramCs (dramCs ),
		.dramRas(dramRas),
		.dramCas(dramCas),
		.dramWe (dramWe ),
		.dramDQM(dramDQM),
		.dramDQ (dramDQ ),
		.dramBA (dramBA ),
		.dramA  (dramA  )
	);

	assign dramCk = clock;

//--- zxp3 ----------------------------------------------------------------------------------------

	wire divmmc = !status[2];
	wire timing = status[5];

	wire reset = power && ready && F9 && !status[0] && !dioEn && romLoaded && !clrE;
	wire nmi = F5 && !status[1];

	wire ear = tapeBusy ? tapeEar : ~tape;

	zxp3 zxp3
	(
		.divmmc (divmmc ),
		.timing (timing ),
		.clock  (clock  ),
		.ne7M0  (ne7M0  ),
		.pe7M0  (pe7M0  ),
		.ne3M5  (ne3M5  ),
		.pe3M5  (pe3M5  ),
		.reset  (reset  ),
		.rfsh   (rfsh   ),
		.nmi    (nmi    ),
		.a1     (a1     ),
		.q1     (q1     ),
		.w1     (w1     ),
		.a2     (a2     ),
		.d2     (d2     ),
		.q2     (q2     ),
		.r2     (r2     ),
		.w2     (w2     ),
		.r      (r      ),
		.g      (g      ),
		.b      (b      ),
		.i      (i      ),
		.hsync  (hsync  ),
		.vsync  (vsync  ),
		.ear    (ear    ),
		.midi   (midi   ),
		.left   (left   ),
		.right  (right  ),
		.col    (col    ),
		.row    (row    ),
		.joy1   (joy1   ),
		.joy2   (joy2   ),
		.mbtns  (mbtns  ),
		.xaxis  (xaxis  ),
		.yaxis  (yaxis  ),
		.fddCe  (fddCe  ),
		.fddRd  (fddRd  ),
		.fddWr  (fddWr  ),
		.fddA   (fddA   ),
		.fddD   (fddD   ),
		.fddQ   (fddQ   ),
		.fddMtr (fddMtr ),
		.sdcCs  (sdcCs  ),
		.sdcCk  (sdcCk  ),
		.sdcMosi(sdcMosi),
		.sdcMiso(sdcMiso)
	);

//-------------------------------------------------------------------------------------------------

	assign led = { ear, tapeBusy, {5{ !reset }}, !sdcCs };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
