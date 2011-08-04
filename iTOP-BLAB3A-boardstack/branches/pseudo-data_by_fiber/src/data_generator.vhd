-- 2011-06-29 kurtis
-- 2011-07-18 modified by mza
-- 2011-08-04 modified by mza
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data_generator is
	generic (
		CURRENT_PROTOCOL_FREEZE_DATE : std_logic_vector(31 downto 0) := x"20110718"
	);
	port (
		ENABLE                        : in    STD_LOGIC;
		TRIGGER                       : in    STD_LOGIC;
		TRIGGER_ACK                   :   out STD_LOGIC;
		TX_DST_RDY_N                  : in    STD_LOGIC;
		FIFO_EMPTY                    : in    STD_LOGIC;
		FIFO_DATA_VALID               : in    STD_LOGIC;
		USER_CLK                      : in    STD_LOGIC;
		DATA_TO_FIFO                  :   out STD_LOGIC_VECTOR (31 downto 0);
		WRITE_DATA_TO_FIFO_ENABLE     :   out STD_LOGIC;
		TX_SRC_RDY_N                  :   out STD_LOGIC;
		READ_FROM_FIFO_ENABLE         :   out STD_LOGIC;
		DATA_GENERATOR_STATE          :   out STD_LOGIC_VECTOR(2 downto 0);
		VARIABLE_DELAY_BETWEEN_EVENTS : in    STD_LOGIC_VECTOR(31 downto 0)
	);
end data_generator;

architecture Behavioral of data_generator is
	type STATE_TYPE is (IDLE, MAKE_DATA_READY_FOR_FIFO, CLOCK_DATA_INTO_FIFO, PAUSE_BEFORE_SENDING, SEND_DATA, ACKNOWLEDGE_TRIGGER, DELAY_BETWEEN_EVENTS);
	signal internal_STATE 						: STATE_TYPE;
	signal internal_ENABLE 						: std_logic;
	signal internal_TX_DST_RDY_N 				: std_logic;
	signal internal_DATA_TO_FIFO				: std_logic_vector(31 downto 0) := (others => '0');
	signal internal_WRITE_DATA_TO_FIFO_ENABLE	: std_logic := '0';
	signal internal_TX_SRC_RDY_N				: std_logic := '0';
	signal internal_CHECKSUM					: std_logic_vector(31 downto 0) := (others => '0');
	signal internal_READ_FROM_FIFO_ENABLE	: std_logic := '0';
	signal internal_DATA_GENERATOR_STATE	: std_logic_vector(2 downto 0) := "000";
	signal internal_FIFO_EMPTY					: std_logic;
	signal internal_FIFO_DATA_VALID 			: std_logic;
	signal internal_VARIABLE_DELAY_BETWEEN_EVENTS : std_logic_vector(31 downto 0);
	signal internal_TRIGGER                : std_logic;
	signal internal_TRIGGER_ACK            : std_logic;
