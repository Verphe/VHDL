--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_CTRL_LOOPBACK is
    port (
        clk        : in  std_logic;                      -- 50 MHz
        reset      : in  std_logic;                      
        rx         : in  std_logic_vector(7 downto 0);                     
        tx         : out std_logic_vector(7 downto 0);                      
    );
end UART_CTRL_LOOPBACK;

architecture rtl of UART_CTRL_LOOPBACK is

    --RX signaler
    --signal rx_done : std_logic;
    --signal rx_data : std_logic_vector(7 downto 0);

    --TX signaler
    --signal tx_start : std_logic;
    --signal tx_byte  : std_logic_vector(7 downto 0);

    -- UART_RX_INST : entity work.UART_RX
    --     port map (
    --         clk      => clk,
    --         reset    => reset,
    --         rx       => rx,
    --         data_out => rx_data,
    --         rx_done_tick => rx_done
    --     );
    
    -- UART_TX_INST : entity work.UART_TX
    --     port map (
    --         clk        => clk,
    --         reset      => reset,
    --         tx_start   => tx_start,
    --         tx_byte    => tx_byte,
    --         tx         => tx,
    --         tx_done_tick    => open

    --     );  
        
    --Loopback kontroll
    begin
    process(clk, reset)
    begin
        if reset = '1' then
            tx <= (others => '0');
end architecture rtl;