-- Inkluderer biblioteker
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_CTRL_DISPLAY is
    port (
        clk            : in  std_logic;                      -- 50 MHz
        reset          : in  std_logic;
        data_in        : in  std_logic_vector(7 downto 0);   -- Mottat byte
        data_ready     : in  std_logic;
        display_output : out std_logic_vector(7 downto 0)    -- 7-segment ut
    );
end UART_CTRL_DISPLAY;

architecture rtl of UART_CTRL_DISPLAY is

    -- 0-9 og A-F
    constant SEG_0 : std_logic_vector(7 downto 0) := "00000011";
    constant SEG_1 : std_logic_vector(7 downto 0) := "10011111";
    constant SEG_2 : std_logic_vector(7 downto 0) := "00100101";
    constant SEG_3 : std_logic_vector(7 downto 0) := "00001101";
    constant SEG_4 : std_logic_vector(7 downto 0) := "10011001";
    constant SEG_5 : std_logic_vector(7 downto 0) := "01001001";
    constant SEG_6 : std_logic_vector(7 downto 0) := "01000001";
    constant SEG_7 : std_logic_vector(7 downto 0) := "00011111";
    constant SEG_8 : std_logic_vector(7 downto 0) := "00000001";
    constant SEG_9 : std_logic_vector(7 downto 0) := "00001001";

    constant SEG_A : std_logic_vector(7 downto 0) := "00010001";
    constant SEG_B : std_logic_vector(7 downto 0) := "11000001";
    constant SEG_C : std_logic_vector(7 downto 0) := "01100011";
    constant SEG_D : std_logic_vector(7 downto 0) := "10000101";
    constant SEG_E : std_logic_vector(7 downto 0) := "01100001";
    constant SEG_F : std_logic_vector(7 downto 0) := "01110001";

    constant SEG_BLANK : std_logic_vector(7 downto 0) := (others => '1'); -- blank
    signal ascii_code : std_logic_vector(7 downto 0);

begin

    -- Lagre mottatt ASCII byte
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ascii_code <= (others => '0');
            elsif data_ready = '1' then
                ascii_code <= data_in;
            end if;
        end if;
    end process;

    -- Display
    process(ascii_code)
    begin
        case ascii_code is

            -- Siffer ASCII: '0'–'9' (0x30–0x39)
            when x"30" => display_output <= SEG_0;
            when x"31" => display_output <= SEG_1;
            when x"32" => display_output <= SEG_2;
            when x"33" => display_output <= SEG_3;
            when x"34" => display_output <= SEG_4;
            when x"35" => display_output <= SEG_5;
            when x"36" => display_output <= SEG_6;
            when x"37" => display_output <= SEG_7;
            when x"38" => display_output <= SEG_8;
            when x"39" => display_output <= SEG_9;

            -- Bokstaver ASCII: 'A'–'F' (0x41–0x46)
            when x"41" => display_output <= SEG_A;
            when x"42" => display_output <= SEG_B;
            when x"43" => display_output <= SEG_C;
            when x"44" => display_output <= SEG_D;
            when x"45" => display_output <= SEG_E;
            when x"46" => display_output <= SEG_F;

            -- Hvis tegn ikke er støttet -> blank display
            when others => display_output <= SEG_BLANK;

        end case;
    end process;

end rtl;
