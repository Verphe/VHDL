--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_clk_generator is
    generic (
        F_CLK      : integer := 50000000; --Klokkefrekvens i Hz
        BAUD       : integer := 9600; --Baud rate bit/s
        OVERSAMPLE : integer := 8; --Oversampling
        N          : integer := 10 --Antall bit i telleren (2^N > M)
    );
    port (
        clk        : in  std_logic; --Inngangsklokke
        reset      : in  std_logic;
        max_tick   : out std_logic; --Utgangssignal ved maks tellerverdi (resettes etter bruk)
        q          : out std_logic_vector(N-1 downto 0) --Tellerverdi
    );
end baud_clk_generator;

architecture Behavioral of baud_clk_generator is
    constant M : integer := F_CLK / (BAUD * OVERSAMPLE); --Teller grenseverdi (9600 baud gir 651)
    signal r_reg, r_next : unsigned(N-1 downto 0); --Register for tellerverdi
begin
    --Register
    process(clk, reset)
    begin
        if reset = '1' then
            r_reg <= (others => '0');
        elsif rising_edge(clk) then
            r_reg <= r_next;
        end if;
    end process;

    --"Neste-tilstand"-logikk
    r_next <= (others => '0') when r_reg = (M-1) else r_reg + 1; -- Teller opp til M-1 og nullstiller etter

    --Utgangslogikk
    q <= std_logic_vector(r_reg); --Tellerverdi som std_logic_vector
    max_tick <= '1' when r_reg = (M-1) else '0'; --Høy når tellerverdien når M-1
end Behavioral;
