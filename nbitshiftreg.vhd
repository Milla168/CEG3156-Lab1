LIBRARY ieee;
USE ieee.std_logic_1164.all;

--PARALLEL/SERIAL IN SERIAL/PARALLEL OUT
entity nbitshiftreg is 
    generic(n: integer:= 8);
    port(d_in : in std_logic_vector(n-1 downto 0); --parallel in
         shift_in: in std_logic; --serial in
         clk, load, shiftl, shiftr, reset_b: in std_logic;
         s_out: out std_logic;
			d_out: out std_logic_vector(n-1 downto 0));
end nbitshiftreg;

architecture struc of nbitshiftreg is  
signal mux_out, int_dout: std_logic_vector(n-1 downto 0);
signal int_en: std_logic;

component onebit4to1mux
    port(i_0, i_1, i_2, i_3: IN std_logic;
         sel1, sel2 : IN std_logic;
         o : OUT std_logic);
end component;

component enardFF_2
    port(
i_resetBar: IN STD_LOGIC;
i_d: IN STD_LOGIC;
i_enable: IN STD_LOGIC;
i_clock: IN STD_LOGIC;
o_q, o_qBar: OUT STD_LOGIC);
end component;

begin 

mux0: onebit4to1mux
    port map(i_0 => d_in(0), 
             i_1 => shift_in, 
             i_2 => int_dout(1), 
             i_3 => '0', --default value
             sel1 => shiftl, 
             sel2 => shiftr,
             o => mux_out(0));
 
muxn_1: onebit4to1mux
    port map(i_0 => d_in(n-1), 
            i_1 => int_dout(n-2), 
            i_2 => shift_in, 
            i_3 => '0', --default value
            sel1 => shiftl, 
            sel2 => shiftr,
            o => mux_out(n-1));

muxes: for i in n-2 downto 1 generate
    muxi: onebit4to1mux
        port map(i_0 => d_in(i), 
                 i_1 => int_dout(i-1), 
                 i_2 => int_dout(i+1),
 i_3 => '0', --default value 
                 sel1 => shiftl, 
                 sel2 => shiftr, 
                 o => mux_out(i));
end generate;

dffs: for i in n-1 downto 0 generate
    biti: enARdFF_2  
        PORT MAP(i_resetBar => reset_b, 
                i_d => mux_out(i), 
                i_enable => int_en, 
                i_clock => clk, 
                o_q => int_dout(i),
                o_qBar => open);
    end generate;
  int_en <= (shiftr OR shiftl OR load);
  s_out <= int_dout(n-1) when shiftl ='1' else int_dout(0);
  d_out <= int_dout;

end struc;