library ieee;
use ieee.std_logic_1164.all;

entity fp_adder_datapath is
	port(GClock, GReset: in std_logic;
		  SignA, SignB: in std_logic;
		  MantissaA, MantissaB: in std_logic_vector(7 downto 0);
		  ExponentA, ExponentB: in std_logic_vector(6 downto 0);
		  SignOut: out std_logic;
		  MantissaOut: out std_logic_vector(7 downto 0);
		  ExponentOut: out std_logic_vector(6 downto 0)
	);
end fp_adder_datapath;


architecture rtl of fp_adder_datapath is
signal greset_b, int_subExp, int_expSel, int_expZero, int_AxorB, int_loadExpR, int_incExpR, int_decExpR,
		 int_loadManA, int_loadManB, int_resetManA, int_resetManB, int_shiftManA, int_shiftManB, int_ManSel, 
		 int_manSub, int_overflow, int_RZero, int_RoundManRUp, int_RndOverflow, int_loadManR, 
		 int_shiftRightManR, int_shiftLeftManR, int_loadShiftAmnt: std_logic;
signal int_shiftAmnt, int_shiftAmntRegOut: std_logic_vector(6 downto 0);
signal expOut, comp_expOut, expMuxOut: std_logic_vector(6 downto 0);
signal MantissaRnded: std_logic_vector(7 downto 0);
signal InManA, InManB, ManA, ManB, manOp1, manOp2, manAdderOut, comp_manAdderOut, ManR, MantissaR: std_logic_vector(11 downto 0);
signal resetManA_b, resetManB_b: std_logic;
signal int_state: std_logic_vector(17 downto 0);
component fp_adder_controlpath
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
		  state: out std_logic_vector(17 downto 0));
end component;

component nbitaddersubtractor
	generic(n: integer:= 8);
	port(x : in STD_LOGIC_VECTOR(n-1 downto 0); -- First operand
        y : in STD_LOGIC_VECTOR(n-1 downto 0); -- Second operand
        cin : in STD_LOGIC;			-- Control signal for operation type
        sum : out STD_LOGIC_VECTOR(n-1 downto 0);  -- Result
        cout : out STD_LOGIC		-- Carry out
    );
end component;

component nbit2to1mux
	GENERIC(n: integer:=8);
	PORT ( i_0, i_1 : IN std_logic_vector( n-1 downto 0);
			 sel1 : IN std_logic;
			 o : OUT std_logic_vector( n-1 downto 0));
end component;

component nbitshiftreg
    generic(n: integer:= 8);
    port(d_in : in std_logic_vector(n-1 downto 0); --parallel in
         shift_in: in std_logic; --serial in
         clk, load, shiftl, shiftr, reset_b: in std_logic;
         s_out: out std_logic;
			d_out: out std_logic_vector(n-1 downto 0));
end component;

component result_exponent_reg
	port(din: in std_logic_vector(6 downto 0);
	     load, inc, dec, greset_b, gclk: in std_logic;
		  dout, doutb: out std_logic_vector(6 downto 0));
end component;

component rounder
	PORT(rnd_in: IN std_logic_vector(11 downto 0);
		  gclk, greset_b: IN std_logic;
		  rnd_out: OUT std_logic_vector(7 downto 0);
		  rnd_overflow: OUT std_logic
	);
end component;

component nbitreg
	GENERIC( n: integer:= 4);
	PORT(reset_b: in std_logic;
		  din : in std_logic_vector(n-1 downto 0);
		  load, clk: in std_logic;
		  dout, dout_b : out std_logic_vector(n-1 downto 0));
end component;

begin

expSubtraction: nbitaddersubtractor
	generic map(n => 7)
	port map(x => ExponentA, y => ExponentB, cin => int_subExp, 
				sum => expOut, cout => open);

shiftAmnt2sComp: nbitaddersubtractor
	generic map(n => 7)
	port map(x => "0000000", y => expOut, cin => '1', 
				sum => comp_expOut, cout => open);

shiftAmntSel: nbit2to1mux
	generic map(n => 7)
	port map(i_0 => expOut, i_1 => comp_expOut, sel1 => int_expSel, o => int_shiftAmnt);

shiftAmntReg: nbitreg
	generic map(n => 7)
	port map(reset_b => greset_b, din => int_shiftAmnt, load => int_loadShiftAmnt, 
				clk => GClock, dout => int_shiftAmntRegOut, dout_b => open);
	

