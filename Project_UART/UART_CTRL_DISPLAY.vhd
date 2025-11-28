-- Inkluderer biblioteker
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_CTRL_DISPLAY is
    port (
        clk            : in  std_logic;                      -- 50 MHz
        reset          : in  std_logic;
        --data_ready     : in  std_logic;
        data_in        : in  std_logic_vector(7 downto 0);   -- Mottatt byte
        HEX0           : out std_logic_vector(7 downto 0);   
        HEX1           : out std_logic_vector(7 downto 0);
        HEX2           : out std_logic_vector(7 downto 0)
    );
end UART_CTRL_DISPLAY;

architecture rtl of UART_CTRL_DISPLAY is


    signal ascii_val : integer range 0 to 255;
	signal hundreds  : integer range 0 to 9;
    signal tens      : integer range 0 to 9;
    signal ones      : integer range 0 to 9;

    
    -- 7-segment aktive-lav
    type seg_array is array (0 to 9) of std_logic_vector(7 downto 0);
    constant SEG : seg_array := (
        "11000000", -- 0
        "11111001", -- 1
        "10100100", -- 2
        "10110000", -- 3
        "10011001", -- 4
        "10010010", -- 5
        "10000010", -- 6
        "11111000", -- 7
        "10000000", -- 8
        "10010000"  -- 9
    );

begin
    process(clk, reset)
    begin
        if reset = '1' then
            HEX0 <= (others => '1');
            HEX1 <= (others => '1');
            HEX2 <= (others => '1');
        elsif rising_edge(clk) then
            -- Konverter 8-bit -> ASCII heltall
            ascii_val <= to_integer(unsigned(data_in)); 

            -- Del i desimaler
            hundreds <= (ascii_val /100) mod 10; --Tredje siffer
            tens <= (ascii_val / 10) mod 10; -- Andre siffer
            ones <= ascii_val mod 10;        -- Første siffer

            -- Display utganger
            HEX2 <= SEG(hundreds); 
            HEX1 <= SEG(tens);
            HEX0 <= SEG(ones);
        end if;
    end process;
end rtl;
