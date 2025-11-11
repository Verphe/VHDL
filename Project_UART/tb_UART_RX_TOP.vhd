library ieee;
use ieee.std_logic_1164.all;

entity tb_uart_rx_top is
end tb_uart_rx_top;

architecture sim of tb_uart_rx_top is
  -- Clock and UART timing
  constant CLK_PERIOD       : time    := 20 ns;  -- 50 MHz
  constant BAUD_TICK_COUNT  : integer := 651;    -- same M as mod_m_counter
  constant OVERSAMPLE       : integer := 8;      -- 8x sampling
  constant BIT_PERIOD       : time    := CLK_PERIOD * BAUD_TICK_COUNT * OVERSAMPLE;

  -- DUT signals
  signal clk        : std_logic := '0';
  signal reset      : std_logic := '1';
  signal rx         : std_logic := '1';  -- idle is high
  signal data_out   : std_logic_vector(7 downto 0);
  signal data_rdy : std_logic;

  -- procedure to send a UART byte (8N1, LSB first)
  procedure send_byte(
    signal rx_s : out std_logic;
    constant b  : in  std_logic_vector(7 downto 0)
) is
  begin
    -- start bit (low)
    rx_s <= '0';
    wait for BIT_PERIOD;

    -- 8 data bits, LSB first
    for i in 0 to 7 loop
      rx_s <= b(i);
      wait for BIT_PERIOD;
    end loop;

    -- stop bit (high)
    rx_s <= '1';
    wait for BIT_PERIOD;
  end procedure;

begin
  ---------------------------------------------------------------------------
  -- Instantiate DUT (uart_rx_top)
  ---------------------------------------------------------------------------
  dut : entity work.uart_rx_top
    port map (
      clk        => clk,
      reset      => reset,
      rx         => rx,
      data_out   => data_out,
      data_rdy   => data_rdy
    );

  ---------------------------------------------------------------------------
  -- Clock generation: 50 MHz
  ---------------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  ---------------------------------------------------------------------------
  -- Stimulus
  ---------------------------------------------------------------------------
  stim_process : process
  begin
    -- Initial conditions
    rx    <= '1';  -- idle
    reset <= '1';
    wait for 10 * CLK_PERIOD;  -- hold reset a bit

    reset <= '0';
    wait for BIT_PERIOD;       -- let the receiver settle

    -- Send first byte: 0x55 = "01010101"
    send_byte(rx, x"55");
    -- Wait some time after first frame
    wait for 5 * BIT_PERIOD;

    -- Send second byte: 0xA3 = "10100011"
    send_byte(rx, x"A3");
    wait for 10 * BIT_PERIOD;

    -- End simulation
    wait;
  end process;

end sim;
