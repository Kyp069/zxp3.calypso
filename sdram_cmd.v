//-------------------------------------------------------------------------------------------------
// ram commands
//-------------------------------------------------------------------------------------------------

task INHIBIT; 
begin
	dramCe  <= 1'b1;
	dramCs  <= 1'b1;
	dramRas <= 1'b1;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramDQ  <= 16'bZ;
	dramBA  <= 2'd0;
	dramA   <= 12'd0;
end
endtask

task NOP;
begin
	dramCe  <= 1'b1;
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramDQ  <= 16'bZ;
	dramBA  <= 2'd0;
	dramA   <= 12'd0;
end
endtask

task REFRESH;
begin
	dramCe  <= 1'b1;
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b0;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramDQ  <= 16'bZ;
	dramBA  <= 2'd0;
	dramA   <= 12'd0;
end
endtask

task PRECHARGE;
input[ 1:0] ba;
input pca;
begin
	dramCe  <= 1'b1;
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b1;
	dramWe  <= 1'b0;
	dramDQM <= 2'b11;
	dramDQ  <= 16'bZ;
	dramBA  <= ba;
	dramA   <= { 1'b0, pca, 9'd0 };
end
endtask

task LMR;
input[13:0] mode;
begin
	dramCe  <= 1'b1;
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b0;
	dramWe  <= 1'b0;
	dramDQM <= 2'b11;
	dramDQ  <= 16'bZ;
	dramBA  <= mode[13:12];
	dramA   <= mode[11: 0];
end
endtask

task ACTIVE;
input[ 1:0] ba;
input[11:0] a;
begin
	dramCe  <= 1'b1;
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQ  <= 16'bZ;
	dramDQM <= 2'b11;
	dramBA  <= ba;
	dramA   <= a;
end
endtask

task WRITE;
input[ 1:0] dqm;
input[ 1:0] ba;
input[ 7:0] a;
input[15:0] d;
input pca;
begin
	dramCe  <= 1'b1;
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b0;
	dramWe  <= 1'b0;
	dramDQM <= dqm;
	dramDQ  <= d;
	dramBA  <= ba;
	dramA   <= { 1'b0, pca, 2'd0, a };
end
endtask

task READ;
input[ 1:0] dqm;
input[ 1:0] ba;
input[ 7:0] a;
input pca;
begin
	dramCe  <= 1'b1;
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b0;
	dramWe  <= 1'b1;
	dramDQM <= dqm;
	dramDQ  <= 16'bZ;
	dramBA  <= ba;
	dramA   <= { 1'b0, pca, 2'd0, a };
end
endtask

//-------------------------------------------------------------------------------------------------
