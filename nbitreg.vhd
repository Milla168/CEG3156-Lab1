LIBRARY ieee; 
USE ieee.std_logic_1164.all;

ENTITY nbitreg IS 
	GENERIC( n: integer:= 4);
	PORT(reset_b: in std_logic;
		  din : in std_logic_vector(n-1 downto 0);
		  load, clk: in std_logic;
		  dout, dout_b : out std_logic_vector(n-1 downto 0));
END nbitreg;

ARCHITECTURE struc OF nbitreg IS
signal test : std_logic_vector(7 downto 0);
signal fourbit: std_logic_vector(3 downto 0);

COMPONENT enARdFF_2 
	PORT(i_resetBar	: IN	STD_LOGIC;
		i_d		: IN	STD_LOGIC;
	 	i_enable	: IN	STD_LOGIC;
	 	i_clock		: IN	STD_LOGIC;
		o_q, o_qBar	: OUT	STD_LOGIC);
END COMPONENT;

BEGIN
	reg: for i in n-1 downto 0 generate
		biti: enARdFF_2  
			PORT MAP(i_resetBar => reset_b, 
					i_d => din(i), 
					i_enable => load, 
					i_clock => clk, 
					o_q => dout(i),
					o_qBar => dout_b(i));
	end generate;
		
	
END struc;
			
		