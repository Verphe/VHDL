
--Det er tatt inspirasjon fra en kodepresentasjon fra
--Electrical and Computer Engineering Department, University of New Mexico
--https://ece-research.unm.edu/jimp/vhdl_fpgas/slides/UART.pdf

--Inkluder bibliotek

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_RX is
    generic (
        DATABIT        : integer := 8; --Antall databit
        STOPBIT_TICKS  : integer := 8;  --Antall ticks for stoppbit (8*1)
        OVERSAMPLING   : integer := 8  --Hvor mye oversampling
    );
    port (
        clk            : in  std_logic;               --Systemklokke
        reset          : in  std_logic;               --Reset
        rx             : in  std_logic;               --Serriell data inn
        sample_tick    : in  std_logic;               --Sample tick (8x baud)
        rx_done_tick   : out std_logic;               --Data mottatt flagg
        data_out       : out std_logic_vector(DATABIT-1 downto 0); --Mottatt data
        parity_value   : in unsigned (1 downto 0);     --Paritetsbit innstilling (00 = ingen, 01 = odde, 10 = partall
        parity_error   : out std_logic
    );
end UART_RX;

architecture arch of UART_RX is
    type state_type is (IDLE, START, DATA, STOP, PARITY);
    signal state_reg, state_next : state_type;

    --8x oversampling (0-7) gir 3 bit
    signal s_reg, s_next : unsigned(2 downto 0);  --Punktprøvingsteller (0-7)
    signal n_reg, n_next : unsigned(2 downto 0);  --Databitsteller (0-7)
    signal b_reg, b_next : std_logic_vector(DATABIT-1 downto 0); --Databuffer
    signal p_reg, p_next : unsigned(2 downto 0); --Paritetsbitteller
    signal p_flag_reg, p_flag_next  : std_logic; --Paritetsfeil flagg
    begin
    
    --Tilstandsmaskin og register

    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= IDLE;
            s_reg <= (others => '0'); --Reset punktprøvingsteller 
            n_reg <= (others => '0'); --Reset databiteller
            b_reg <= (others => '0'); --Reset databuffer
            p_reg <= (others => '0'); --Reset paritetsbitteller
            p_flag_reg <= '0';

        
        elsif rising_edge(clk) then
            state_reg <= state_next;
            s_reg <= s_next; --Punktprøvingsteller oppdatering
            n_reg <= n_next; --Databiteller oppdatering
            b_reg <= b_next; --Databuffer oppdatering
            p_reg <= p_next; --Paritetsbitteller oppdatering
            p_flag_reg <= p_flag_next; --Paritetsfeil flagg oppdatering
        end if;
    end process;


    --Tilstander

    process(state_reg, rx, sample_tick, s_reg, n_reg, b_reg, p_reg, p_flag_reg, parity_value)
    begin
        --Standard
        state_next <= state_reg;
        s_next <= s_reg;
        n_next <= n_reg;
        b_next <= b_reg;
        p_next <= p_reg;
        rx_done_tick <= '0';
        p_flag_next <= p_flag_reg;

        case state_reg is
            when IDLE => --Vent på startbit
                
                if rx = '0' then
                    state_next <= START; --Bytt til startbitregistreringstilstand
                    s_next <= (others => '0'); --Reset punktprøvingsteller 
                end if;
            
            when START => --Vent til punkttelleren treffer midten av startbitten
                
                if sample_tick = '1' then
                    if to_integer(s_reg) = 3 then
                        state_next <= DATA; --Bytt til databit-tilstand
                        s_next     <= (others => '0'); --Reset punktteller
                        n_next     <= (others => '0'); --Reset databitteller for å begynne telling
                        p_next     <= (others => '0'); --Reset paritetsbitteller
                        p_flag_next <= '0'; --Reset paritetsfeilflagg
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;
            
            when DATA => --Sjekk databit
                if sample_tick = '1' then --Dersom baud-tick er 1
                    if to_integer(s_reg) = (OVERSAMPLING-1) then --OG dersom databitten er registrert på midten
                        s_next <= (others => '0'); --Reset punktteller

                        if rx = '1' then --Legg til antall 1ere
                            p_next <= p_reg + 1;
                        end if;

                        b_next <= b_reg(DATABIT-2 downto 0) & rx; --Fjerner forrige buffer mot minst signifikante bit og setter nyeste rx-bit inn mest signifikante bit

                        if to_integer(n_reg) = (DATABIT-1) then --Dersom hel byte er motatt
                            state_next <= PARITY; --Bytt til stoppbit-tilstand
                        else
                            n_next <= n_reg + 1; --Ellers tell flere databit
                        end if;
                    
                    else
                        s_next <= s_reg + 1; --Ellers tell flere punkter
                    end if;
                end if;
            
            when PARITY => --Sjekk paritetsbit
                if sample_tick = '1' then
                    if s_reg = OVERSAMPLING -1 then
                        if parity_value /= "00" then
                            if to_integer(p_reg) mod 2 = 0 then
                                if parity_value = "10" then
                                    if rx = '1' then
                                        state_next <= STOP;
                                    else
                                        state_next <= IDLE; --Feil 
                                        p_next <= (others => '0');
                                        p_flag_next <= '1';
                                    end if;
                                elsif parity_value = "01" then
                                    if rx = '0' then
                                        state_next <= STOP;
                                    else
                                        state_next <= IDLE; --Feil i
                                        p_next <= (others => '0');
                                        p_flag_next <= '1';
                                    end if;
                                end if;
                            else
                                if parity_value = "10" then
                                    if rx = '0' then
                                        state_next <= STOP;
                                    else
                                        state_next <= IDLE; --Feil 
                                        p_next <= (others => '0');
                                        p_flag_next <= '1';
                                    end if;
                                elsif parity_value = "01" then
                                    if rx = '1' then
                                        state_next <= STOP;
                                    else
                                        state_next <= IDLE; --Feil 
                                        p_next <= (others => '0');
                                        p_flag_next <= '1';
                                    end if;
                                end if;
                            end if;
                        else
                            state_next <= STOP; --Hopp til stoppbit hvis ingen paritet
                        end if;
                        s_next <= (others => '0');
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;
                    

            when STOP => --Sjekk stoppbit
                if rx = '1' then
                    if sample_tick = '1' then
                        if to_integer(s_reg) = STOPBIT_TICKS - 1 then
                            state_next <= IDLE; --Gå tilbake til idle tilstand
                            rx_done_tick <= '1'; --Byte er klar! yay
                        else
                            s_next <= s_reg + 1; --Tell flere punkter
                        end if;
                    end if;
                end if;
        end case;
    end process;

    data_out <= b_reg; --Koble databuffer til data_out port
    parity_error <= p_flag_reg; --Koble paritetsfeil flagg til port

end architecture arch;
