LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY fulladder IS
    PORT(
        x : in STD_LOGIC;
        y : in STD_LOGIC;
        cin : in STD_LOGIC;
        sum : out STD_LOGIC;
        cout : out STD_LOGIC
    );
END fulladder;

ARCHITECTURE behav OF fulladder IS
	BEGIN
		 sum <= x XOR y XOR cin;
		 cout <= (x AND y) OR (cin AND (x XOR y));
END behav;