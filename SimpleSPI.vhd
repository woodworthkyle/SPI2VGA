----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:59:37 03/13/2014 
-- Design Name: 
-- Module Name:    SimpleSPI - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SimpleSPI is
GENERIC(
    cpol    : STD_LOGIC := '0';  --spi clock polarity mode
    cpha    : STD_LOGIC := '0';  --spi clock phase mode
    d_width : INTEGER := 8
	 );
	Port(
		sclk         : IN     STD_LOGIC;  --spi clk from master
		reset_n      : IN     STD_LOGIC;  --active low reset
		ss_n         : IN     STD_LOGIC;  --active low slave select
		mosi         : IN     STD_LOGIC;  --master out, slave in
		rx_data      : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0')
	);
end SimpleSPI;

architecture Behavioral of SimpleSPI is
	SIGNAL mode    : STD_LOGIC;	
	SIGNAL clk     : STD_LOGIC;
	SIGNAL bit_cnt : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
	SIGNAL rx_buf  : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
begin
	
	mode <= cpol XOR cpha;  --'1' for modes that write on rising edge
	WITH mode SELECT
		clk <= sclk WHEN '1',
      NOT sclk WHEN OTHERS;
	
	PROCESS(ss_n, clk)
	BEGIN
		IF(ss_n = '1' OR reset_n = '0') THEN                         --this slave is not selected or being reset
			--bit_cnt <= (conv_integer(NOT cpha) => '1', OTHERS => '0'); --reset miso/mosi bit count
			bit_cnt <= (conv_integer(NOT cpha) => '1');
    ELSE                                                         --this slave is selected
      IF(rising_edge(clk)) THEN                                  --new bit on miso/mosi
        bit_cnt <= bit_cnt(d_width-1 DOWNTO 0) & '0';          --shift active bit indicator
      END IF;
    END IF;
	
	IF(reset_n = '0') THEN
      rx_buf <= (OTHERS => '0');
    ELSE
      FOR i IN 0 TO d_width-1 LOOP          
        IF(falling_edge(clk)) THEN
				IF(bit_cnt(i) = '1') THEN
					rx_buf(d_width-1-i) <= mosi;
				END IF;
			END IF;
      END LOOP;
    END IF;
    --fulfill user logic request for receive data
    IF(reset_n = '0') THEN
      rx_data <= (OTHERS => '0');
    ELSIF(ss_n = '0' AND rx_req = '1') THEN  
      rx_data <= rx_buf;
    END IF;
	 end process;

end Behavioral;

