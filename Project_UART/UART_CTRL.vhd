--Inkluder bibliotek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity UART_CTRL is
    port (
        clk          : in  std_logic;                      -- 50 MHz
        reset        : in  std_logic;

        --Analog styring
        switch       : in  std_logic;                      -- Velger mellom loopback og knappetrykkx
        button_press : in  std_logic;                      -- Knappetrykk

        --Data
        rx_data           : in  std_logic_vector(7 downto 0);   -- Seriell data inn
        tx_data           : out std_logic_vector(7 downto 0);   -- Seriell data ut

        --Flagg
        rx_flag      : in  std_logic;                       -- TX er ferdig, kan motta igjen
        tx_flag      : in  std_logic;                      -- Indikerer at TX er opptatt
        tx_set_flag  : out std_logic;                      -- Flag at tx er opptatt
        rx_clr_flag  : out std_logic                       -- Indikerer at RX har mottatt data
    );
end UART_CTRL;

architecture rtl of UART_CTRL is

    type t_string is array(0 to 7) of std_logic_vector(7 downto 0);
    constant message : t_string := (
        b"01001000", -- H
        b"01100001", -- a
        b"01100001", -- a
        b"01101011", -- k
        b"01101111", -- o
        b"01101110", -- n
        b"00111010", -- :
        b"00101001"  -- )
    );

    signal index : integer range 0 to 7 := 0;
    signal sending : std_logic := '0';

    --constant FIXED_BYTE : std_logic_vector(7 downto 0) := b"01000011";

    signal tx_buf_reg     : std_logic_vector(7 downto 0);
    signal tx_buf_next    : std_logic_vector(7 downto 0);
    signal tx_flag_reg, tx_flag_next : std_logic;

    signal rx_clr_reg : std_logic := '0';
    signal rx_clr_next : std_logic := '0';

    signal button_prev : std_logic := '1';

    signal gap_cnt : integer range 0 to 40 := 0;

begin


    process(clk, reset)
    begin
        if reset = '1' then
            tx_buf_reg   <= (others => '0');
            tx_flag_reg  <= '0';
            index <= 0;
            sending <= '0';
            rx_clr_reg <= '0';
            button_prev <= '1';
            gap_cnt <= 0;

        elsif rising_edge(clk) then
            tx_buf_reg   <= tx_buf_next;
            tx_flag_reg  <= tx_flag_next;
            rx_clr_reg <= rx_clr_next;


            button_prev <= button_press; --Hvis man holder inne så vil ikke 'H' bli sendt uendelig


            if gap_cnt > 0 then
                gap_cnt <= gap_cnt - 1; -- Bruker litt tid mellom hver byte sendt, slik at den ikke hopper over
            end if;


            if switch = '1' then
                if (button_prev = '1' and button_press = '0') then
                    sending <= '1';
                    index <= 0;
                end if;
            end if;
				
            if sending = '1' and tx_flag_next = '1' and tx_flag = '0' then
                if index < 7 then
                    index <= index + 1;
                    gap_cnt <= 20; -- Bruker litt tid mellom hver byte sendt, slik at den ikke hopper over
                else
                    sending <= '0';
                end if;
            end if;

        end if;
    end process;


    process(tx_buf_reg, tx_flag_reg, rx_clr_reg, rx_data,
            button_press, switch, rx_flag, tx_flag, index, sending, gap_cnt)
    begin
    
        tx_buf_next <= tx_buf_reg;
        tx_flag_next <= '0';
        rx_clr_next <= '0';

        if switch = '0' then  -- Loopback

            if rx_flag = '1' then
                tx_buf_next <= rx_data;
                tx_flag_next <= '1';
            end if;

            if tx_flag = '1'then
                rx_clr_next <= '1';
            end if;
        
        else  

            --TX knappetrykk
            if sending = '1' and tx_flag = '0' and gap_cnt = 0 then
                tx_buf_next <= message(index);
                tx_flag_next <= '1';
            end if;

        end if;
    end process;


    tx_data <= tx_buf_reg;
    tx_set_flag <= tx_flag_reg;
    rx_clr_flag <= rx_clr_reg;

end rtl;
