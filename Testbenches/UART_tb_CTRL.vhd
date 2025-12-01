library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_ctrl is
end entity;

architecture sim of tb_uart_ctrl is

    --------------------------------------------------------------------
    -- Konstanter

    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz

    -- For å sjekke baud-rate sekvensen (100 k til 1M)
    type int_array_t is array (1 to 10) of integer;
    constant BAUD_TICKS : int_array_t := (
        62, -- 100 kbit/s
        31, -- 200 kbit/s
        20, -- 300 kbit/s
        15, -- 400 kbit/s
        12, -- 500 kbit/s
        10, -- 600 kbit/s
        8,  -- 700 kbit/s
        7,  -- 800 kbit/s
        6,  -- 900 kbit/s
        5   -- 1 Mbit/s
    );

    -- For å sjekke "Haakon:)" meldingen
    type t_string is array(0 to 7) of std_logic_vector(7 downto 0);
    constant MESSAGE_EXPECTED : t_string := (
        x"48", -- H
        x"61", -- a
        x"61", -- a
        x"6B", -- k
        x"6F", -- o
        x"6E", -- n
        x"3A", -- :
        x"29"  -- )
    );

    --------------------------------------------------------------------
    -- Signaler
    --------------------------------------------------------------------
    -- Klokke og reset
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    -- CTRL-innganger
    signal switch_sig          : std_logic := '0';
    signal baud_switch_sig     : std_logic := '0';
    signal button_press_sig    : std_logic := '1';
    signal button_baud_sel_sig : std_logic := '1';
    signal parity_switch_sig   : std_logic := '0';
    signal parity_switch_oe_sig: std_logic := '0';

    signal rx_data_sig  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_flag_sig  : std_logic := '0';

    -- CTRL-utganger
    signal baud_limit_sig   : unsigned(9 downto 0);
    signal parity_value_sig : unsigned(1 downto 0);
    signal tx_data_sig      : std_logic_vector(7 downto 0);
    signal tx_set_flag_sig  : std_logic;

    -- LED-modul
    signal rx_done_tick_sig : std_logic := '0';
    signal rx_led_sig       : std_logic;

    -- Display-modul
    signal HEX0_sig : std_logic_vector(7 downto 0);
    signal HEX1_sig : std_logic_vector(7 downto 0);
    signal HEX2_sig : std_logic_vector(7 downto 0);

