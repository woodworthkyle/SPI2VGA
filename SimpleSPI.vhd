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
		miso : OUT STD_LOGIC;
		rx_data      : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
		rx_complete : out std_logic
	);
end SimpleSPI;

architecture Behavioral of SimpleSPI is
	SIGNAL mode    : STD_LOGIC;	
	SIGNAL clk     : STD_LOGIC;
	SIGNAL bit_cnt : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '1');
	SIGNAL rx_buf  : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL tmpCount : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal rxrdy : std_logic;
begin
	
	mode <= cpol XOR cpha;  --'1' for modes that write on rising edge
	WITH mode SELECT
		clk <= sclk WHEN '1',
      NOT sclk WHEN OTHERS;
	
	PROCESS(ss_n, clk, reset_n, tmpCount)
	BEGIN
	
		IF(reset_n = '0') THEN
			rx_buf <= (OTHERS => '0');
		ELSE
			if(falling_edge(clk)) then
				rx_buf(0) <= mosi;
				FOR i IN 1 to d_width-1 LOOP
					rx_buf(i) <= rx_buf(i-1);
				
				END LOOP;
				tmpCount <= unsigned(tmpCount) + '1';
			end if;
			
			if(tmpCount > "00110001") then
				rxrdy <= '1';
				tmpCount <= (others => '0');
			else
				rxrdy <= '0';
			end if;
			
		END IF;
    --fulfill user logic request for receive data
		IF(reset_n = '0') THEN
			rx_data <= (OTHERS => '0');
		ELSIF(ss_n = '0' and rxrdy = '1') THEN  
			rx_data <= rx_buf;
		END IF;
		
	end process;
	
	rx_complete <= rxrdy;

end Behavioral;

