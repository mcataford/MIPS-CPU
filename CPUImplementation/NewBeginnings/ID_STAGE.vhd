library IEEE;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ID_STAGE is
	
	port(
		--INPUT
		--Clock signal
		CLOCK: in std_logic;
		--Program counter
		PC: in integer range 0 to 1023;
		--Instruction
		INSTR: in std_logic_vector(31 downto 0);
		--Writeback source
		WB_SRC: in std_logic;
		--Writeback data
		WB_DATA: in std_logic_vector(31 downto 0);
		
		--OUTPUT
		--Register A
		REG_A: out integer;
		--Register B
		REG_B: out integer;
		--Sign-extended immediate
		IMMEDIATE: out integer;
		--Control signals
		CONTROL_VECTOR: out std_logic_vector(6 downto 0);
		--ALU control signals
		ALU_CONTROL_VECTOR: out std_logic_vector(6 downto 0)
	);
	
end entity;

architecture ID_STAGE_Impl of ID_STAGE is

	--Intermediate signals and constants
	
	constant REG_COUNT_MAX: integer := 32;
	
	--Register file
	type REGISTER_FILE is array (REG_COUNT_MAX-1 downto 0) of integer;
	signal REG: REGISTER_FILE;
	
	--Instruction parsing
	signal RS,RT,RD,SHAMT: std_logic_vector(4 downto 0);
	signal OPCODE,FUNCT: std_logic_vector(5 downto )0;
	signal IMM: std_logic_vector(15 downto 0);
	signal ADDR: std_logic_vector(25 downto 0);

begin

	STAGE_BEHAVIOUR: process(PC)
	
	begin
		
		--Parsing the instruction word.
		OPCODE <= INSTR(31 downto 26);
		RS <= INSTR(25 downto 21);
		RT <= INSTR(20 downto 16);
		RD <= INSTR(15 downto 11);
		SHAMT <= INSTR(10 downto 6);
		FUNCT <= INSTR(5 downto 0);
		IMM <= INSTR(15 downto 0);
		ADDR <= INSTR(25 downto 0);
		
		
		
		
	
	end process;
	
	REGISTER_FILE_INIT: process
	
	begin
	
		if now < 1ps then
		
			for idx in REG_COUNT_MAX-1 downto 0 loop
			
				REG(idx) <= 0;
				
			end loop;
			
		end if;
		
		wait;
	
	end process;

end architecture;