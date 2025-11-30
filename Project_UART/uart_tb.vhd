library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_tb is
end entity;

architecture tb of UART_tb is

    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal rx      : std_logic := '1';
    signal tx      : std_logic;
    signal rx_led  : std_logic;

    signal ctrl_sw     : std_logic := '0';
    signal ctrl_btn    : std_logic := '1';
    signal baud_switch : std_logic := '0';
    signal button_baud_sel : std_logic := '1';
    signal parity_switch : std_logic := '0';
    signal parity_switch_oe : std_logic := '0';

    signal HEX0, HEX1, HEX2 : std_logic_vector(7 downto 0);

    signal tb_sample_tick : std_logic;

    constant BIT_TIME : time := 104 us; -- 1 bit @ 9600 baud

begin

    DUT : entity work.uart
        port map (
            clk => clk,
            reset => reset,
            rx => rx,
            rx_led => rx_led,
            tx => tx,
            ctrl_sw => ctrl_sw,
            ctrl_btn => ctrl_btn,
            baud_switch => baud_switch,
            button_baud_sel => button_baud_sel,
            parity_switch => parity_switch,
            parity_switch_oe => parity_switch_oe,
            HEX0 => HEX0,
            HEX1 => HEX1,
            HEX2 => HEX2
        );

    clk <= not clk after 10 ns;

    tb_baud_gen: entity work.baud_clk_generator
        port map (
            clk => clk,
            reset => reset,
            max_tick => tb_sample_tick
        );

    stim : process
        variable tx_val : std_logic_vector(7 downto 0);

        procedure uart_rx_send_byte(b : std_logic_vector(7 downto 0)) is
        begin
            rx <= '0'; wait for BIT_TIME;  -- startbit
            for i in 0 to 7 loop
                rx <= b(i);
                wait for BIT_TIME;
            end loop;
            rx <= '1'; wait for BIT_TIME;  -- stopbit
        end procedure;

        procedure press_button is
        begin
            ctrl_btn <= '0';
            wait for 1 ms;
            ctrl_btn <= '1';
        end procedure;

        procedure decode_uart(signal s : std_logic; variable v : out std_logic_vector(7 downto 0)) is
        begin
            wait until falling_edge(s);  -- startbit
            wait for BIT_TIME/2;
            for i in 0 to 7 loop
                v(i) := s;
                wait for BIT_TIME;
            end loop;
        end procedure;

    begin
        wait for 200 ns;
        reset <= '0';
        wait for 200 ns;

        ----------------------------------------------------------------
        -- TEST 1: Kun RX-mottak -> Display skal endre seg
        ----------------------------------------------------------------
        report "TEST 1: RX mottar 0x55";
        uart_rx_send_byte(x"55");
        wait for 10 ms;
        assert HEX0 /= "11111111"
            report "TEST 1 FEIL: display oppdaterte ikke" severity error;
        report "TEST 1 OK";

        ----------------------------------------------------------------
        -- TEST 2: Loopback -> TX sender tilbake det som kommer på RX
        ----------------------------------------------------------------
        report "TEST 2: Loopback 0xA5";
        ctrl_sw <= '0';
        uart_rx_send_byte(x"A5");
        wait for 10 ms;
        report "TEST 2 OK";

        ----------------------------------------------------------------
        -- TEST 3: TX med EVEN parity (CTRL-knapp)
        ----------------------------------------------------------------
        report "TEST 3: TX 0x96 EVEN";
        ctrl_sw <= '1';
        parity_switch <= '1';
        parity_switch_oe <= '0'; -- EVEN
        press_button;
        decode_uart(tx, tx_val);
        assert tx_val = x"96"
            report "TEST 3 FEIL: TX feil ved EVEN paritet" severity error;
        report "TEST 3 OK";

        ----------------------------------------------------------------
        -- TEST 4: TX med ODD parity
        ----------------------------------------------------------------
        report "TEST 4: TX 0x3C ODD";
        parity_switch_oe <= '1';
        press_button;
        decode_uart(tx, tx_val);
        assert tx_val = x"3C"
            report "TEST 4 FEIL: TX feil ved ODD paritet" severity error;
        report "TEST 4 OK";

        ----------------------------------------------------------------
        -- TEST 5: TX uten paritet
        ----------------------------------------------------------------
        report "TEST 5: TX 0xFF NONE";
        parity_switch <= '0';
        press_button;
        decode_uart(tx, tx_val);
        assert tx_val = x"FF"
            report "TEST 5 FEIL: TX feil ved ingen paritet" severity error;
        report "TEST 5 OK";

        ----------------------------------------------------------------
        report "ALLE TESTER FULLFØRT ";
        ----------------------------------------------------------------

        wait;
    end process;

end architecture;
