--Inkluderer biblioteker
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_CTRL_DISPLAY is
    port (
        clk        : in  std_logic;                      -- 50 MHz
        reset      : in  std_logic;                      
        data_in    : in  std_logic_vector(7 downto 0);   
        data_ready : in  std_logic;                      
        HEX0, HEX1 : out std_logic_vector(7 downto 0)   -- De to hexene
    );
end UART_CTRL_DISPLAY;

architecture rtl of UART_CTRL_DISPLAY is

    -- Array med 7-segment-encoding for 0–F
    type segmenton_array is array (0 to 15) of std_logic_vector(7 downto 0);
    constant segmenton : segmenton_array := (
        "00000011", -- 0
        "10011111", -- 1
        "00100101", -- 2
        "00001101", -- 3
        "10011001", -- 4
        "01001001", -- 5
        "01000001", -- 6
        "00011111", -- 7
        "00000001", -- 8
        "00001001", -- 9
        "00010001", -- A
        "11000001", -- B
        "01100011", -- C
        "10000101", -- D
        "01100001", -- E
        "01110001"  -- F
    );

    signal top_system, lower_system : std_logic_vector(3 downto 0);

begin

 
    process(clk) --Oppdater når byte mottas
    begin
        if rising_edge(clk) then
            if reset = '1' then
                top_system <= (others => '0');
                lower_system  <= (others => '0');
            elsif data_ready = '1' then
                top_system <= data_in(7 downto 4);
                lower_system  <= data_in(3 downto 0);
            end if;
        end if;
    end process;


    HEX1 <= segmenton(to_integer(unsigned(top_system)));  -- Top del av byte
    HEX0 <= segmenton(to_integer(unsigned(lower_system)));   -- Nedre del av byte
end rtl;
