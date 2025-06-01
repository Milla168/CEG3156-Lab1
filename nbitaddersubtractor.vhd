library ieee;
use ieee.std_logic_1164.all;

entity nbitaddersubtractor is	
	generic(n: integer:= 8);
	port(x : in STD_LOGIC_VECTOR(n-1 downto 0); -- First operand
        y : in STD_LOGIC_VECTOR(n-1 downto 0); -- Second operand
        cin : in STD_LOGIC;			-- Control signal for operation type
        sum : out STD_LOGIC_VECTOR(n-1 downto 0);  -- Result
        cout : out STD_LOGIC		-- Carry out
    );
	
end nbitaddersubtractor;


architecture struc of nbitaddersubtractor is
SIGNAL carry, cins, yxor: STD_LOGIC_VECTOR(n-1 downto 0);

COMPONENT fulladder IS
	PORT(x : in STD_LOGIC;
        y : in STD_LOGIC;
        cin : in STD_LOGIC;
        sum : out STD_LOGIC;
        cout : out STD_LOGIC);
END COMPONENT;

BEGIN 
	cins <= (others => cin);
	yxor <= y XOR cins; -- Invert each bit of y if operation is subtraction
	
	FA0: fulladder PORT MAP(x => x(0), y => yxor(0), cin => cin, sum => sum(0), cout => carry(0)); 
	addersubtractor: for i in 1 to n-1 generate
	FAi: fulladder PORT MAP(x => x(i), y => yxor(i), cin => carry(i-1), sum => sum(i), cout => carry(i));
	end generate;
	
	cout <= carry(n-1); -- Assign final carry out

end struc;