--ExponentR
expMux: nbit2to1mux
	generic map(n => 7)
	port map(i_0 => ExponentA, i_1 => "1000001", sel1 => expOut(6), o => expMuxOut);
	
ExpR: result_exponent_reg
	port map(din => expMuxOut, load => int_loadExpR, inc => int_incExpR, 
		  dec => int_decExpR, greset_b => greset_b, gclk => GClock, 
		  dout => ExponentOut, doutb => open);
		  
		  
--Mantissa Operations and Setup
InManA <= '1' & MantissaA & "000";
InManB <= '1' & MantissaB & "000"; --hardcoded ManA
resetManA_b <= NOT int_resetManA;
resetManB_b <= NOT int_resetManB;

ManAReg: nbitshiftreg
    generic map(n => 12)
    port map(d_in => InManA, --parallel in
         shift_in => '0', --serial in
         clk => GClock, load => int_loadManA, 
			shiftl => '0', shiftr => int_shiftManA, reset_b => resetManA_b,
         s_out => open,
			d_out => ManA);

ManBReg: nbitshiftreg
    generic map(n => 12)
    port map(d_in => InManB, --parallel in
         shift_in => '0', --serial in
         clk => GClock, load => int_loadManB, 
			shiftl => '0', shiftr => int_shiftManB, reset_b => resetManB_b,
         s_out => open,
			d_out => ManB);
	
manOp1Mux: nbit2to1mux
	generic map(n => 12)
	port map(i_0 => ManA, i_1 => ManB, sel1 => int_ManSel, o => manOp1);
	
manOp2Mux: nbit2to1mux	
	generic map(n => 12)
	port map(i_0 => InManB, i_1 => ManA, sel1 => int_ManSel, o => manOp2);

manAdder: nbitaddersubtractor
	generic map(n => 12)
	port map(x => manOp1, y => manOp2, cin => int_manSub, sum => manAdderOut, cout => int_overflow);
	
manAdderOut2sComp: nbitaddersubtractor
	generic map(n => 12)
	port map(x => "000000000000", y => manAdderOut, cin => '1', sum => comp_manAdderOut, cout => open);
	
manRMux: nbit2to1mux
	generic map(n => 12)
	port map(i_0 => manAdderOut, i_1 => comp_manAdderOut, sel1 => manAdderOut(11), o => ManR);
	
ManRShiftReg_12bit: nbitshiftreg
	generic map(n => 12)
   port map(d_in => ManR, --parallel in
        shift_in => '0', --serial in
        clk => GClock, load => int_loadManR, 
		  shiftl => int_shiftLeftManR, shiftr => int_shiftRightManR, reset_b => greset_b,
        s_out => open,
		  d_out => MantissaR);
	
--rounding
rounding: rounder
	port map(rnd_in => MantissaR, gclk => GClock, greset_b => greset_b,
		  rnd_out => MantissaRnded, rnd_overflow => int_RndOverflow);

	

controlpath: fp_adder_controlpath
	port map(gclk => GClock, greset_b => greset_b,
		  shiftAmnt => int_shiftAmntRegOut,
		  expZero => int_expZero,
		  AltB => expOut(6), 
		  AxorB => int_AxorB,
		  signA => SignA, signB => SignB,
		  overflow => int_overflow,
		  RZero => int_RZero,
		  RoundManRUp => int_RoundManRUp,
		  RndOverflow => int_RndOverflow,
		  manRNormal => MantissaR(11),
		  loadShiftAmnt => int_loadShiftAmnt,
		  subExp => int_subExp, 
		  resetManA => int_resetManA, resetManB => int_resetManB,
		  shiftManA => int_shiftManA, shiftManB => int_shiftManB,
		  loadManA => int_loadManA, loadManB => int_loadManB,
		  loadExpR => int_loadExpR, loadManR => int_loadManR, 
		  manSub => int_manSub, manSel => int_ManSel,
		  expSel => int_expSel,
		  shiftRightManR => int_shiftRightManR, shiftLeftManR => int_shiftLeftManR,
		  incExpR => int_incExpR, decExpR => int_decExpR, 
		  state => int_state);


int_expZero <= '1' when expOut = "0000000" else '0';
int_AxorB <= SignA XOR SignB;
int_RZero <= '1' when manAdderOut = "000000000000" else '0';
int_RoundManRUp <= ManR(2) AND (ManR(3) OR ManR(1) OR ManR(0));

greset_b <= NOT GReset;

--Outputs
MantissaOut <= MantissaR(10 downto 3);
SignOut <= (SignA AND SignB) OR expOut(6);

end rtl;