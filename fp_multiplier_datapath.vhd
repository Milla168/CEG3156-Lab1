LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity fp_multiplier_datapath is
	port(ExpA, ExpB: in std_logic_vector(6 downto 0);
		  ManA, ManB: in std_logic_vector(7 downto 0);
		  SignA, SignB, greset_b, gclk: in std_logic;
		  loadMpcand, loadMplier, loadProd, shiftProdRight, selExpOp, subBias, loadExpP, incrExpP, zeroP: in std_logic;
		  ManPOut: out std_logic_vector(7 downto 0);
		  ExpPOut: out std_logic_vector(6 downto 0);
		  SignP: out std_logic;
		  overflow, NormalOut, NormalP: out std_logic);
end fp_multiplier_datapath;


architecture struct of fp_multiplier_datapath is

-- Mantissa signals
signal Mpcand_in, Mpcand_out, int_rnd_in : std_logic_vector(11 downto 0); 
signal Mplier_in, Mplier_out : std_logic_vector(8 downto 0); 
signal int_prod_out          : std_logic_vector(20 downto 0);  
signal int_normal_prod_out   : std_logic_vector(20 downto 0);  
signal int_round_prod_out    : std_logic_vector(7 downto 0);   
signal int_round_overflow    : std_logic;

-- Exponent signals
signal mux1_out, mux2_out        : std_logic_vector(6 downto 0); 
signal int_exp_adder_out         : std_logic_vector(6 downto 0); 
signal exp_adder_out             : std_logic_vector(6 downto 0); 
signal exp_reg_out               : std_logic_vector(6 downto 0); 
signal exp_overflow                     : std_logic;                    
                      
component twelvebitmultiplier 
	PORT(M: IN std_logic_vector(11 downto 0);
	     Q: IN std_logic_vector(8 downto 0);
		  gclk, greset_b: IN std_logic;
		  P: OUT std_logic_vector(20 downto 0)
	);
END component;

component nbitreg 
	GENERIC( n: integer:= 12);
	PORT(reset_b: in std_logic;
		  din : in std_logic_vector(n-1 downto 0);
		  load, clk: in std_logic;
		  dout, dout_b : out std_logic_vector(n-1 downto 0));
END component;

component nbit2to1mux
	generic(n : integer := 7);
	port(i_0, i_1: IN std_logic_vector(n-1 downto 0);
		  sel1: IN std_logic;
		  o: OUT std_logic_vector(n-1 downto 0)
	);
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
		  rnd_overflow: OUT std_logic);
END component;

component nbitaddersubtractor
	generic(n : integer := 7);
	port(x : in std_logic_vector(n-1 downto 0); 
        y : in std_logic_vector(n-1 downto 0); 
        cin : in std_logic;			
        sum : out std_logic_vector(n-1 downto 0);  
        cout : out std_logic		
    );
end component;

component nbitshiftreg
    generic(n: integer:= 12);
    port(d_in : in std_logic_vector(n-1 downto 0); --parallel in
         shift_in: in std_logic; --serial in
         clk, load, shiftl, shiftr, reset_b: in std_logic;
         s_out: out std_logic;
			d_out: out std_logic_vector(n-1 downto 0));
end component;


begin 

-- Mantissa Multiplication

Mpcand_in <= '1' & ManA & "000";
MpcandReg: nbitreg
	generic map(n => 12)
	PORT map(reset_b => greset_b,
		  din => Mpcand_in,
		  load => loadMpcand,
		  clk => gclk,
		  dout => Mpcand_out,
		  dout_b => open);
		
Mplier_in <= '1' & ManB;
MplierReg: nbitreg
	generic map(n => 9)
	PORT map (reset_b => greset_b,
		  din => Mplier_in,
		  load => loadMpcand,
		  clk => gclk,
		  dout => Mplier_out,
		  dout_b => open);
		  
Multiplier: twelvebitmultiplier
	port map(M => Mpcand_out,
			  Q => Mplier_out, 
			  gclk => gclk,
			  greset_b => greset_b,
			  P => int_prod_out);
			  
ProdReg: nbitshiftreg
generic map(n => 21)
    port map(
        d_in     => int_prod_out,
        shift_in => '0',    --> Carry from addition shifted in
        clk      => gclk,
        load     => loadProd,
        shiftl   => '0',
        shiftr   => shiftProdRight,
        reset_b  => greset_b,
        s_out    => open,   -- LSB shifts out to Q MSB
        d_out    => int_normal_prod_out
    );

int_rnd_in <= int_normal_prod_out(20 downto 9);
ProdRounder: rounder
	port map(rnd_in => int_rnd_in,
				gclk => gclk,
				greset_b => greset_b,
				rnd_out => int_round_prod_out,
				rnd_overflow => int_round_overflow);
	
-- Exponent Addtion
mux1: nbit2to1mux
	port map(i_0 => int_exp_adder_out,
				i_1 => ExpA,   
				sel1 => selExpOp,
				o => mux1_out);
				
mux2: nbit2to1mux
	port map(i_0 => "0111111",
				i_1 => ExpB,   
				sel1 => selExpOp,
				o => mux2_out);
				
exp_adder: nbitaddersubtractor
	port map(x => mux1_out,
				y => mux2_out,
				cin => subBias,
				sum => exp_adder_out,
				cout => exp_overflow);

ExpP_Reg: result_exponent_reg
	port map(din => exp_adder_out,
				load => loadExpP,
				inc => incrExpP,
				dec => '0',
				greset_b => greset_b,
				gclk => gclk,
				dout => exp_reg_out,
				doutb => open);

ManPOut <= int_round_prod_out;
ExpPOut <= exp_reg_out;
SignP <= SignA XOR SignB;
overflow <= exp_overflow;
NormalOut <= incrExpP;
NormalP <= shiftProdRight;

end struct;