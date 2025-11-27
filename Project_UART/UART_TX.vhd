library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX is
    generic (
        DATABIT        : integer := 8; --Antall databit
        DBIT_IN_BINARY : integer := 3; --Maks antall databit i binær [1 1 1] = 8
        STOPBIT_TICKS  : integer := 8  --Antall ticks for stoppbit (8*1)
    );
    port (
        clk             : in  std_logic;               --Systemklokke
        rst             : in  std_logic;               --Reset
        tx_start        : in  std_logic;               --Start sending av data
        data_in         : in  std_logic_vector(DATABIT-1 downto 0); --Data som skal sendes
        sample_tick     : in  std_logic;               --Sample tick (8x baud)
        tx              : out std_logic;               --Seriell data ut
        tx_done_tick    : out std_logic                --Data sendt flagg
    );
end UART_TX;

architecture arch of UART_TX is
    type state_type is (IDLE, START, DATA, STOP); --Samme tilstander som i RX
    signal state_reg, state_next : state_type;

    --Trenger ikke oversampling i TX, men en enkel teller for baud, men ettersom at vi har brukt 8x oversampling i baudgen, beholder jeg det for enkelhets skyld
    signal s_reg, s_next : unsigned(2 downto 0);                 --Punktprøvingsteller (0-7)
    signal n_reg, n_next : unsigned(DBIT_IN_BINARY-1 downto 0);  --Databitsteller (0-7)
    signal b_reg, b_next : std_logic_vector(DATABIT-1 downto 0); --Databuffer

    begin
    
    --Tilstandsmaskin og register
