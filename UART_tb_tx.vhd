library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_tx is
end entity;

architecture sim of tb_uart_tx is

    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz 

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    -- Baud-generator
    signal sample_tick : std_logic;
    signal baud_limit  : unsigned(9 downto 0);

    -- TX-buffer / flagg
    signal data_from_ctrl : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_data        : std_logic_vector(7 downto 0);
    signal set_flag       : std_logic := '0';
    signal tx_flag        : std_logic;
    
    -- TX
    signal tx_line      : std_logic;
    signal tx_done_tick : std_logic;
    signal parity_value : unsigned(1 downto 0) := "00";  -- 00 = ingen, 01 = odde, 10 = partall

begin

    --Klokkeprosess
    clk <= not clk after CLK_PERIOD/2;

    --BAUDgen
    baud_gen_inst : entity work.baud_clk_generator
        generic map(
            F_CLK => 50000000,
            N     => 10
        )
        port map(
            clk        => clk,
            reset      => reset,
            max_tick   => sample_tick,
            baud_limit => baud_limit
        );

    --TX-buffer
    tx_buf_inst : entity work.UART_TX_BUFFER_FLAG
        generic map(
            DATABITS => 8
        )
        port map(
            clk      => clk,
            reset    => reset,
            data_in  => data_from_ctrl,
            data_out => tx_data,
            set_flag => set_flag,
            clr_flag => tx_done_tick,
            tx_flag  => tx_flag      
        );

    --TX-modul
    tx_inst : entity work.UART_TX
        generic map(
            DATABITS      => 8,
            STOPBIT_TICKS => 8,  -- 1 stopbit (8 samples)
            OVERSAMPLING  => 8
        )
        port map(
            clk          => clk,
            reset        => reset,
            tx_start     => tx_flag,       -- fra buffer
            data_in      => tx_data,
            sample_tick  => sample_tick,
            tx           => tx_line,
            tx_done_tick => tx_done_tick,
            parity_value => parity_value
        );

    --------------------------------------------------------------------
    --Stimulus-prosess
    stim_proc : process
    begin

        -- Reset
        reset <= '1';
        baud_limit <= to_unsigned(651, baud_limit'length);
        wait for 5 * CLK_PERIOD;
        reset <= '0';

        ----------------------------------------------------------------
        -- TEST 1: Ingen paritet 9600 baud
        -- Send "10100101"
        report "TEST 1: Ingen paritet, baud_limit = 651 (9600)" severity note;

        parity_value   <= "00";                    -- ingen paritet
        baud_limit     <= to_unsigned(651, baud_limit'length);  -- 9600 baud
        data_from_ctrl <= "10100101";              -- Send ut

        -- Start sending: pulser set_flag
        wait for 10 * CLK_PERIOD;
        set_flag <= '1';
        wait for CLK_PERIOD;
        set_flag <= '0';

        -- Vent til TX er ferdig
        wait until rising_edge(clk) and tx_done_tick = '1';
        report "TEST 1 ferdig: byte uten paritet sendt" severity note;

        -- Litt margin
        wait for 20 * CLK_PERIOD;

        ----------------------------------------------------------------
        -- TEST 2: Partallsparitet (partall), 
        -- Send "00111100"
        report "TEST 2: Partall parity, baud_limit = 1" severity note;

        parity_value   <= "10";                    -- partall paritet
        baud_limit     <= to_unsigned(54, baud_limit'length);  -- raskere baudrate (115200)
        data_from_ctrl <= "00111100";

        -- Start sending: pulser set_flag
        set_flag <= '1';
        wait for CLK_PERIOD;
        set_flag <= '0';

        -- Vent til TX er ferdig
        wait until rising_edge(clk) and tx_done_tick = '1';
        report "TEST 2 ferdig: byte med even parity sendt" severity note;

        ----------------------------------------------------------------
        -- Stopp simuleringen
        wait for 100 * CLK_PERIOD;
        assert false report "End of simulation" severity failure;

    end process;

end architecture sim;