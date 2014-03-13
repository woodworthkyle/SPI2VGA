library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity font_test is
	generic(
		spi_cpol : std_logic := '0';
		spi_cpha : std_logic := '0');
	port(
		ext_clk, reset: in std_logic;
		hsync, vsync: out std_logic;
		rgb: out std_logic_vector(2 downto 0);
		sclk    : IN    STD_LOGIC;  --spi serial clock
		ss_n    : IN    STD_LOGIC;  --spi slave select
		mosi    : IN    STD_LOGIC;  --spi master out, slave in
		miso    : OUT   STD_LOGIC;  --spi master in, slave out
		reset_n : IN    STD_LOGIC;  --active low reset
		--trdy    : BUFFER   STD_LOGIC;  --spi transmit ready
		--scl     : INOUT STD_LOGIC;  --i2c serial clock
		--sda     : INOUT STD_LOGIC; --i2c serial data
		writeEnable : in std_logic_vector(0 downto 0);
		dataOut : out std_logic_vector(23 downto 0)
	);
end font_test;

architecture Behavioral of font_test is
	-- declare spi slave component
	component spi_slave is
		generic(
			cpol    : STD_LOGIC; --spi clock polarity mode
			cpha    : STD_LOGIC; --spi clock phase mode
			d_width : integer);  --data width in bits
		port(
			sclk         : IN     STD_LOGIC;                            --spi clk from master
			reset_n      : IN     STD_LOGIC;                            --active low reset
			ss_n         : IN     STD_LOGIC;                            --active low slave select
			mosi         : IN     STD_LOGIC;                            --master out, slave in
			rx_req       : IN     STD_LOGIC;                            --'1' while busy = '0' moves data to the rx_data output
			st_load_en   : IN     STD_LOGIC;                            --asynchronous load enable
			st_load_trdy : IN     STD_LOGIC;                            --asynchronous trdy load input
			st_load_rrdy : IN     STD_LOGIC;                            --asynchronous rrdy load input
			st_load_roe  : IN     STD_LOGIC;                            --asynchronous roe load input
			tx_load_en   : IN     STD_LOGIC;                            --asynchronous transmit buffer load enable
			tx_load_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0); --asynchronous tx data to load
			trdy         : BUFFER STD_LOGIC := '0';                     --transmit ready bit
			rrdy         : BUFFER STD_LOGIC := '0';                     --receive ready bit
			roe          : BUFFER STD_LOGIC := '0';                     --receive overrun error bit
			rx_data      : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0); --receive register output to logic
			busy         : OUT    STD_LOGIC := '0';                     --busy signal to logic ('1' during transaction)
			miso         : OUT    STD_LOGIC := 'Z');                    --master in, slave out
	end component spi_slave;
	CONSTANT spi_d_width : INTEGER := 24;  --spi data width in bits
	signal   spi_busy    : STD_LOGIC;
	signal   spi_tx_ena  : STD_LOGIC;
	signal   spi_tx_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
	signal   spi_rx_req  : STD_LOGIC;
	-- writeAddr + writeData
	signal   spi_rx_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
	signal   spi_rrdy    : STD_LOGIC;
	signal 	resetSPI : STD_LOGIC;
	signal 	txrdySPI : STD_LOGIC;
	signal 	dumpData : STD_LOGIC_VECTOR(4 downto 0);
	
	
	-- signals for address writing
	--signal writeEnable : std_logic_vector(0 downto 0);
	signal writeAddr : std_logic_vector(11 downto 0);
	signal writeData : std_logic_vector(6 downto 0);
	
	-- vga clock
	component dcm_32_to_50p35
		port(
			clkin_in : in std_logic;          
			clkfx_out : out std_logic;
			clkin_ibufg_out : out std_logic;
			clk0_out : out std_logic
		);
	end component;
	signal clock: std_logic;
	
	signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
	signal video_on, pixel_tick: std_logic;
	signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
begin
	
	--resetSPI <= '1';
	spi_rrdy <= '1';
	spi_rx_req <= '1';
	txrdySPI <= '0';
	
	spi_slave_0:  spi_slave
	GENERIC MAP(cpol => spi_cpol,
					cpha => spi_cpha,
					d_width => spi_d_width)
	PORT MAP(sclk => sclk,
				reset_n => reset_n,
				ss_n => ss_n,
				mosi => mosi,
				rx_req => spi_rx_req,
				st_load_en => '0',
				st_load_trdy => '0',
            st_load_rrdy => '0',
				st_load_roe => '0',
				tx_load_en => spi_tx_ena,
            tx_load_data => spi_tx_data,
				trdy => txrdySPI,
				rrdy => spi_rrdy,
				roe => open,
            rx_data => spi_rx_data,
				busy => spi_busy,
				miso => miso);
     
	
	-- pixel clock
	inst_dcm_32_to_50p35: dcm_32_to_50p35
		port map(
			clkin_in => ext_clk,
			clkfx_out => clock,
			clkin_ibufg_out => open,
			clk0_out => open
		);

	-- VGA signals
	vga_sync_unit: entity work.vga_sync
		port map(
			clock => clock,
			reset => reset,
			hsync => hsync,
			vsync => vsync,
			video_on => video_on,
			pixel_tick => pixel_tick,
			pixel_x => pixel_x,
			pixel_y => pixel_y
		);

	-- font generator
	font_gen_unit: entity work.font_generator
		port map(
			clock => pixel_tick,
			video_on => video_on,
			pixel_x => pixel_x,
			pixel_y => pixel_y,
			rgb_text => rgb_next,
			writeEnable => writeEnable,
			writeAddr => writeAddr,
			writeData => writeData
		);
	
	writeData <= spi_rx_data(6 downto 0);
	dumpData <= spi_rx_data(11 downto 7);
	writeAddr <= spi_rx_data(23 downto 12);
	
	--writeAddr <= spi_rx_data(11 downto 0);
	--writeData <= spi_rx_data(18 downto 12);
	-- Output data to pins
	--dataOut <= spi_rx_data;
	dataOut <= (others => '0');
	
	-- rgb buffer
	process(clock)
	begin
		if clock'event and clock = '1' then
			if pixel_tick = '1' then
				rgb_reg <= rgb_next;
			end if;
		end if;
	end process;
	
	rgb <= rgb_reg;
end Behavioral;
