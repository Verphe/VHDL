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

    stim_proc : process

        procedure wait_one_bit is
        begin
            for i in 0 to 7 loop
                wait until rising_edge(tb_sample_tick);
            end loop;
        end procedure;

        procedure uart_rx_byte(b : std_logic_vector(7 downto 0)) is
        begin
            -- startbit
            rx <= '0';
            wait_one_bit;

            -- databits
            for i in 0 to 7 loop
                rx <= b(i);
                wait_one_bit;
            end loop;

            -- stopbit
            rx <= '1';
            wait_one_bit;
        end procedure;

    begin
        wait for 200 ns;
        reset <= '0';
        wait for 200 ns;

        report "TEST 1: mottar 0x55" severity note;
        uart_rx_byte("01010101"); --Sender 01010101
        wait for 4 ms;

        -- verifiser på display
        assert (HEX0 /= "11111111")
            report "Display ble ikke oppdatert etter RX" severity error;

        report "TEST 1 OK" severity note;

end architecture;