begin

    --------------------------------------------------------------------
    -- Klokke (50 MHz)
    --------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD/2;

    --------------------------------------------------------------------
    -- Instans: UART_CTRL (DUT)

    ctrl_inst : entity work.UART_CTRL
        port map(
            clk             => clk,
            reset           => reset,
            switch          => switch_sig,
            baud_switch     => baud_switch_sig,
            button_press    => button_press_sig,
            button_baud_sel => button_baud_sel_sig,
            parity_switch   => parity_switch_sig,
            parity_switch_oe=> parity_switch_oe_sig,
            baud_limit      => baud_limit_sig,
            parity_value    => parity_value_sig,
            rx_data         => rx_data_sig,
            tx_data         => tx_data_sig,
            rx_flag         => rx_flag_sig,
            tx_set_flag     => tx_set_flag_sig
        );

    --------------------------------------------------------------------
    -- Instans: LEDREADY

    led_inst : entity work.UART_CTRL_LEDREADY
        generic map(
            LED_CLKS => 10   -- veldig kort "blink" for sim
        )
        port map(
            clk          => clk,
            reset        => reset,
            rx_done_tick => rx_done_tick_sig,
            rx_led       => rx_led_sig
        );

    --------------------------------------------------------------------
    -- Instans: DISPLAY

    disp_inst : entity work.UART_CTRL_DISPLAY
        port map(
            clk   => clk,
            reset => reset,
            data_in => rx_data_sig,
            HEX0  => HEX0_sig,
            HEX1  => HEX1_sig,
            HEX2  => HEX2_sig
        );

    --------------------------------------------------------------------
    -- Stimulus

    stim_proc : process
        variable expected_uns : unsigned(9 downto 0);
        variable msg_idx      : integer := 0;
    begin
        ----------------------------------------------------------------
        -- RESET OG INIT

        reset <= '1';
        switch_sig          <= '0';
        baud_switch_sig     <= '0';
        button_press_sig    <= '1';
        button_baud_sel_sig <= '1';
        parity_switch_sig   <= '0';
        parity_switch_oe_sig<= '0';
        rx_data_sig         <= (others => '0');
        rx_flag_sig         <= '0';
        rx_done_tick_sig    <= '0';

        wait for 5 * CLK_PERIOD;
        reset <= '0';
        wait for 5 * CLK_PERIOD;

        ----------------------------------------------------------------
        -- TEST 1: Loopback-modus (switch = '0')
        -- rx_flag = '1' skal gi tx_data = rx_data og puls på tx_set_flag

        report "TEST 1: Loopback modus" severity note;

        rx_data_sig <= x"A5";
        rx_flag_sig <= '1';
        wait until rising_edge(clk);
        rx_flag_sig <= '0';

        -- Sjekk ett par klokkesykler etterpå
        wait until rising_edge(clk);
        assert tx_set_flag_sig = '1'
            report "tx_set_flag forventet '1' i loopback" severity error;
        assert tx_data_sig = x"A5"
            report "tx_data forventet 0xA5 i loopback" severity error;

        -- Etterpå bør flagget gå lavt igjen
        wait until rising_edge(clk);
        assert tx_set_flag_sig = '0'
            report "tx_set_flag burde være '0' etter puls" severity error;

        ----------------------------------------------------------------
        -- TEST 2: Paritetsvalg

        report "TEST 2: Parity-switch test" severity note;

        -- Ingen paritet
        parity_switch_sig    <= '0';
        parity_switch_oe_sig <= '0';
        wait until rising_edge(clk);
        assert parity_value_sig = "00"
            report "parity_value forventet 00 (ingen)" severity error;

        -- Even parity
        parity_switch_sig    <= '1';
        parity_switch_oe_sig <= '0';
        wait until rising_edge(clk);
        assert parity_value_sig = "10"
            report "parity_value forventet 10 (even)" severity error;

        -- Odd parity
        parity_switch_sig    <= '1';
        parity_switch_oe_sig <= '1';
        wait until rising_edge(clk);
        assert parity_value_sig = "01"
            report "parity_value forventet 01 (odd)" severity error;

        -- Tilbake til ingen
        parity_switch_sig    <= '0';
        wait until rising_edge(clk);
        assert parity_value_sig = "00"
            report "parity_value forventet 00 (ingen igjen)" severity error;

        ----------------------------------------------------------------
        -- TEST 3: Variabel baud-rate (baud_switch = '1')

        report "TEST 3: Variable baud-rate stepping" severity note;

        baud_switch_sig <= '1';

        -- Gi litt tid
        wait for 5 * CLK_PERIOD;

        for i in 1 to 10 loop
            -- lag falling edge på button_baud_sel
            button_baud_sel_sig <= '1';
            wait until rising_edge(clk);
            button_baud_sel_sig <= '0';
            wait until rising_edge(clk);  
            button_baud_sel_sig <= '1';
            -- Vent til baud_select har oppdatert seg
            wait for 3 * CLK_PERIOD;

            expected_uns := to_unsigned(BAUD_TICKS(i), baud_limit_sig'length);
            assert baud_limit_sig = expected_uns
                report "Feil baud_limit for steg " & integer'image(i) &
                       " forventet " & integer'image(BAUD_TICKS(i))
                severity error;
        end loop;

        ----------------------------------------------------------------
        -- TEST 4: Knappemodus (switch = '1') og sending av "Haakon:)"

        report "TEST 4: Button-modus, send melding 'Haakon:)'" severity note;

        switch_sig <= '1';
        rx_flag_sig <= '0'; -- Ikke loopback nå

        -- Lag et knappetrykk: falling edge på button_press
        button_press_sig <= '1';
        wait until rising_edge(clk);
        button_press_sig <= '0';
        wait until rising_edge(clk);
        button_press_sig <= '0';  -- hold lav en stund

        msg_idx := 0;

        -- Vent og plukk opp 8 bytes fra tx_data_sig ved tx_set_flag_sig
        while msg_idx < 8 loop
            wait until rising_edge(clk);
            if tx_set_flag_sig = '1' then
                assert tx_data_sig = MESSAGE_EXPECTED(msg_idx)
                    report "Feil byte i melding på index " &
                           integer'image(msg_idx) severity error;
                msg_idx := msg_idx + 1;
            end if;
        end loop;

        report "Meldingen 'Haakon:)' er sendt korrekt" severity note;

        ----------------------------------------------------------------
        -- TEST 5: LED-modul (blink på rx_done_tick)

        report "TEST 5: LED blink ved rx_done_tick" severity note;

        rx_done_tick_sig <= '1';
        wait until rising_edge(clk);
        rx_done_tick_sig <= '0';

        -- Rett etter tick bør LED være høy
        wait until rising_edge(clk);
        assert rx_led_sig = '1'
            report "rx_led forventet '1' rett etter rx_done_tick" severity error;

        -- Etter litt tid (>= LED_CLKS) skal LED være lav
        wait for 20 * CLK_PERIOD;
        assert rx_led_sig = '0'
            report "rx_led forventet '0' etter at timer har løpt ut" severity error;

        ----------------------------------------------------------------
        -- TEST 6: DISPLAY (visuelt i waveform)
        -- Sett rx_data_sig = ASCII 'A' (65) og sjekk HEX0..2 i waves:
        -- skal være "065"

        report "TEST 6: Display test med ASCII 'A' (65)" severity note;

        rx_data_sig <= x"41"; -- 65
        wait for 10 * CLK_PERIOD;

        ----------------------------------------------------------------
        -- FERDIG

        wait for 50 * CLK_PERIOD;
        assert false report "End of UART_CTRL testbench" severity failure;
    end process;

end architecture sim;
