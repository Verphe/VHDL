--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity UART_CTRL is
    port (
        clk          : in  std_logic;                      -- 50 MHz
        reset        : in  std_logic;

        --Analog styring
        switch       : in  std_logic;                      -- Velger mellom loopback og knappetrykkx
        button_press : in  std_logic;                      -- Knappetrykk

        --Data
        rx_data           : in  std_logic_vector(7 downto 0);   -- Seriell data inn
        tx_data           : out std_logic_vector(7 downto 0);   -- Seriell data ut

        --Flagg
        rx_flag      : in  std_logic;                       -- TX er ferdig, kan motta igjen
        tx_flag      : in  std_logic;                      -- Indikerer at TX er opptatt
        tx_set_flag  : out std_logic;                      -- Flag at tx er opptatt
        rx_clr_flag  : out std_logic                       -- Indikerer at RX har mottatt data
    );
end UART_CTRL;

architecture rtl of UART_CTRL is
    constant FIXED_BYTE : std_logic_vector(7 downto 0) := b"01000011";

    signal tx_buf_reg     : std_logic_vector(7 downto 0);
    signal tx_buf_next    : std_logic_vector(7 downto 0);
    signal tx_flag_reg, tx_flag_next : std_logic; --Utgangsflagg
    

    begin

    process(clk, reset)
    begin
        if reset = '1' then
            tx_buf_reg   <= (others => '0');
            tx_flag_reg  <= '0';
        elsif rising_edge(clk) then
            tx_buf_reg   <= tx_buf_next;
            tx_flag_reg  <= tx_flag_next;
        end if;
    end process;

    
    process(tx_buf_reg, tx_flag_reg, tx_set_flag, rx_clr_flag, rx_data, button_press, switch)
    begin
    
    if switch = '0' then
        if tx_flag = '1'then
            rx_clr_flag <= '1';
        else
            rx_clr_flag <= '0';
        end if;
        
        if rx_flag = '1' then
            tx_buf_next <= rx_data;
            tx_flag_next <= '1';
        end if;
    
    else
        if button_press = '1' then
            tx_buf_next <= FIXED_BYTE;
            tx_flag_next <= '1';
        else
            tx_flag_next <= '0';
        end if;
    end if;
    end process;

    tx_data <= tx_buf_reg;
    tx_set_flag <= tx_flag_reg;

end rtl;