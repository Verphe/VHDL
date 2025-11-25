--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_CTRL_ButtonPress is
    port (
        clk          : in  std_logic;      --50 MHz
        reset        : in  std_logic;                      
        button_press : in  std_logic;      --Knapp
        data_out     : out std_logic_vector(7 downto 0);
        data_valid   : out std_logic       --Puls for sending                     
    );
end UART_CTRL_ButtonPress;

architecture rtl of UART_CTRL_ButtonPress is
    constant FIXED_BYTE : std_logic_vector(7 downto 0) := x"HF";  -- Sender ut Håkon og Filip :)
    signal valid_reg : std_logic := '0';
begin

    data_out <= FIXED_BYTE;
    data_valid <= valid_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                valid_reg <= '0';
            else
                if button_press = '1' then --Knappetrykk
                    valid_reg <= '1';     -- Sendepuls
                else
                    valid_reg <= '0';     -- Kun ett klokkeslag
                end if;
            end if;
        end if;
    end process;

end rtl;
