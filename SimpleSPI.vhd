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
	Port(
		clk : in std_logic;
		sclk : in std_logic;
		mosi : in std_logic;
		miso : out std_logic;
		ssel : in std_logic;
		data_rx : out std_logic_vector(7 downto 0);
		byte_rx : out std_logic
	);
end SimpleSPI;

architecture Behavioral of SimpleSPI is
	
	signal sclk_reg : std_logic_vector(2 downto 0);
	signal sclk_rise : std_logic;
	signal sclk_fall : std_logic;
	
	signal ssel_reg : std_logic_vector(2 downto 0);
	signal ssel_active : std_logic;
	signal ssel_start : std_logic;
	signal ssel_end : std_logic;
	
	signal mosi_reg : std_logic_vector(1 downto 0);
	signal mosi_data : std_logic;
	
	signal bitcnt : std_logic_vector(3 downto 0);
	signal byte_rx_reg : std_logic;
	signal data_reg : std_logic_vector(7 downto 0);
	
	
	
begin
	
	process(clk, sclk_reg, ssel_reg, mosi_reg)
	begin
		if rising_edge(clk) then
			sclk_reg <= sclk_reg(1 downto 0)&sclk;
			ssel_reg <= ssel_reg(1 downto 0)&ssel;
			mosi_reg <= mosi_reg(0)&mosi;
		end if;
		
		if sclk_reg(2 downto 1) = "01" then
			sclk_rise <= '1';
		else
			sclk_rise <= '0';
		end if;
		
		if sclk_reg(2 downto 1) = "10" then
			sclk_fall <= '1';
		else
			sclk_fall <= '0';
		end if;
		
		ssel_active <= not ssel_reg(1);
		
		if ssel_reg(2 downto 1) = "10" then
			ssel_start <= '1';
		else
			ssel_start <= '0';
		end if;
		
		if ssel_reg(2 downto 1) = "01" then
			ssel_end <= '1';
		else
			ssel_end <= '0';
		end if;
		
		mosi_data <= mosi_reg(1);
		
	end process;
	
	
	process(clk)
	begin
		if rising_edge(clk) then
			if((not ssel_active) = '1') then
				bitcnt <= "0000";
				data_reg <= "00000000";
				data_rx <= "00000000";
			elsif (sclk_rise = '1') then
				bitcnt <= unsigned(bitcnt)+1;
				data_reg <= data_reg(6 downto 0)&mosi_data;
			end if;
			
			--if (ssel_active='1') and (sclk_rise='1') and (bitcnt = "111") then
			if (bitcnt = "1000") then
				byte_rx_reg <= '1';
				data_rx <= data_reg;
				bitcnt <= "0000";
			else
				byte_rx_reg <= '0';
			end if;
			
			
		end if;
	end process;
	
	byte_rx <= byte_rx_reg;
	
end Behavioral;

