library ieee;
use ieee.std_logic_1164.all;

entity nbitcounter is  
	 generic(n: integer:= 4);
    port(inc_i, greset_b, clk: in std_logic;
         count : out std_logic_vector(n-1 downto 0));
end nbitcounter;

architecture struc of nbitcounter is   
--intermediate signals
signal adder_out : std_logic_vector(n-1 downto 0);
signal int_x, int_count: std_logic_Vector(n-1 downto 0);


component nbitreg
	generic(n: integer);
    port(reset_b: in std_logic;
        din : in std_logic_vector(n-1 downto 0);
        load, clk: in std_logic;
        dout, dout_b : out std_logic_vector(n-1 downto 0));
end component;

component nbitaddersubtractor
	generic(n: integer);
	port(x : in STD_LOGIC_VECTOR(n-1 downto 0); -- First operand
        y : in STD_LOGIC_VECTOR(n-1 downto 0); -- Second operand
        cin : in STD_LOGIC;			-- Control signal for operation type
        sum : out STD_LOGIC_VECTOR(n-1 downto 0);  -- Result
        cout : out STD_LOGIC		-- Carry out
		  );
end component;

begin
    adder: nbitaddersubtractor
	 generic map(n => n)
    port map(
        x => int_x,
        y => int_count,
        cin => '0',
        sum => adder_out, 
		  cout => open);
    
	reg: nbitreg
    generic map(n => n)
    port map(reset_b => greset_b, 
         din => adder_out,
         load => inc_i, 
         clk => clk,
         dout => int_count);

int_x <= (n-2 downto 0 => '0') & '1';
count <= int_count;

end struc;