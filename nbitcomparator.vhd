library ieee;
use  ieee.std_logic_1164.all;

ENTITY nbitcomparator IS
    GENERIC(n : INTEGER := 4);
    PORT(
        A, B	: IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        AeqB, AgtB, AltB : OUT STD_LOGIC);
END nbitcomparator;

ARCHITECTURE rtl OF nbitcomparator IS
    SIGNAL int_AgtB, int_AltB : STD_LOGIC_VECTOR(n-1 DOWNTO 0);

    COMPONENT oneBitComparator
        PORT(
            i_GTPrevious, i_LTPrevious	: IN	STD_LOGIC;
            i_Ai, i_Bi			: IN	STD_LOGIC;
            o_GT, o_LT			: OUT	STD_LOGIC);
    END COMPONENT; 

BEGIN
    comparatorMSB: oneBitComparator 
		 PORT MAP( 
			  i_GTPrevious => '0',
			  i_LTPrevious => '0',
			  i_Ai => A(n-1),
			  i_Bi => B(n-1),
			  o_GT => int_AgtB(n-1),
			  o_LT => int_AltB(n-1));

    comparatorLoop: FOR i IN n-2 DOWNTO 0 GENERATE
        -- Instantiate the oneBitComparator
        comparator_n: oneBitComparator PORT MAP(
            i_GTPrevious => int_AgtB(i+1),
            i_LTPrevious => int_AltB(i+1),
            i_Ai => A(i),
            i_Bi => B(i),
            o_GT => int_AgtB(i),
            o_LT => int_AltB(i));
    END GENERATE comparatorLoop;

    -- Output Driver
    AeqB <= not(int_AgtB(0)) and not(int_AltB(0));
    AgtB <= int_AgtB(0);
    AltB <= int_AltB(0);

END rtl;