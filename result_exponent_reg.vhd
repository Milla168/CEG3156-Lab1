library ieee;
use ieee.std_logic_1164.all;

--the exponent of the result is a 9 bit incrementing and decrementing register

entity result_exponent_reg is
	port(din: in std_logic_vector(8 downto 0);
	     load, inc, dec, greset_b, gclk: in std_logic;
		  dout, doutb: out std_logic_vector(8 downto 0));
end result_exponent_reg;


architecture rtl of result_exponent_reg is
	signal int_data, int_dout, int_increment, int_decrement: std_logic_vector(8 downto 0);
	
	component nbitaddersubtractor
		generic(n: integer:=9);
		port(x : in STD_LOGIC_VECTOR(n-1 downto 0); -- First operand
        y : in STD_LOGIC_VECTOR(n-1 downto 0); -- Second operand
        cin : in STD_LOGIC;			-- Control signal for operation type
        sum : out STD_LOGIC_VECTOR(n-1 downto 0);  -- Result
        cout : out STD_LOGIC		-- Carry out
		);
	end component;
	
	component nbitreg
		generic(n: integer:=9);
		PORT(reset_b: in std_logic;
		  din : in std_logic_vector(n-1 downto 0);
		  load, clk: in std_logic;
		  dout, dout_b : out std_logic_vector(n-1 downto 0));
	end component;
	
	begin
	
	reg: nbitreg
		port map(reset_b => greset_b, 
					din => int_data, 
					load => load, 
					clk => gclk, 
					dout => int_dout, 
					dout_b => doutb);
	
	increment: nbitaddersubtractor
		port map(x => int_dout, y => "000000001", cin => '0', sum => int_increment, cout =>open);
	
	decrement: nbitaddersubtractor
		port map(x => int_dout, y => "000000001", cin => '1', sum => int_decrement, cout =>open);
		
	int_data <= int_increment when inc = '1' else
					int_decrement when dec = '1' else
					din;	
			
	dout <= int_dout;		
	
end rtl;