library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv is
    PORT(
        led_r   : out std_logic;
        led_g   : out std_logic;
        led_b   : out std_logic
    );
end riscv;

Architecture behavior of riscv is

    component clock port (
        clk_48: out std_logic
    );
    end component;

    component reset port (
        clk:     in  std_logic;
        reset_n: out std_logic
    );
    end component;

    signal reset_n : std_logic;
    signal clk     : std_logic;
    signal done    : std_logic;

begin
    -- Instatiation:
    clock_inst: clock port map (
        clk_48 => clk
    );

    reset_inst: reset port map (
        clk     => clk,
        reset_n => reset_n
    );

    core_inst : entity work.core port map (
        clk     => clk,
        reset_n => reset_n,
        done    => done
    );

    led_g <= done;
    led_b <= '1';
    led_r <= '1';

    process(clk)
    begin
        if rising_edge(clk) then
        end if;
    end process;
end behavior;
