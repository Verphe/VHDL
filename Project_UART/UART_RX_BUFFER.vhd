--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flag_buff is
    port(
        clk, reset : in std_logic; --Systemklokke og reset
        set_flag : in std_logic; --Kontrollsignaler for flagg
        data_in : in std_logic_vector(7 downto 0); --Data inngang
        data_out : out std_logic_vector(7 downto 0); --Data utgang
        rx_done : out std_logic --Flagg utgang
    );
end entity flag_buff;

architecture arch of flag_buff is
    signal buf_reg : std_logic_vector(7 downto 0); --Buffer register
    signal buf_next : std_logic_vector(7 downto 0); --Neste verdi for buffer register

    signal flag_reg, flag_next : std_logic; --Flagg register og neste verdi

    begin
        process(clk, reset)
        begin
        if reset = '1' then
            buf_reg <= (others => '0'); --Reset buffer register
            flag_reg <= '0'; --Reset flagg utgang
        elsif rising_edge(clk) then
            buf_reg <= buf_next; --Oppdater buffer register
            flag_reg <= flag_next; --Oppdater flagg utgang
        end if;
    end process;

    process(buf_reg, flag_reg,  set_flag, data_in)
        begin
        buf_next <= buf_reg; --Standard hold verdi
        flag_next <= flag_reg; --Standard hold verdi
        if (set_flag = '1') then
            buf_next <= data_in; --Sett buffer til data inngang
            flag_next <= set_flag; --Send flagg videre
        end if;
    end process;
    data_out <= buf_reg; --Koble buffer register til data utgang
    rx_done <= flag_reg; --Koble flagg register til flagg utgang

    end architecture arch;