begin
	internal_ENABLE 				<= ENABLE;
	internal_TX_DST_RDY_N 		<= TX_DST_RDY_N;
	DATA_TO_FIFO 					<= internal_DATA_TO_FIFO;
	WRITE_DATA_TO_FIFO_ENABLE	<= internal_WRITE_DATA_TO_FIFO_ENABLE;
	TX_SRC_RDY_N 					<= internal_TX_SRC_RDY_N;
	READ_FROM_FIFO_ENABLE		<= internal_READ_FROM_FIFO_ENABLE;
	DATA_GENERATOR_STATE			<= internal_DATA_GENERATOR_STATE;
	internal_FIFO_EMPTY			<= FIFO_EMPTY;
	internal_FIFO_DATA_VALID	<= FIFO_DATA_VALID;
	internal_VARIABLE_DELAY_BETWEEN_EVENTS <= VARIABLE_DELAY_BETWEEN_EVENTS;
	internal_TRIGGER           <= TRIGGER;
	TRIGGER_ACK                <= internal_TRIGGER_ACK;

	process(USER_CLK) 
		variable word_number 	: integer range 0 to 139 := 0;
		variable packet_number 	: integer range 0 to 129 := 0;
		variable delay_counter 	: unsigned(31 downto 0) := (others => '0');
	begin
		if (falling_edge(USER_CLK)) then
			case internal_STATE is
				when IDLE =>
					internal_DATA_GENERATOR_STATE <= "000";
					internal_TX_SRC_RDY_N <= '1';				
					internal_READ_FROM_FIFO_ENABLE <= '0';
					internal_TRIGGER_ACK <= '0';
					if (internal_ENABLE = '1' and internal_TRIGGER = '1') then
						word_number := 0;
						internal_CHECKSUM <= (others => '0');
						internal_STATE <= MAKE_DATA_READY_FOR_FIFO;
					end if;
				when MAKE_DATA_READY_FOR_FIFO =>
					internal_DATA_GENERATOR_STATE <= "001";				
					internal_WRITE_DATA_TO_FIFO_ENABLE <= '0';				
					internal_STATE <= CLOCK_DATA_INTO_FIFO;					
					if (word_number = 0) then
						internal_DATA_TO_FIFO <= x"00BE11E2"; -- header (similar to "Belle2" in hexadecimal)
					elsif (word_number = 1) then
						internal_DATA_TO_FIFO <= x"0000008C"; -- packet size in words
					elsif (word_number = 2) then
						internal_DATA_TO_FIFO <= CURRENT_PROTOCOL_FREEZE_DATE; -- protocol freeze date (YYYYMMDD in BCD)
					elsif (word_number = 3) then
						internal_DATA_TO_FIFO <= x"00C0FFEE"; -- packet type (similar to "coffee" in hexadecimal)
					elsif (word_number >= 4 and word_number <= 136) then
						internal_DATA_TO_FIFO <= std_logic_vector(to_unsigned(word_number,16)) & x"BEEF"; -- pseudo-data
					elsif (word_number = 137) then
						internal_DATA_TO_FIFO <= x"0001" & x"0000"; -- SCROD revision and ID (0 means all SCRODs)
					elsif (word_number = 138) then
						internal_DATA_TO_FIFO <= std_logic_vector(unsigned(internal_CHECKSUM) + x"62504944"); -- 32 bit checksum, including header+footer, but not self
					elsif (word_number = 139) then
						internal_DATA_TO_FIFO <= x"62504944"; -- footer ("bPID" in ASCII)
					else
						internal_DATA_TO_FIFO <= x"45534446";
					end if;
				when CLOCK_DATA_INTO_FIFO => 
					internal_DATA_GENERATOR_STATE <= "010";				
					internal_WRITE_DATA_TO_FIFO_ENABLE <= '1';
					internal_CHECKSUM <= std_logic_vector(unsigned(internal_CHECKSUM) + unsigned(internal_DATA_TO_FIFO));
					if (word_number = 139) then
						internal_STATE <= PAUSE_BEFORE_SENDING;
					else
						word_number := word_number + 1;
						internal_STATE <= MAKE_DATA_READY_FOR_FIFO;
					end if;
				when PAUSE_BEFORE_SENDING => 
					internal_DATA_GENERATOR_STATE <= "011";
					internal_WRITE_DATA_TO_FIFO_ENABLE <= '0';
					internal_STATE <= SEND_DATA;
				when SEND_DATA =>
					internal_DATA_GENERATOR_STATE <= "100";
--					internal_READ_FROM_FIFO_ENABLE <= internal_FIFO_DATA_VALID and not(internal_TX_DST_RDY_N);
--					internal_TX_SRC_RDY_N <= not(internal_FIFO_DATA_VALID and not(internal_TX_DST_RDY_N));
					internal_READ_FROM_FIFO_ENABLE <= not(internal_TX_DST_RDY_N); -- tell the fifo whether Aurora is accepting data
					internal_TX_SRC_RDY_N <= internal_TX_DST_RDY_N; -- no sense in trying to send if the other side is not listening
					if (internal_FIFO_EMPTY = '1') then
						internal_TX_SRC_RDY_N <= '1';
						if (packet_number = 129) then
							internal_STATE <= ACKNOWLEDGE_TRIGGER;
						else
							packet_number := packet_number + 1;
							internal_STATE <= IDLE;							
						end if;
					end if;
				when ACKNOWLEDGE_TRIGGER =>
					internal_TRIGGER_ACK <= '1';
					internal_STATE <= DELAY_BETWEEN_EVENTS;
				when DELAY_BETWEEN_EVENTS =>
					internal_TRIGGER_ACK <= '0';
					internal_DATA_GENERATOR_STATE <= "101";
					internal_READ_FROM_FIFO_ENABLE <= '0';
					if (delay_counter < unsigned(internal_VARIABLE_DELAY_BETWEEN_EVENTS)) then
						delay_counter := delay_counter + 1;
					else
						delay_counter := (others => '0');
						packet_number := 0;
						internal_STATE <= IDLE;
					end if;
				when others =>
					internal_DATA_GENERATOR_STATE <= "110";				
					internal_STATE <= IDLE;
			end case;
		end if;
	end process;
end Behavioral;
