library ieee;
use ieee.std_logic_1164.all;

entity fp_adder_controlpath is
	port(gclk, greset_b: in std_logic;
		  shiftAmnt : in std_logic_vector(6 downto 0);
		  expZero: in std_logic; --ExpA == ExpB
		  AltB: in std_logic; --ExpA < ExpB
		  AxorB: in std_logic; --Sign A xor Sign B
		  signA, signB: in std_logic;
		  overflow: in std_logic; --overflow from mantissa addition
		  RZero: in std_logic; 
		  RoundManRUp: in std_logic;
		  RndOverflow: in std_logic;
		  manRNormal: in std_logic; --manR[11]
		  loadShiftAmnt: out std_logic; --latching shift amount
		  subExp: out std_logic; 
		  resetManA, resetManB: out std_logic;
		  shiftManA, shiftManB: out std_logic; 
		  loadManA, loadManB: out std_logic;
		  loadExpR, loadManR: out std_logic; 
		  manSub, manSel: out std_logic;
		  expSel: out std_logic;
		  shiftRightManR, shiftLeftManR: out std_logic; 
		  incExpR, decExpR: out std_logic;
		  state: out std_logic_vector(17 downto 0) --for debugging
		  );
end fp_adder_controlpath;


architecture rtl of fp_adder_controlpath is
signal int_incShiftCount, int_countEqShift, int_normalize, int_shiftAmntgt8: std_logic;
signal int_shiftCount, int_shiftAmntRegOut: std_logic_vector(6 downto 0);
signal state_input, s: std_logic_vector(17 downto 0);

component nbitcomparator
	generic(n: integer:= 4);
	port(A, B	: IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        AeqB, AgtB, AltB : OUT STD_LOGIC);
end component;

component nbitcounter
	generic(n: integer);
	port(inc_i, greset_b, clk: in std_logic;
        count : out std_logic_vector(n-1 downto 0));
end component;

component enArdFF_2
	port(i_resetBar	: IN	STD_LOGIC;
		i_d		: IN	STD_LOGIC;
		i_enable	: IN	STD_LOGIC;
		i_clock		: IN	STD_LOGIC;
		o_q, o_qBar	: OUT	STD_LOGIC);
end component;



begin

	compareShiftTo8: nbitcomparator --compares shiftAmnt with 8
		generic map(n => 7)
		port map(A => shiftAmnt, B => "0001000", AeqB => open, 
					AgtB => int_shiftAmntgt8, AltB => open);
	shiftCount: nbitcounter --counter that increments shift count
		generic map(n => 7)
		port map(inc_i => int_incShiftCount, greset_b => greset_b, 
					clk => gclk, count => int_shiftCount);
					
				
	compareShiftCountToAmnt: nbitcomparator --checks if count = shift amount
		generic map(n => 7)
		port map(A => shiftAmnt, B => int_shiftCount, AeqB => int_countEqShift, 
					AgtB => open, AltB => open);

	--States

	state0: enardFF_2
		port map(i_resetBar => '1', 
				 i_d => state_input(0), 
				 i_enable => '1', 
				 i_clock => gclk, 
				 o_q => s(0), 
				 o_qBar => open);
	states1to17:
	for i in 1 to 17 generate
		state_i: enardFF_2 
		port map(i_resetBar => greset_b, 
				 i_d => state_input(i), 
				 i_enable => '1', 
				 i_clock => gclk, 
				 o_q => s(i), 
				 o_qBar => open);
	end generate;
	
	
	--State inputs
	state_input(0) <= NOT greset_b;
	state_input(1) <= s(0);
	state_input(2) <= s(1);
	state_input(3) <= s(2) AND AltB AND int_shiftAmntgt8;
	state_input(4) <= (NOT int_countEqShift) AND ((s(2) AND AltB AND (NOT int_shiftAmntgt8)) OR s(4));
	state_input(5) <= (int_countEqShift) AND ((s(2) AND AltB AND (NOT int_shiftAmntgt8)) OR s(4));
	state_input(6) <= s(2) AND (NOT AltB) AND int_shiftAmntgt8;
	state_input(7) <= (NOT int_countEqShift) AND ((s(2) AND (NOT AltB) AND (NOT int_shiftAmntgt8)) OR s(7));
	state_input(8) <= (int_countEqShift) AND ((s(2) AND (NOT AltB) AND (NOT int_shiftAmntgt8)) OR s(7));
	state_input(9) <= (s(8) OR s(5) OR s(3) OR s(6)) AND AxorB AND (NOT signA);
	state_input(10) <= (s(8) OR s(5) OR s(3) OR s(6)) AND AxorB AND signA;
	state_input(11) <= ((s(9) OR s(10)) AND (NOT overflow) AND int_normalize) OR (s(11) AND NOT manRNormal); 
	state_input(12) <= (s(8) OR s(5) OR s(3) OR s(6)) AND (NOT AxorB);
	state_input(13) <= s(12) AND overflow;
	state_input(14) <= ((s(12) AND (NOT overflow)) OR s(13)) AND RoundManRUp;
	state_input(15) <= RndOverflow AND ((s(12) AND (NOT overflow) AND (NOT RoundManRUp)) 
							 OR (s(13) AND (NOT RoundManRUp)) OR s(14));
	state_input(16) <= RoundManRUp AND (((s(9) OR s(10)) AND (NOT overflow) AND (NOT int_normalize)) 
							 OR (s(11) AND manRNormal));
	state_input(17) <= RndOverflow AND 	(((s(9) OR s(10)) AND (NOT overflow) AND (NOT int_normalize) AND (NOT RoundManRUp))
							 OR (s(11) AND manRNormal AND (NOT RoundManRUp)) OR s(16));
	

	
	--internally-used control signals
	--int_normalize <= ((AltB AND signB) OR ((NOT AltB) AND signA)) AND (NOT RZero);
	int_normalize <= '1';
	int_incShiftCount <= s(4) OR s(7);

	
	--control signals
	loadManA <= s(1); 
	loadManB <= s(1);
	loadShiftAmnt <= s(1); 
	subExp <= s(1); 
	--s(2) is a buffer
	resetManA <= s(3) OR s(0);
	resetManB <= s(6) OR s(0); 
	shiftManA <= s(4) and NOT (int_countEqShift);
	shiftManB <= s(7) AND NOT(int_countEqShift);
	expSel <= s(5);
	loadExpR <= s(5) OR s(8) OR s(11) OR s(13) OR s(15) OR s(17);
	loadManR <= s(9) OR s(10) OR s(12);
	manSub <= s(9) OR s(10);
	manSel <= s(10);
	shiftRightManR <= s(13);
	incExpR <= s(13) OR s(15) OR s(17); 
	shiftLeftManR <= s(11);
	decExpR <= s(11); 
	
	state <= s;
	

end rtl;