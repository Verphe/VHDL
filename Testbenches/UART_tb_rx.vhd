library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_rx is
end entity;

architecture sim of tb_uart_rx is

    constant CLK_PERIOD      : time    := 20 ns;    -- 50 MHz
    constant OVERSAMPLING_C  : integer := 8;
    constant DATABITS_C      : integer := 8;

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';

    signal rx_sig      : std_logic := '1';  -- idle = '1'
    signal sample_tick : std_logic;

    signal baud_limit  : unsigned(9 downto 0);

    signal rx_done_tick_sig : std_logic;
    signal data_rx_sig      : std_logic_vector(7 downto 0);
    signal parity_value_sig : unsigned(1 downto 0) := "00";
    signal parity_error_sig : std_logic;

    -- RX-buffer
    signal buf_data_out : std_logic_vector(7 downto 0);
    signal buf_rx_done  : std_logic;

begin

    --------------------------------------------------------------------
    -- Klokke
    clk <= not clk after CLK_PERIOD/2;

    --------------------------------------------------------------------
    -- Baud-generator
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

    --------------------------------------------------------------------
    -- UART_RX
    uart_rx_inst : entity work.UART_RX
        generic map(
            DATABIT       => DATABITS_C,
            STOPBIT_TICKS => OVERSAMPLING_C, -- 1 stopbit av 8 samples
            OVERSAMPLING  => OVERSAMPLING_C
        )
        port map(
            clk          => clk,
            reset        => reset,
            rx           => rx_sig,
            sample_tick  => sample_tick,
            rx_done_tick => rx_done_tick_sig,
            data_out     => data_rx_sig,
            parity_value => parity_value_sig,
            parity_error => parity_error_sig
        );

    --------------------------------------------------------------------
    -- RX-buffer
    rx_buf_inst : entity work.flag_buff
        port map(
            clk      => clk,
            reset    => reset,
            set_flag => rx_done_tick_sig,
            data_in  => data_rx_sig,
            data_out => buf_data_out,
            rx_done  => buf_rx_done
        );

    --------------------------------------------------------------------
    -- Stimulus-prosess
    stim_proc : process
        -- Venter 1 bitperiode (8 oversamples)
        procedure wait_bit_period is
            variable ticks : integer := 0;
        begin
            while ticks < OVERSAMPLING_C loop
                wait until rising_edge(clk);
                if sample_tick = '1' then
                    ticks := ticks + 1;
                end if;
            end loop;
        end procedure;

        -- sende en UART-ramme
        procedure send_frame(
            constant data                : in std_logic_vector(7 downto 0);
            constant use_parity         : in boolean;
            constant even_parity        : in boolean;
            constant inject_parity_err  : in boolean
        ) is
            variable ones       : integer := 0;
            variable parity_bit : std_logic := '0';
        begin
            -- Beregn paritetsbit
            if use_parity then
                for i in 0 to DATABITS_C-1 loop
                    if data(i) = '1' then
                        ones := ones + 1;
                    end if;
                end loop;

                if even_parity then
                    -- Partall:
                    if (ones mod 2) = 0 then
                        parity_bit := '0';
                    else
                        parity_bit := '1';
                    end if;
                else
                    -- Odde: 
                    if (ones mod 2) = 0 then
                        parity_bit := '1';
                    else
                        parity_bit := '0';
                    end if;
                end if;

                if inject_parity_err then
                    -- Flipp bit for å tvinge feil
                    if parity_bit = '0' then
                        parity_bit := '1';
                    else
                        parity_bit := '0';
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- STARTBIT
            rx_sig <= '1';
            wait_bit_period;        -- litt idle
            rx_sig <= '0';          -- startbit
            wait_bit_period;

            ----------------------------------------------------------------
            -- DATABITS
            for i in 0 to DATABITS_C-1 loop
                rx_sig <= data(i);
                wait_bit_period;
            end loop;

            ----------------------------------------------------------------
            -- PARITETSBIT (hvis aktiv)
            if use_parity then
                rx_sig <= parity_bit;
                wait_bit_period;
            end if;

            ----------------------------------------------------------------
            -- STOPBIT (1)
            rx_sig <= '1';
            wait_bit_period;
        end procedure;

    begin
        ----------------------------------------------------------------
        -- RESET
        reset      <= '1';
        baud_limit <= to_unsigned(3, baud_limit'length);  -- "treg" baud for simulering
        wait for 10 * CLK_PERIOD;
        reset <= '0';
        wait for 10 * CLK_PERIOD;

        ----------------------------------------------------------------
        -- TEST 1: Ingen paritet
        report "TEST 1: Ingen paritet" severity note;

        parity_value_sig <= "00";                     -- ingen paritet
        wait for 10 * CLK_PERIOD;

        send_frame(x"A5", false, true, false);        -- use_parity=false

        -- vent til RX flagger byte mottatt
        wait until rising_edge(clk) and rx_done_tick_sig = '1';

        assert data_rx_sig = x"A5"
            report "Feil data_rx_sig ved TEST 1 (forventet 0xA5)" severity error;
        assert buf_data_out = x"A5"
            report "Feil buf_data_out ved TEST 1 (forventet 0xA5)" severity error;
        assert parity_error_sig = '0'
            report "parity_error skal være '0' når paritet er avslått" severity error;

        ----------------------------------------------------------------
        -- TEST 2: Even parity, korrekt

        report "TEST 2: Even parity, korrekt" severity note;

        baud_limit      <= to_unsigned(1, baud_limit'length);  -- raskere baud
        parity_value_sig <= "10";                   -- Partall

        wait for 20 * CLK_PERIOD;

        send_frame(x"3C", true, true, false);       -- use_parity=true, partall, ingen feil

        wait until rising_edge(clk) and rx_done_tick_sig = '1';

        assert data_rx_sig = x"3C"
            report "Feil data_rx_sig ved TEST 2 (forventet 0x3C)" severity error;
        assert buf_data_out = x"3C"
            report "Feil buf_data_out ved TEST 2 (forventet 0x3C)" severity error;
        assert parity_error_sig = '0'
            report "parity_error skal være '0' ved korrekt paritet" severity error;

        ----------------------------------------------------------------
        -- TEST 3: Even parity, med vilje feil

        report "TEST 3: Even parity, med paritetsfeil" severity note;

        -- Vi sender samme byte, men flipper paritetsbit
        send_frame(x"55", true, true, true);        -- inject_parity_err = true

        -- Gi tid til PARITY-tilstand og overgang til IDLE
        wait for 20 * CLK_PERIOD;

        -- Forventning: ingen rx_done_tick, og parity_error går til '1'
        assert rx_done_tick_sig = '0'
            report "rx_done_tick skal IKKE være '1' ved paritetsfeil" severity error;
        assert parity_error_sig = '1'
            report "parity_error skal være '1' etter paritetsfeil" severity error;

        ----------------------------------------------------------------
        -- FERDIG
    
        wait for 100 * CLK_PERIOD;
        assert false report "End of UART_RX testbench" severity failure;
    end process;

end architecture sim;
