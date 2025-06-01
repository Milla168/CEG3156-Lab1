LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Takes a 12 bit input (1 hidden bit + 8 bit mantissa + GRS)
-- Determines if rounding is needed
-- Outputs 8 bit (removes hidden 1)

ENTITY rounder IS
	PORT(rnd_in: IN std_logic_vector(11 downto 0);
		  gclk, greset_b: IN std_logic;
		  rnd_out: OUT std_logic_vector(7 downto 0);
		  rnd_overflow: OUT std_logic
	);
END rounder;

ARCHITECTURE struct of rounder IS
signal mantissa, int_rnd_mux, int_rnded_result: std_logic_vector(8 downto 0); -- 9-bit: hidden + 8-bit mantissa
signal grs: std_logic_vector(2 downto 0); -- GRS bits
signal int_rnd_up: std_logic;

component nbit2to1mux
	generic(n : integer := 9);
	port(i_0, i_1: IN std_logic_vector(n-1 downto 0);
		  sel1: IN std_logic;
		  o: OUT std_logic_vector(n-1 downto 0)
	);
end component;
	
component nbitaddersubtractor
	generic(n : integer := 9);
	port(x : in std_logic_vector(n-1 downto 0); 
        y : in std_logic_vector(n-1 downto 0); 
        cin : in std_logic;			
        sum : out std_logic_vector(n-1 downto 0);  
        cout : out std_logic		
    );
end component;

begin
-- Split input
mantissa <= rnd_in(11 downto 3);
grs <= rnd_in(2 downto 0); -- G = grs(2), R = grs(1), S = grs(0)

-- Round-up logic
int_rnd_up <= (grs(2) AND mantissa(0)) OR (grs(2) AND grs(1)) OR (grs(2) AND grs(0));

  -- Mux to select between adding 0 or 1
mux: nbit2to1mux
	port map(i_0  => "000000000",
            i_1  => "000000001",
            sel1 => int_rnd_up,
            o    => int_rnd_mux
    );

adder: nbitaddersubtractor
	port map(x=> mantissa,
            y    => int_rnd_mux,
				cin  => '0',
			   sum  => int_rnded_result,
            cout => rnd_overflow  -- if overflow=1, incrExpR since result needs to be normalized, but keep rnd_out as 0
   );

rnd_out <= int_rnded_result(7 downto 0);

end struct;
