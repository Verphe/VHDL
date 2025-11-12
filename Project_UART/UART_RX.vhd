--Inkluder bibliotek

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity UART_RX is
    generic (
        DATABIT        : integer := 8; --Antall databit
        DBIT_IN_BINARY : integer := 3; --Maks antall databit i binær [1 1 1] = 8
        STOPBIT_TICKS  : integer := 8;  --Antall ticks for stoppbit (8*1)
        LED_CLKS       : integer := 100000000 --Klokkesyklus for LED blink (2 sekunder på 50MHz)
    );
    port (
        clk            : in  std_logic;               --Systemklokke
        rst            : in  std_logic;               --Reset
        rx             : in  std_logic;               --Serriell data inn
        sample_tick    : in  std_logic;               --Sample tick (8x baud)
        rx_done_tick   : out std_logic;               --Data mottatt flagg
        data_out       : out std_logic_vector(DATABIT-1 downto 0); --Mottatt data
        o_rx_led        : out std_logic                --LED pin for mottatt data
    );
end UART_RX;

architecture arch of UART_RX is
    type state_type is (IDLE, START, DATA, STOP);
    signal state_reg, state_next : state_type;

    --8x oversampling (0-7) gir 3 bit
    signal s_reg, s_next : unsigned(2 downto 0);                 --Punktprøvingsteller (0-7)
    signal n_reg, n_next : unsigned(DBIT_IN_BINARY-1 downto 0);  --Databitsteller (0-7)
    signal b_reg, b_next : std_logic_vector(DATABIT-1 downto 0); --Databuffer
    
    -- Led lyser når byte blir mottatt
    signal r_rx_led       : std_logic := '0';
    signal led_timer     : unsigned(26 downto 0) := (others => '0'); --27 bit for å telle til 100 million (2 sek ved 50MHz)
    signal led_active    : std_logic := '0';
    constant led_time   : unsigned(26 downto 0) := to_unsigned(LED_CLKS, 27);

    begin 
    
    --Tilstandsmaskin og register

    process(clk, rst)
    begin
        if rst = '1' then
            state_reg <= IDLE;
            s_reg <= (others => '0'); --Reset punktprøvingsteller 
            n_reg <= (others => '0'); --Reset databiteller
            b_reg <= (others => '0'); --Reset databuffer
        
        elsif rising_edge(clk) then
            state_reg <= state_next;
            s_reg <= s_next; --Punktprøvingsteller oppdatering
            n_reg <= n_next; --Databiteller oppdatering
            b_reg <= b_next; --Databuffer oppdatering
        end if;
    end process;


    --Tilstander

    process(state_reg, rx, sample_tick, s_reg, n_reg)
    begin
        --Standard
        state_next <= state_reg;
        s_next <= s_reg;
        n_next <= n_reg;
        b_next <= b_reg;
        rx_done_tick <= '0';

        case state_reg is
            when IDLE => --Vent på startbit
                
                if rx = '0' then
                    state_next <= START; --Bytt til startbitregistreringstilstand
                    s_next <= (others => '0'); --Reset punktprøvingsteller 
                end if;
            
            when START => --Vent til punkttelleren treffer midten av startbitten
                
                if sample_tick = '1' then
                    if to_integer(s_reg) = DBIT_IN_BINARY then
                        state_next <= DATA; --Bytt til databit-tilstand
                        s_next     <= (others => '0'); --Reset punktteller
                        n_next     <= (others => '0'); --Reset databitteller for å begynne telling
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;
            
            when DATA => --Sjekk databit
                if sample_tick = '1' then --Dersom databit er 1
                    if to_integer(s_reg) = (DATABIT-1) then --OG dersom databitten er registrert på midten
                        s_next <= (others => '0'); --Reset punktteller

                        b_next <= rx & b_reg(DATABIT-1 downto 1); --Fjerner forrige buffer mot minst signifikante bit og setter nyeste rx-bit inn mest signifikante bit

                        if to_integer(n_reg) = (DATABIT-1) then --Dersom hel byte er motatt
                            state_next <= STOP; --Bytt til stoppbit-tilstand
                        else
                            n_next <= n_reg + 1; --Ellers tell flere databit
                        end if;
                    
                    else
                        s_next <= s_reg + 1; --Ellers tell flere punkter
                    end if;
                end if;
            
            when STOP => --Sjekk stoppbit
                if sample_tick = '1' then
                    if to_integer(s_reg) = STOPBIT_TICKS - 1 then
                        state_next <= IDLE; --Gå tilbake til idle tilstand
                        rx_done_tick <= '1'; --Byte er klar! yay
                        r_rx_led <= '1'; --Sett høy for å indikere mottatt byte
                        led_active <= '1'; --Aktiver LED timer
                        led_timer <= (others => '0'); --Reset LED timer

                    else
                        s_next <= s_reg + 1; --Tell flere punkter
                    end if;
                end if;
        end case;
    end process;

    LED_TIMER_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
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

    o_rx_led <= r_rx_led; --Led utgang

    data_out <= b_reg; --Koble databuffer til data_out port

end architecture arch;
