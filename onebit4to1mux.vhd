LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY onebit4to1mux IS 
	GENERIC(n: integer:=8);
	PORT ( i_0, i_1, i_2, i_3: IN std_logic;
			 sel1, sel2 : IN std_logic;
			 o : OUT std_logic);
END onebit4to1mux;

ARCHITECTURE behav of onebit4to1mux IS
	BEGIN
	o <= i_0 when sel2 = '0' AND sel1 = '0' else
		 i_1 when sel2 = '0' AND sel1 = '1' else
		 i_2 when sel2 = '1' AND sel1 = '0' else
		 i_3;
END behav;