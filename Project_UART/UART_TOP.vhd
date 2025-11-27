library ieee;
use ieee.std_logic_1164.all;

library work;

entity uart_top is
    port (
        clk          : in  std_logic;                     --Systemklokke (50MHz)
        reset        : in  std_logic;                     --Reset
        rx           : in  std_logic;                     --UART RX pin
        data_out_rx     : out std_logic_vector(7 downto 0);  --Mottatt databyte
        data_rdy_rx     : out std_logic;                      --Puls når databyte er klar
        rx_led      : out std_logic;                      --LED pin for mottatt data
        HEX0        : out std_logic_vector(7 downto 0);    --Hex displayer
        HEX1        : out std_logic_vector(7 downto 0);     
        HEX2        : out std_logic_vector(7 downto 0)     
    );
end uart_top;

architecture arch of uart_top is
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
            reset          => reset,
            rx           => rx,
            sample_tick  => sample_tick,
            rx_done_tick => data_rdy_rx,
            data_out     => data_out_rx
            --o_rx_led     => rx_led 
        );

    -- Lagring av mottatt byte
    uart_rx_save_byte_inst : entity work.flag_buff
        port map (
            clk       => clk,
            reset     => reset,
            clr_flag  => '0', --Ikke bruk klar flagg
            set_flag  => data_rdy_rx, --Sett flagg når data er mottatt
            data_in   => data_out_rx, --Data inngang fra UART RX
            data_out  => data_out_rx, --Data utgang
            flag_out  => open --Ikke bruk flagg utgang
        );
    --Kontroller for display
       uart_display_inst : entity work.UART_CTRL_DISPLAY
        port map (
            clk        => clk,
            reset      => reset,
            data_in    => data_out_rx,
            -- data_ready => data_rdy,
            HEX0       => HEX0,
            HEX1       => HEX1,
            HEX2       => HEX2
        );

        --Leadready kontroller
        UART_leadready_inst : entity work.UART_CTRL_LEADREADY
        generic map (
            LED_CLKS => 100000000 --2 sekunder ved 50MHz
        )
        port map (
            clk         => clk,
            reset       => reset,
            rx_done_tick => data_rdy_rx,
            rx_led      => rx_led
        );

end arch;
