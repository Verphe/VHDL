library ieee;
use ieee.std_logic_1164.all;

library work;

entity uart_rx_top is
    port (
        clk          : in  std_logic;                     --Systemklokke (50MHz)
        reset        : in  std_logic;                     --Reset
        rx           : in  std_logic;                     --UART RX pin
        data_out     : out std_logic_vector(7 downto 0);  --Mottatt databyte
        data_rdy     : out std_logic                      --Puls når databyte er klar
    );
end uart_rx_top;

architecture arch of uart_rx_top is
    signal sample_tick  : std_logic;                     --Sample tick (8x baud)
    --signal q_count      : std_logic_vector(9 downto 0);  --Teller for baud rate generator (Kan brukes for output)

begin
    --Baud generator
    --50 MHz, 9600 Baud, 8x oversampling
    -- M = 651, N = 10

    baud_gen_inst : entity work.baud_clk_generator
        generic map (
            N => 10   --2^N > M
        )
        port map (
            clk        => clk,
            reset      => reset,
            max_tick   => sample_tick --Brukes som sample tick
            --q          => q_count --Igjen, kan brukes
        );
    
    
    --UART mottaker

    uart_rx_inst : entity work.UART_RX
        generic map (
            DATABIT        => 8, --Antall databit
            DBIT_IN_BINARY => 3, --Maks antall databit i binær [1 1 1] = 8
            STOPBIT_TICKS  => 8  --Antall ticks for stoppbit (8*1)
        )
        port map (
            clk          => clk,
            rst          => reset,
            rx           => rx,
            sample_tick  => sample_tick,
            rx_done_tick => data_rdy,
            data_out     => data_out
        );
end arch;
