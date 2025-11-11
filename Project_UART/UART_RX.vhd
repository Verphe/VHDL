--Inkluder bibliotek

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity UART_RX is
    generic (
        DATABIT        : integer := 8; --Antall databit
        DBIT_IN_BINARY : integer := 3; --Maks antall databit i binær [1 1 1] = 8
        STOPBIT_TICKS  : integer := 8  --Antall ticks for stoppbit (8*1)
    );
    port (
        clk            : in  std_logic;               --Systemklokke
        rst            : in  std_logic;               --Reset
        rx             : in  std_logic;               --Serriell data inn
        sample_tick    : in  std_logic;               --Sample tick (8x baud)
        rx_done_tick   : out std_logic;               --Data mottatt flagg
        data_out       : out std_logic_vector(DATABIT-1 downto 0) --Mottatt data
    );
end UART_RX;

architecture arch of UART_RX is
    type state_type is (IDLE, START, DATA, STOP);
    signal state_reg, state_next : state_type;

    --8x oversampling (0-7) gir 3 bit
    signal s_reg, s_next : unsigned(2 downto 0);                 --Punktprøvingsteller (0-7)
    signal n_reg, n_next : unsigned(DBIT_IN_BINARY-1 downto 0);  --Databitsteller (0-7)
    signal b_reg, b_next : std_logic_vector(DATABIT-1 downto 0); --Databuffer
    
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
                    state_next <= start; --Bytt til startbitregistreringstilstand
                    s_next <= (others => '0'); --Reset punktprøvingsteller 
                end if;
            
            when start => --Vent til punkttelleren treffer midten av startbitten
                
                if sample_tick = '1' then
                    if to_integer(s_reg) = DBIT_IN_BINARY then
                        state_next <= data; --Bytt til databit-tilstand
                        s_next     <= (others => '0'); --Reset punktteller
                        n_next     <= (others => '0'); --Reset databitteller for å begynne telling
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;
            
            when data => --Sjekk databit
                if sample_tick = '1' then --Dersom databit er 1
                    if to_integer(s_reg) = (DATABIT-1) then --OG dersom databitten er registrert på midten
                        s_next <= (others => '0'); --Reset punktteller

                        b_next <= rx & b_reg(DATABIT-1 downto 1); --Fjerner forrige buffer mot minst signifikante bit og setter nyeste rx-bit inn mest signifikante bit

                        if to_integer(n_reg) = (DATABIT-1) then --Dersom hel byte er motatt
                            state_next <= stop; --Bytt til stoppbit-tilstand
                        else
                            n_next <= n_reg + 1; --Ellers tell flere databit
                        end if;
                    
                    else
                        s_next <= s_reg + 1; --Ellers tell flere punkter
                    end if;
                end if;
            
            when stop => --Sjekk stoppbit
                if sample_tick = '1' then
                    if to_integer(s_reg) = STOPBIT_TICKS - 1 then
                        state_next <= IDLE; --Gå tilbake til idle tilstand
                        rx_done_tick <= '1'; --Byte er klar! yay
                    else
                        s_next <= s_reg + 1; --Tell flere punkter
                    end if;
                end if;
        end case;
    end process;

    data_out <= b_reg; --Koble databuffer til data_out port

end arch;
