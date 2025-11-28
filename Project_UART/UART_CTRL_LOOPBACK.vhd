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

begin
    UART_RX_INST : entity work.UART_RX
        port map (
            clk      => clk,
            reset    => reset,
            rx       => rx,
            data_out => rx_data,
            rx_done_tick => rx_done
        );
    
    UART_TX_INST : entity work.UART_TX
        port map (
            clk        => clk,
            reset      => reset,
            tx_start   => tx_start,
            tx_byte    => tx_byte,
            tx         => tx,
            tx_done_tick    => open

        );  
        
    --Loopback kontroll
    process(clk, reset)
    begin
        if reset = '1' then
            tx_start <= '0';
            tx_byte  <= (others => '0');
        elsif rising_edge(clk) then
            if rx_done = '1' then
                tx_start <= '1';          --Start sending
                tx_byte  <= rx_data;     --Sett byte til mottatt data
            else
                tx_start <= '0';         --Hold sendepuls lav
            end if;
        end if;
    end process;
end architecture rtl;