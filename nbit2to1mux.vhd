LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nbit2to1mux IS 
	GENERIC(n: integer:=8);
	PORT ( i_0, i_1 : IN std_logic_vector( n-1 downto 0);
			 sel1 : IN std_logic;
			 o : OUT std_logic_vector( n-1 downto 0));
END nbit2to1mux;

ARCHITECTURE behav of nbit2to1mux IS
	BEGIN
	o <= i_0 when sel1 = '0' else i_1;
		 
END behav;