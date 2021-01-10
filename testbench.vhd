library ieee;
use ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture tb of testbench is
    signal clk        : std_logic := '0'; 
    signal reset_n    : std_logic := '0'; 
    signal finished   : std_logic := '0'; 
    signal done       : std_logic := '0'; 

begin

    UUT : entity work.core port map (
        clk        => clk,
        reset_n    => reset_n,
        done       => done
    );
    
    clk <= not clk after 10 ns when finished /= '1' else '0';

    STIMULUS: process
    begin
        reset_n <= '0';
        wait for 100 ns;
        reset_n <= '1';
        wait for 1 ms;
        finished <= '1';
        wait;
    end process STIMULUS;

end tb ;
