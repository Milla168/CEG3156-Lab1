LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- unsiged 12 bit multiplier

ENTITY twelvebitmultiplier IS
	PORT(M: IN std_logic_vector(11 downto 0);
	     Q: IN std_logic_vector(8 downto 0);
		  gclk, greset_b: IN std_logic;
		  P: OUT std_logic_vector(20 downto 0)
	);
END twelvebitmultiplier;


ARCHITECTURE struct of twelvebitmultiplier IS

signal carry, selProdOp, incrShiftCount, shiftRightQ, shiftRightP, loadP, loadQ, QshiftOut,PshiftOut, Qlsb, Qlsb_prev, countEq12: std_logic;
signal adder_data, mux_data, shift_count_value, PReg_out: std_logic_vector(11 downto 0);
signal QReg_out: std_logic_vector(8 downto 0);
signal state_input, s: std_logic_vector(3 downto 0);

component nbit2to1mux
	generic(n : integer := 12);
	port(i_0, i_1: IN std_logic_vector(n-1 downto 0);
		  sel1: IN std_logic;
		  o: OUT std_logic_vector(n-1 downto 0)
	);
end component;
	
component nbitaddersubtractor
	generic(n : integer := 12);
	port(x : in std_logic_vector(n-1 downto 0); 
        y : in std_logic_vector(n-1 downto 0); 
        cin : in std_logic;			
        sum : out std_logic_vector(n-1 downto 0);  
        cout : out std_logic		
    );
end component;

component nbitshiftreg
    generic(n: integer:= 25);
    port(d_in : in std_logic_vector(n-1 downto 0); --parallel in
         shift_in: in std_logic; --serial in
         clk, load, shiftl, shiftr, reset_b: in std_logic;
         s_out: out std_logic;
			d_out: out std_logic_vector(n-1 downto 0));
end component;

component nbitcounter
	 generic(n: integer:= 12);
    port(inc_i, greset_b, clk: in std_logic;
         count : out std_logic_vector(n-1 downto 0));
end component;

component nbitcomparator
    GENERIC(n : INTEGER := 12);
    PORT(
        A, B	: IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        AeqB, AgtB, AltB : OUT STD_LOGIC);
END component;

component enardFF_2 
	port(i_resetBar	: IN	STD_LOGIC;
		i_d		: IN	STD_LOGIC;
		i_enable	: IN	STD_LOGIC;
		i_clock		: IN	STD_LOGIC;
		o_q, o_qBar	: OUT	STD_LOGIC);
end component;

begin

--------- DATAPATH ---------
adder: nbitaddersubtractor
	port map(x => M,
				y => PReg_out,
				cin => '0',
				sum => adder_data,
				cout => carry
				);
				
prodMux: nbit2to1mux
	port map(i_0 => adder_data,
				i_1 => "000000000000",   -- Initialization
				sel1 => selProdOp,
				o => mux_data);	
			
PReg: nbitshiftreg
	 generic map(n => 12)
    port map(
        d_in     => mux_data,
        shift_in => carry,    --> Carry from addition shifted in
        clk      => gclk,
        load     => loadP,
        shiftl   => '0',
        shiftr   => shiftRightP,
        reset_b  => greset_b,
        s_out    => PshiftOut,   -- LSB shifts out to Q MSB
        d_out    => PReg_out
    );

QReg: nbitshiftreg
	 generic map(n => 9)
    port map(
        d_in     => Q,
        shift_in => PshiftOut,   -- Shift in from Product LSB
        clk      => gclk,
        load     => loadQ,
        shiftl   => '0',
        shiftr   => shiftRightQ,
        reset_b  => greset_b,
        s_out    => QshiftOut,   -- LSB shifted out 
        d_out    => QReg_out
    );
				
shiftCounter: nbitcounter
	port map(inc_i => incrShiftCount,
				greset_b => greset_b,
				clk => gclk,
				count => shift_count_value
				);
				
shiftComparator: nbitcomparator
	port map(A => shift_count_value,
				B => "000000001100",
				AeqB => countEq12,
				AgtB => open,
				AltB => open);
				
Qlsb_prev_reg: enardFF_2
    port map(
        i_resetBar => greset_b,
        i_d        => QshiftOut,    -- Capture the LSB shifted out of QReg for next iteration
        i_enable   => '1',
        i_clock    => gclk,
        o_q        => Qlsb_prev,
        o_qBar     => open
    );
	
Qlsb <= QReg_out(0);

-------- CONTROL PATH ------------
	state0: enardFF_2
		port map(i_resetBar => '1', 
				 i_d => state_input(0), 
				 i_enable => '1', 
				 i_clock => gclk, 
				 o_q => s(0), 
				 o_qBar => open);
	states1to3:
	for i in 1 to 3 generate
		state_i: enardFF_2 
		port map(i_resetBar => greset_b, 
				 i_d => state_input(i), 
				 i_enable => '1', 
				 i_clock => gclk, 
				 o_q => s(i), 
				 o_qBar => open);
	end generate;
	
	
-- State inputs			
state_input(0) <= not greset_b;
state_input(1) <= s(0);
state_input(2) <= (s(1) AND Qlsb) OR (s(3) AND not countEq12 AND Qlsb);
state_input(3) <= s(2) OR (s(1) AND not Qlsb) OR (s(3) AND not countEq12 AND not Qlsb);

loadQ <= s(1);
selProdOp <= s(1);
loadP <= s(1) OR s(2);
incrShiftCount <= s(3);
shiftRightQ <= s(3);
shiftRightP <= s(3);

P <= PReg_out & QReg_out;

end struct;


