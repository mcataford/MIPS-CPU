-- ECSE425 CPU Pipeline mark II
--
-- Instruction fetch stage
--
-- Author: Marc Cataford
-- Last modified: 10/4/2017


library IEEE;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IF_STAGE is

		port(
			--INPUT
			--Clock signal
			CLOCK: in std_logic;
			ENABLE: in std_logic;
			--Reset signal
			RESET: in std_logic;
			--PC MUX select signal
			PC_SEL: in std_logic;
			--Feedback from ALU for PC calc.
			ALU_PC: in std_logic_vector(31 downto 0);
			
			--OUTPUT
			--PC output
			PC_OUT: out std_logic_vector(31 downto 0) := (others => 'Z');
			--Fetched instruction
			INSTR: out std_logic_vector(31 downto 0) := (others => 'Z');
			
			CACHE_IN: in std_logic_vector(32 downto 0);
			CACHE_OUT: out std_logic_vector(65 downto 0)
			
		);
	
end entity;

architecture IF_STAGE_Impl of IF_STAGE is

	--Intermediate signals and constants
	
	--Instruction memory addr.
	signal IR_ADDR: integer range 0 to 1023;
	
	--Fetched instruction.
	signal IR_OUT: std_logic_vector(31 downto 0) := (others => '0');
	
	--Memory stall request.
	signal IR_MEMSTALL: std_logic;
	
	--Program counter memory.
	signal PC_REG,PC_INC: std_logic_vector(31 downto 0) := (others => '0');
	
	--Memory read allow
	signal IR_MEMREAD: std_logic := '0';

	--Subcomponent instantiation
	
	--Instruction memory
	
	-- component memory is
	
		-- GENERIC(
		-- ram_size : INTEGER := 8192;
		-- mem_delay : time := 1 ns;
		-- clock_period : time := 1 ns;
		-- from_file : boolean := true;		
		-- file_in : string := "program.txt";
		-- to_file : boolean := false;
		-- file_out : string := "output.txt";
		-- sim_limit : time := 10 ns
	-- );
		-- PORT (
		-- clock: IN STD_LOGIC;
		-- writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		-- address: IN INTEGER RANGE 0 TO ram_size-1;
		-- memwrite: IN STD_LOGIC;
		-- memread: IN STD_LOGIC;
		-- readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		-- waitrequest: OUT STD_LOGIC
	-- );
	
	-- end component;

begin

	-- IR: memory port map(
		-- --INPUT
		-- --Clock signal
		-- CLOCK,
		-- --Data in (DISABLED)
		-- std_logic_vector(to_unsigned(0,32)),
		-- --Data addr.
		-- IR_ADDR,
		-- --Memory write perm. (DISABLED)
		-- '0',
		-- --Memory read perm.
		-- IR_MEMREAD,
		
		-- --OUTPUT
		-- --Data out
		-- IR_OUT,
		-- --Stall signal
		-- IR_MEMSTALL		
	-- );
	
	CACHE_OUT <= (others => '0');
					
	STAGE_BEHAVIOUR: process(CLOCK)
	
	begin
	
	
		if RESET = '1' then
		
			PC_REG <= x"00000000";
	
		elsif falling_edge(CLOCK) and ENABLE = '1' then
		
			if IR_MEMREAD <= '0' then
			
				IR_MEMREAD <= '1';
				
				if PC_SEL = '0' or PC_SEL = 'Z' then
				
					--IR_ADDR <= to_integer(unsigned(PC_REG));
					CACHE_OUT(65 downto 34) <= PC_REG;
					PC_INC <= std_logic_vector(unsigned(PC_REG)+1);
					
				else
				
					--IR_ADDR <= to_integer(unsigned(ALU_PC));
					CACHE_OUT(65 downto 34) <= ALU_PC;
					PC_INC <= std_logic_vector(unsigned(ALU_PC)+1);
					
					report "Yes.";
				
				end if;
				
			end if;
			
		elsif rising_edge(CLOCK) and ENABLE = '1' then
		
			--if IR_MEMSTALL = '0' then
			if CACHE_IN(0) = '0' then
			
				IR_MEMREAD <= '0';
				CACHE_OUT(1) <= '0';
				INSTR <= IR_OUT;
				PC_OUT <= PC_INC;
				PC_REG <= PC_INC;
			
			end if;
		elsif rising_edge(ENABLE) then
				
				IR_MEMREAD <= '0';
				
		end if;
	
	end process;
	
end architecture;