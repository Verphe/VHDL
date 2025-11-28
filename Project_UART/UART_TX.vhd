library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX is
    generic (
        DATABITS       : integer := 8; --Antall databit
        STOPBIT_TICKS  : integer := 8;  --Antall ticks for stoppbit (8*1)
        OVERSAMPLING   : integer := 8  --Hvor mye oversampling
    );
    port (
        clk             : in  std_logic;               --Systemklokke
        rst             : in  std_logic;               --Reset
        tx_start        : in  std_logic;               --Start sending av data
        data_in         : in  std_logic_vector(DATABITS-1 downto 0); --Data som skal sendes
        sample_tick     : in  std_logic;               --Sample tick (8x baud)
        tx              : out std_logic;               --Seriell data ut
        tx_done_tick    : out std_logic                --Data sendt flagg
    );
end UART_TX;

architecture arch of UART_TX is
    type state_type is (IDLE, START, DATA, STOP); --Samme tilstander som i RX
    signal state_reg, state_next : state_type;

    --Trenger ikke oversampling i TX, men en enkel teller for baud, men ettersom at vi har brukt 8x oversampling i baudgen, beholder jeg det for enkelhets skyld
    signal s_reg, s_next : unsigned(2 downto 0);                  --Punktprøvingsteller (0-7)
    signal n_reg, n_next : unsigned(DATABITS-1 downto 0);         --Databitsteller (0-7)
    signal b_reg, b_next : std_logic_vector(DATABITS-1 downto 0); --Databuffer
    signal tx_reg, tx_next: std_logic;                            --Utgangssignal

    begin
    
    --Register (Samme som RX)
    process(clk, rst)
    begin
        if rst = '1' then
            state_reg <= IDLE;
            s_reg <= (others => '0'); --Reset punktprøvingsteller 
            n_reg <= (others => '0'); --Reset databiteller
            b_reg <= (others => '0'); --Reset databuffer
            tx_reg <= '1'; --Sett TX høy
        
        elsif rising_edge(clk) then
            state_reg <= state_next;
            s_reg <= s_next; --Punktprøvingsteller oppdatering
            n_reg <= n_next; --Databiteller oppdatering
            b_reg <= b_next; --Databuffer oppdatering
            tx_reg <= tx_next; --TX oppdatering
        end if;
    end process;  

    --Tilstandsmaskin
    process(state_reg, sample_tick, s_reg, n_reg, b_reg, tx_reg, data_in, tx_start)
    begin
        --Standard verdier
        s_next <= s_reg;
        n_next <= n_reg;
        b_next <= b_reg;
        tx_next <= tx_reg;
        state_next <= state_reg;
        tx_done_tick <= '0';

        case state_reg is
            when IDLE =>
                if tx_start = '1' and sample_tick = '1' then
                    state_next <= START;
                    s_next <= (others => '0');
                    b_next <= data_in; --Dobbeltsjekk denne pls thanks very much
                end if;

            when START =>
                if tx_start = '1' and sample_tick = '1' then
                    tx_next <= '0';
                    if to_integer(s_reg) = OVERSAMPLING-1 then
                        state_next <= DATA;
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;

            when DATA =>
                if tx_start = '1' and sample_tick = '1' then
                    tx_next <= b_reg(0);
                    if to_integer(s_reg) = OVERSAMPLING-1 then
                        s_next <= (others  => '0');
                        b_next <= '0' & b_reg(7 downto 1);
                        if (n_reg = DATABIT-1) then
                            state_next <= STOP;
                        else
                            n_next <= n_reg + 1;
                        end if;
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;

            when STOP =>
                if tx_start = '1' and sample_tick = '1' then
                    tx_next <= '1';
                    if to_integer(s_reg) = STOPBIT_TICKS-1 then
                        state_next <= IDLE;
                        tx_done_tick <= '1';
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;
        end case;
    end process;
        
    tx <= tx_reg;

end architecture arch;
    
