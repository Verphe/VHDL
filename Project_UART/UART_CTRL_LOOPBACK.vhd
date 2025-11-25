--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_CTRL_LOOPBACK is
    port (
        clk        : in  std_logic;                      -- 50 MHz
        reset      : in  std_logic;                      
        rx         : in  std_logic;                      -- Serriell data inn
        tx         : out std_logic                      -- Serriell data ut
    );
end UART_CTRL_LOOPBACK;

architecture rtl of UART_CTRL_LOOPBACK is

    --RX signaler
    signal rx_done : std_logic;
    signal rx_data : std_logic_vector(7 downto 0);

    --TX signaler
    signal tx_start : std_logic;
    signal tx_byte  : std_logic_vector(7 downto 0);
    signal tx_done  : std_logic;

begin
    UART_RX_INST : entity work.uart_rx_top
        port map (
            clk      => clk,
            reset    => reset,
            rx       => rx,
            data_out => rx_data,
            data_rdy => rx_done,
            rx_led   => open,
            HEX0     => open,
            HEX1     => open
        );