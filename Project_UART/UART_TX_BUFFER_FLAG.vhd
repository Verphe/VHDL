--Det er tatt inspirasjon fra en kodepresentasjon fra
--Electrical and Computer Engineering Department, University of New Mexico
--https://ece-research.unm.edu/jimp/vhdl_fpgas/slides/UART.pdf

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX_BUFFER_FLAG is
    generic (
        DATABITS : integer := 8 --Antall databit
    );
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;

        data_in         : in  std_logic_vector(DATABITS-1 downto 0); --Data fra CTRL (Enten buttonpress eller loopback)
        data_out        : out std_logic_vector(DATABITS-1 downto 0); --Data fra TX buffer til UART TX

        --Flaggoperasjoner
        set_flag        : in  std_logic;               --Flag at tx er opptatt
        clr_flag        : in  std_logic;               --TX er ferdig, kan motta igjen
        tx_flag         : out std_logic               --Indikerer at TX er opptatt, når TX mottar fra RX, kan RX motta igjen
    );
end entity UART_TX_BUFFER_FLAG;

architecture arch_tx_buf_flag of UART_TX_BUFFER_FLAG is

    signal tx_buf_reg  : std_logic_vector(DATABITS-1 downto 0);
    signal tx_flag_reg : std_logic;

    begin

    process(clk, reset)
    begin
        if reset = '1' then
            tx_buf_reg  <= (others => '0');
            tx_flag_reg <= '0';
        elsif rising_edge(clk) then
            if set_flag = '1' then
                tx_buf_reg  <= data_in;
                tx_flag_reg <= '1';
            elsif clr_flag = '1' then
                tx_flag_reg <= '0';
            end if;
        end if;
    end process;

    -- Outputs
    data_out <= tx_buf_reg;
    tx_flag  <= tx_flag_reg;

end architecture arch_tx_buf_flag;

                
                
            