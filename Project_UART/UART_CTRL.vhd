--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity UART_CTRL is
    port (
        clk          : in  std_logic;                      -- 50 MHz
        reset        : in  std_logic;
        switch       : in  std_logic;                      -- Velger mellom loopback og knappetrykkx
        button_press : in  std_logic;                      -- Knappetrykk
        rx           : in  std_logic;                      -- Seriell data inn
        tx           : out std_logic;                      -- Seriell data ut
        tx_flag      : out std_logic;                      -- Indikerer at TX er opptatt
        set_flag     : in  std_logic;                      -- Flag at tx er opptatt
        clr_flag     : in  std_logic                       -- TX er ferdig, kan motta igjen
    );
end UART_CTRL;

architecture rtl of UART_CTRL is
    signal tx_buf_reg     : std_logic_vector(7 downto 0);
    signal tx_buf_next    : std_logic_vector(7 downto 0);

    signal tx_flag_reg, tx_flag_next : std_logic; --Utgangsflagg
    signal data_in_button : std_logic_vector(7 downto 0);
    signal data_in_RX     : std_logic_vector(7 downto 0);
begin

    UART_CTRL_BUTTONPRESS : entity work.UART_CTRL_BUTTONPRESS
        port map (
        clk          => clk,
        reset        => reset,
        button_press => button_press,
        data_out     => data_in_button,
        data_valid   => tx_flag_next
    );

    UART_CTRL_LOOPBACK : entity work.UART_CTRL_LOOPBACK
        port map (
        clk        => clk,
        reset      => reset,
        rx         => rx,
        tx         => data_in_RX
    );

    UART_TX_BUFFER_FLAG : entity work.UART_TX_BUFFER_FLAG
        port map (
        clk             => clk,
        reset           => reset,
        tx_flag         => tx_flag
    );

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

    
process(tx_buf_reg, tx_flag_reg, set_flag, clr_flag, data_in_RX, data_in_button, switch)
    begin
        tx_buf_next  <= tx_buf_reg;
        tx_flag_next <= tx_flag_reg;

        --MUX
        if switch = '0' then
            --Velger loopback
            if set_flag = '1' then
                tx_buf_next <= data_in_RX; --Sett utgangsdata til RX
                tx_flag_next <= '1'; --Sett flagg høyt
            elsif clr_flag = '1'  then
                tx_flag_next <= '0';
            end if;
        else
            if set_flag = '1' then
                tx_buf_next <= data_in_button;
                tx_flag_next <= '1';
            elsif clr_flag = '1' then
                tx_flag_next <= '0';
            end if;
        end if;
    end process;
    tx <= tx_buf_reg;
    tx_flag <= tx_flag_reg;

end rtl;