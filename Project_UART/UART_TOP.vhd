--Det er tatt inspirasjon fra en kodepresentasjon fra
--Electrical and Computer Engineering Department, University of New Mexico
--https://ece-research.unm.edu/jimp/vhdl_fpgas/slides/UART.pdf

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity uart_top is
    port (
        clk             : in  std_logic;                     --Systemklokke (50MHz)
        reset           : in  std_logic;                     --Reset
        rx              : in  std_logic;                     --UART RX pin
        rx_led          : out std_logic;                     --LED pin for mottatt data
        tx              : out std_logic;                     --UART TX pin
        ctrl_sw         : in  std_logic;                     --Switch for å velge mellom loopback og knappetrykk
        ctrl_btn        : in  std_logic;                     --Knappetrykk for å sende data
        baud_switch     : in  std_logic;                     --Switch for å velge mellom fast 9600 baud eller byttbar baudrate
        button_baud_sel : in  std_logic;                     --Knapp for å bytte baudrate når byttbar baud er valgt
        parity_switch   : in  std_logic;                     --Switch for å aktivere/deaktivere paritetsbit
        parity_switch_oe: in  std_logic;                     --Switch for å velge mellom odde/par paritetsbit   
        HEX0            : out std_logic_vector(7 downto 0);  --Hex displayer
        HEX1            : out std_logic_vector(7 downto 0);     
        HEX2            : out std_logic_vector(7 downto 0)     
    );
end uart_top;

architecture arch of uart_top is
    signal sample_tick  : std_logic;                     --Sample tick (8x baud)
    
    --RX-signaler
    signal rx_done_tick_to_setflag : std_logic;
    signal rx_flag_from_rx_to_ctrl : std_logic;
    signal rx_data_to_save_byte : std_logic_vector(7 downto 0);

    --TX-signaler

    signal tx_buf_flag_start : std_logic; --Start sending tx
    signal tx_data_tx_from_buffer : std_logic_vector(7 downto 0);
    signal tx_done_tick_from_tx : std_logic;
    
    --CTRL-signaler
    signal data_from_rx_to_ctrl     : std_logic_vector(7 downto 0);
    signal data_from_ctrl_to_tx     : std_logic_vector(7 downto 0);
    signal set_flag_from_ctrl_to_tx : std_logic;
    signal baud_limit_from_ctrl     : unsigned(9 downto 0);
    signal parity_value_from_ctrl   : unsigned(1 downto 0);

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
            max_tick   => sample_tick, --Brukes som sample tick
            baud_limit => baud_limit_from_ctrl
        );
    
    
    --UART mottaker

    uart_rx_inst : entity work.UART_RX
        generic map (
            DATABIT        => 8, --Antall databit
            STOPBIT_TICKS  => 8  --Antall ticks for stoppbit (8*1)
        )
        port map (
            clk          => clk,
            reset        => reset,
            rx           => rx,
            sample_tick  => sample_tick,
            rx_done_tick => rx_done_tick_to_setflag,
            data_out     => rx_data_to_save_byte,
            parity_value => parity_value_from_ctrl
        );

    -- Lagring av mottatt byte
    uart_rx_buffer_inst : entity work.flag_buff  
        port map (
            clk       => clk,
            reset     => reset,
            set_flag  => rx_done_tick_to_setflag, --Sett flagg når data er mottatt
            data_in   => rx_data_to_save_byte, --Data inngang fra UART RX
            data_out  => data_from_rx_to_ctrl, --Data utgang
            rx_done   => rx_flag_from_rx_to_ctrl 
        );
    --Kontroller for display
       uart_display_inst : entity work.UART_CTRL_DISPLAY
        port map (
            clk        => clk,
            reset      => reset,
            data_in    => data_from_rx_to_ctrl,
            -- data_ready => data_rdy,
            HEX0       => HEX0,
            HEX1       => HEX1,
            HEX2       => HEX2
        );

        --Leadready kontroller
        UART_ledready_inst : entity work.UART_CTRL_LEDREADY
        port map (
            clk          => clk,
            reset        => reset,
            rx_done_tick => rx_done_tick_to_setflag,
            rx_led       => rx_led
        );

        UART_ctrl_inst : entity work.UART_CTRL
        port map(
            clk             => clk,
            reset           => reset,
            switch          => ctrl_sw,
            button_press    => ctrl_btn,
            tx_data         => data_from_ctrl_to_tx,
            rx_data         => data_from_rx_to_ctrl,
            rx_flag         => rx_flag_from_rx_to_ctrl,
            tx_set_flag     => set_flag_from_ctrl_to_tx,
            baud_switch     => baud_switch,
            button_baud_sel => button_baud_sel,
            baud_limit      => baud_limit_from_ctrl,
            parity_switch   => parity_switch,
            parity_switch_oe=> parity_switch_oe,
            parity_value    => parity_value_from_ctrl
        );
        UART_tx_inst : entity work.UART_TX
        port map (
            clk => clk,
            reset => reset,
            tx_start => tx_buf_flag_start,
            data_in => tx_data_tx_from_buffer,
            sample_tick => sample_tick,
            tx  => tx,
            tx_done_tick => tx_done_tick_from_tx,
            parity_value => parity_value_from_ctrl
        );

        UART_tx_buff_flag_inst : entity work.UART_TX_BUFFER_FLAG
        port map (
            clk => clk,
            reset => reset,
            data_in => data_from_ctrl_to_tx,
            data_out => tx_data_tx_from_buffer,
            set_flag => set_flag_from_ctrl_to_tx,
            clr_flag => tx_done_tick_from_tx,
            tx_flag =>  tx_buf_flag_start
        );

end arch;
