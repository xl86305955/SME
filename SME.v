module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;
reg match;
reg [4:0] match_index;
reg valid;

parameter GET_DATA = 1'b0,
					CMP      = 1'b1;

parameter HAT    = 8'h5e,
					DOT    = 8'h2e,
					DOLLAR = 8'h24,
					SPACE  = 8'h20,
					STAR   = 8'h2a;

parameter IS_HAT 		    = 2'b10,
					IS_DOLLAR     = 2'b01,
					IS_HAT_DOLLAR = 2'b11,
					NONE          = 2'b00;

reg cs;
reg ns;

wire [ 1:0] current_char;

reg [ 7:0] string [0:31];
reg [ 7:0] pattern [0:7];

wire [ 7:0] cur_str;
wire [ 7:0] cur_pat;

reg [ 4:0] string_idx;
reg [ 4:0] string_len;

reg [ 2:0] pattern_idx;
reg [ 2:0] pattern_len;

reg [ 4:0] cmp_string_idx;
reg [ 2:0] cmp_pattern_idx;

reg [ 4:0] str_idx;
reg [ 2:0] pat_idx;
reg [ 4:0] match_idx; 

wire is_din;
reg  is_cmp_done;

reg is_pattern;
reg is_string;
reg is_match;

wire is_hat;
wire is_dot;
wire is_dollar;

always @(posedge clk or posedge reset) begin
	if(reset) begin
		cs <= GET_DATA;
	end
	else begin
		cs <= ns;
	end
end

assign is_din = isstring | ispattern;

always @(*) begin
	case(cs)
		GET_DATA: ns = is_din ? GET_DATA : CMP;
		CMP: 			ns = is_cmp_done ? GET_DATA : CMP; 
	endcase
end

/* Get string data */
integer i;
always @(posedge clk or posedge reset) begin
	if(reset) begin
		for(i=0; i<32; i=i+1) begin
			string[i] <= 0;
		end
	end
	else begin	
		if(isstring) begin
			string[string_idx] <= chardata;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		string_idx <= 0;
	end
	else begin
		if(isstring) begin
			string_idx <= string_idx + 1'b1;
		end
		else begin
			string_idx <= 0;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		is_string <= 0;
	end
	else begin
		is_string <= isstring;
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		string_len <= 0;
	end
	else begin
		if(is_string) begin
			string_len <= string_idx;
		end
	end

end

/* Get pattern data */
integer j;
always @(posedge clk or posedge reset) begin
	if(reset) begin
			for(j=0; j<8; j=j+1) begin
				pattern[j] <= 0;
			end
	end
	else begin
		if(ispattern)
			pattern[pattern_idx] <= chardata;
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		pattern_idx <= 0;
	end
	else begin
		if(ispattern) begin
			pattern_idx <= pattern_idx + 1'b1;
		end
		else begin
			pattern_idx <= 0;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		is_pattern <= 0;
	end
	else begin
			is_pattern <= ispattern;
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		pattern_len <= 0;	
	end
	else begin
		if(is_pattern) begin
			pattern_len <= pattern_idx;
		end
	end
end

/* String compare */
assign is_hat = pattern[0] == HAT;
assign is_dot = pattern[cmp_pattern_idx] == DOT;
assign is_dollar = pattern[pattern_len] == DOLLAR;

assign current_char = {is_hat, is_dollar};

always @(posedge clk or posedge reset) begin
	if(reset) begin
		cmp_string_idx <= 0;	
		cmp_pattern_idx <= 0;	
		match_index <= 0;
		match <= 0;
		valid <= 0;
	end
	else begin
		if(cs == CMP) begin
			cmp_string_idx <= str_idx;
			cmp_pattern_idx <= pat_idx;
			match_index <= match_idx;
			match <= is_match;
			valid <= is_cmp_done;
		end
		else begin
			cmp_string_idx <= 0;
			cmp_pattern_idx <= 0;
			match_index <= 0;
			match <= 0;
			valid <= 0;
		end
	end
end

assign cur_str = string[cmp_string_idx];
assign cur_pat = pattern[cmp_pattern_idx];

assign is_char_match = cur_str == cur_pat;

assign is_match_eof = match_idx == string_len;
assign is_pat_eof = pat_idx == pattern_len;

always @(*) begin
	case(current_char)
		NONE: 
			begin
				is_match = is_char_match & is_pat_eof;
				is_cmp_done = is_match_eof | is_match ? 1'b1 : 1'b0;
				if(is_char_match) begin
					str_idx = cmp_string_idx + 1'b1;
					pat_idx = cmp_pattern_idx + 1'b1;
					match_idx = match_index;
				end
				else begin
					if(pattern[cmp_pattern_idx] == DOT) begin
						str_idx = str_idx + 1'b1;
						pat_idx = cmp_pattern_idx + 1'b1;
						match_idx = match_index;
					end
					else begin
						pat_idx = 0;
						str_idx = match_index;
						match_idx = match_index + 1'b1;
					end
				end
			end
	endcase
end

endmodule
