LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity fp_multiplier_control is
	port(greset_b, gclk, NormalOut, NormalP, overflow: in std_logic;
		  loadMpcand, loadMplier, loadProd, shiftProdRight, selExpOp,
		  subBias, loadExpP, incrExpP, zeroP: out std_logic);
end fp_multiplier_control;

architecture struct of fp_multiplier_control is
signal state_input, s : std_logic_vector(5 downto 0);

component enardFF_2 
	port(i_resetBar	: IN	STD_LOGIC;
		i_d		: IN	STD_LOGIC;
		i_enable	: IN	STD_LOGIC;
		i_clock		: IN	STD_LOGIC;
		o_q, o_qBar	: OUT	STD_LOGIC);
end component;

begin

	state0: enardFF_2
		port map(i_resetBar => '1', 
				 i_d => state_input(0), 
				 i_enable => '1', 
				 i_clock => gclk, 
				 o_q => s(0), 
				 o_qBar => open);
	states1to9:
	for i in 1 to 9 generate
		state_i: enardFF_2 
		port map(i_resetBar => greset_b, 
				 i_d => state_input(i), 
				 i_enable => '1', 
				 i_clock => gclk, 
				 o_q => s(i), 
				 o_qBar => open);
	end generate;
	
state_input(0) <= not greset_b;
state_input(1) <= s(0);
state_input(2) <= s(1);
state_input(3) <= s(2) AND not overflow;
state_input(4) <= s(3) AND not NormalP;
state_input(5) <= ((s(3) AND NormalP) OR (s(4) AND not overflow)) AND not NormalOut;

loadMpcand <= s(1);
loadMplier <= s(1);
loadExpP <= s(2) OR s(3);
selExpOp <= s(2);
subBias <= s(3);
loadProd <= s(3);
shiftProdRight <= s(4);
incrExpP <= s(4) OR s(5);
 
 
 end struct;