--Det er tatt inspirasjon fra en kodepresentasjon fra
--Electrical and Computer Engineering Department, University of New Mexico
--https://ece-research.unm.edu/jimp/vhdl_fpgas/slides/UART.pdf

--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_clk_generator is
    generic (
        F_CLK      : integer := 50000000; --Klokkefrekvens i Hz
        --BAUD       : integer := 9600; --Baud rate bit/s
        --OVERSAMPLE : integer := 8; --Oversampling
        N          : integer := 10 --Antall bit i telleren (2^N > M) (Lavest baud (9600) gir 10)
    );
    port (
        clk        : in  std_logic; --Inngangsklokke
        reset      : in  std_logic;
        max_tick   : out std_logic; --Utgangssignal ved maks tellerverdi (resettes etter bruk)
        baud_limit : in unsigned(N-1 downto 0) --2^10 i grenseverdi gir 1024 maksimum 651 for 9600 baud, mindre for høyere baud
    );
end baud_clk_generator;

architecture Behavioral of baud_clk_generator is
    --constant M : integer := F_CLK / (BAUD * OVERSAMPLE); --Teller grenseverdi (9600 baud gir 651)
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
    r_next <= (others => '0') when r_reg = baud_limit else r_reg + 1; -- Teller opp til baud limit og nullstiller etter

    --Utgangslogikk
    max_tick <= '1' when r_reg = baud_limit else '0'; --Høy når tellerverdien når baud limit
end Behavioral;
