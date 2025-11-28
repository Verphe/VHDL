--Inkluder bibliotek
library ieee;   
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_CTRL_LEDREADY is
    generic (
        LED_CLKS       : integer := 100000000 --Klokkesyklus for LED blink (2 sekunder på 50MHz)
    );
    port (
        clk        : in  std_logic;      --50 MHz
        reset      : in  std_logic;  
        rx_done_tick : in  std_logic;      --Setter led på når byte er mottatt                    
        rx_led  : out std_logic       --LED som indikerer klar til å sende ny byte                    
    );
end UART_CTRL_LEDREADY;

architecture ledready of UART_CTRL_LEDREADY is
    -- Led lyser når byte blir mottatt
    signal r_rx_led       : std_logic := '0';
    signal led_timer     : unsigned(26 downto 0) := (others => '0'); --27 bit for å telle til 100 million (2 sek ved 50MHz)
    signal led_active    : std_logic := '0';
    constant led_time   : unsigned(26 downto 0) := to_unsigned(LED_CLKS, 27);

begin

    LED_ON_PROCESS : process(clk, reset)
    begin
        if reset = '1' then
            r_rx_led <= '0';
            led_active <= '0';
            led_timer <= (others => '0');  -- Reset alt ved reset

        elsif rising_edge(clk) then
            if rx_done_tick = '1' then
                r_rx_led <= '1'; --Sett høy for å indikere mottatt byte
                led_active <= '1'; --Aktiver LED timer
                led_timer <= (others => '0'); --Reset LED timer
            end if;
        end if;
    end process LED_ON_PROCESS;

    LED_TIMER_PROCESS : process(clk, reset)
    begin
        if reset = '1' then
            r_rx_led <= '0';
            led_active <= '0';
            led_timer <= (others => '0'); -- Nullstill timer ved reset

        elsif rising_edge(clk) then
            if led_active = '1' then
                if led_timer < led_time then
                    led_timer <= led_timer + 1;
                else
                    r_rx_led <= '0'; --Slå av LED etter tidsperiode
                    led_active <= '0'; --Deaktiver LED timer
                end if;
            end if;
        end if;
    end process LED_TIMER_PROCESS;

    rx_led <= r_rx_led; --Led utgang

end architecture ledready;
