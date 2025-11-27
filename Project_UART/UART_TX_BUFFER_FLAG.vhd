library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX_BUFFER_FLAG is
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;

        --Mux for hvilken data som går igjennom
        data_in_RX     : in  std_logic_vector(7 downto 0); --Data fra RX
        data_in_button : in  std_logic_vector(7 downto 0); --Predefinert fra CTRL_ButtonPress
        switch         : in  std_logic;                    --Switch velger om man tar fra RX eller button

        --Flaggoperasjoner
        set_flag        : in  std_logic;               --Flag at tx er opptatt
        clr_flag        : in  std_logic;               --TX er ferdig, kan motta igjen
        tx_flag         : out std_logic;               --Indikerer at TX er opptatt, Når TX mottar fra RX, kan RX motta igjen

        data_out        : out std_logic_vector(7 downto 0) --Data fra TX buffer til UART TX
    );
end entity UART_TX_BUFFER_FLAG;

architecture arch_tx_buf_flag of UART_TX_BUFFER_FLAG is

    signal tx_buf_reg     : std_logic_vector(7 downto 0);
    signal tx_buf_next    : std_logic_vector(7 downto 0);

    signal tx_flag_reg, tx_flag_next : std_logic; --Utgangsflagg

    begin
        process(clk, reset)
        begin
        if reset = '1' then
            tx_buf_reg   <= (others => '0');
            tx_flag_reg  <= '0';
        elsif rising_edge(clk) then
            tx_buf_reg   <= tx_buf_next;
            tx_flag_reg  <= tx_flag_next;
        end if;
    end process;

    process(tx_buf_reg, tx_flag_reg, set_flag, clr_flag, data_in_RX, data_in_button, switch)
        begin
        tx_buf_next  <= tx_buf_reg;
        tx_flag_next <= tx_flag_reg;

        --MUX
        if switch = '0' then
            --Velger data fra RX
            if set_flag = '1' then
                tx_buf_next <= data_in_RX; --Sett utgangsdata til RX
                tx_flag_next <= '1'; --Sett flagg høyt
            elsif clr_flag = '1'  then
                tx_flag_next <= '0';
            end if;
        else
            if set_flag = '1' then
                tx_buf_next <= data_in_button;
                tx_flag_next <= '1';
            elsif clr_flag = '1'  then
                tx_flag_next <= '0';
            end if;
        end if;
    end process;
    data_out <= tx_buf_reg;
    tx_flag <= tx_flag_reg;

end architecture arch_tx_buf_flag;

                
                
            