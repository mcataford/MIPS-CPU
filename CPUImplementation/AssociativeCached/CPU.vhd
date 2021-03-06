library IEEE;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CPU is
	port(
		CLOCK: in std_logic;
		RESET: in std_logic
	);
	
end entity;

architecture CPU_Impl of CPU is

	--Intermediate signals and constants
	
	--CPU constants
	constant PC_MAX: integer := 1024;
	constant REG_COUNT: integer := 32;
	
	--IF stage specific
	signal IF_PC_RESET, IF_PC_SELECT: std_logic := '0';
	signal IF_PC_ALU, IF_PC: std_logic_vector(31 downto 0) := (others => '0');
	signal IF_INSTR: std_logic_vector(31 downto 0) := (others => 'Z');
	
	--ID stage specific
	signal ID_PC: std_logic_vector(31 downto 0) := (others => '0');
	signal ID_REG_A,ID_REG_B,ID_IMMEDIATE,ID_WB_DATA: std_logic_vector(31 downto 0) := (others => '0');
	signal ID_INSTR: std_logic_vector(31 downto 0) := (others => 'Z');
	signal ID_WB_SRC: std_logic_vector(31 downto 0) := (others => '0');
	signal ID_CONTROL_VECTOR: std_logic_vector(11 downto 0) := (others => '0');
	signal ID_REGWRITE: std_logic;

	--EX stage specific
	signal EX_PC: std_logic_vector(31 downto 0) := (others => '0');
	signal EX_REG_A,EX_REG_B,EX_IMMEDIATE: std_logic_vector(31 downto 0) := (others => '0');
	signal EX_INSTR: std_logic_vector(31 downto 0) := (others => 'Z');
	signal EX_CONTROL_VECTOR: std_logic_vector(11 downto 0) := (others => '0');
	signal EX_R: std_logic_vector(63 downto 0) := (others => '0');
	signal EX_BRANCH: std_logic := '0';
	
	signal MUX_SEL_A, MUX_SEL_B : std_logic_vector(1 downto 0);
	signal MUX_OUT_A, MUX_OUT_B : std_logic_vector(31 downto 0);
	
	--MEM stage specific
	signal MEM_PC: std_logic_vector(31 downto 0) := (others => '0');
	signal MEM_R: std_logic_vector(63 downto 0) := (others => '0');
	signal MEM_INSTR: std_logic_vector(31 downto 0) := (others => '0');
	signal MEM_B_FW: std_logic_vector(31 downto 0) := (others => '0');
	signal MEM_CONTROL_VECTOR: std_logic_vector(11 downto 0) :=(others => '0');
	signal MEM_DATAREAD: std_logic_vector(31 downto 0) := (others => '0');
	
	--WB stage specific
	signal WB_DATA: std_logic_vector(31 downto 0) := (others => '0');
	signal WB_ADDR: std_logic_vector(63 downto 0) := (others => '0');
	signal WB_INSTR: std_logic_vector(31 downto 0) := (others => '0');
	signal WB_CONTROL_VECTOR: std_logic_vector(11 downto 0) := (others => '0');
	
	signal HI,LO: std_logic_vector(31 downto 0) := (others => '0');
	signal BRANCH_SEL: std_logic := '0';
	
	--Main memory
	signal MAIN_MEM_WRITEDATA, MAIN_MEM_READDATA: std_logic_vector(31 downto 0) := (others => '0');
	signal MAIN_MEM_ADDR: integer := 0;
	signal MAIN_MEM_MEMWRITE, MAIN_MEM_MEMREAD, MAIN_MEM_MEMSTALL: std_logic := '0';
	
	--Unified cache
	signal CACHE_WRITEDATA, CACHE_READDATA, CACHE_ADDR: std_logic_vector(31 downto 0) := (others => '0');
	signal CACHE_MEMWRITE, CACHE_MEMREAD, CACHE_MEMSTALL: std_logic := '0';
	
	--Cache interactions
	signal IF_CACHE_IN, MEM_CACHE_IN: std_logic_vector(32 downto 0);
	signal MEM_CACHE_OUT, IF_CACHE_OUT: std_logic_vector(65 downto 0);

	signal ENABLE: std_logic:= '1';
	
	--Stage components
	
	component IF_STAGE
	
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
			PC_OUT: out std_logic_vector(31 downto 0);
			--Fetched instruction
			INSTR: out std_logic_vector(31 downto 0);
			CACHE_IN: in std_logic_vector(32 downto 0);
			CACHE_OUT: out std_logic_vector(65 downto 0)
		);
	
	end component;
	
	component ID_STAGE
	
		port(
			--INPUT
			--Clock signal
			CLOCK: in std_logic;
			--Instruction
			INSTR: in std_logic_vector(31 downto 0);
			--Writeback source
			WB_SRC: in std_logic_vector(31 downto 0);
			--Writeback data
			WB_DATA: in std_logic_vector(31 downto 0);
			REGWRITE: in std_logic;
			RA_WRITE: in std_logic_vector(31 downto 0);
			
			--OUTPUT
			--Register A
			REG_A: out std_logic_vector(31 downto 0) := (others => '0');
			--Register B
			REG_B: out std_logic_vector(31 downto 0) := (others => '0');
			--Sign-extended immediate
			IMMEDIATE: out std_logic_vector(31 downto 0) := (others => '0');
			--Control signals
			CONTROL_VECTOR: out std_logic_vector(11 downto 0)
		);
	
	end component;
	
	component EX_STAGE
	
		port (
			--INPUT
			--Program counter
			PC: in std_logic_vector(31 downto 0) := (others => '0');
			--Operands
			A: in std_logic_vector(31 downto 0) := (others => '0');
			B: in std_logic_vector(31 downto 0) := (others => '0');
			Imm: in std_logic_vector(31 downto 0) := (others => '0');
			--Control signals
			CONTROL_VECTOR: in std_logic_vector(11 downto 0);
			--Instruction
			INSTR: in std_logic_vector(31 downto 0);
			
			--OUTPUT
			--Results
			R: out std_logic_vector(63 downto 0) := (others => '0');
			BRANCH: out std_logic := '0'
		);
	
	end component;
	
	component MEM_STAGE
	
		port(
			--INPUT
			--Clock
			CLOCK: in std_logic;
			--Reset
			RESET: in std_logic;
			--Control signals
			CONTROL_VECTOR: in std_logic_vector(11 downto 0);
			--Results from ALU
			DATA_ADDRESS: in std_logic_vector(63 downto 0);
			--B fwd
			DATA_PAYLOAD: in std_logic_vector(31 downto 0);
			
			--OUTPUT
			DATA_OUT: out std_logic_vector(31 downto 0);
			CACHE_IN: in std_logic_vector(32 downto 0);
			CACHE_OUT: out std_logic_vector(65 downto 0)
		);
	
	end component;
	
	--Interstage registers
	
	component IF_ID_REG
	
		port(
			--INPUT
			--Clock signal
			CLOCK: in std_logic;
			ENABLE: in std_logic;
			--Reset
			RESET: in std_logic;
			--Program counter
			IF_PC: in std_logic_vector(31 downto 0);
			--Instruction
			IF_INSTR: in std_logic_vector(31 downto 0);
			
			--OUTPUT
			--Program counter
			ID_PC: out std_logic_vector(31 downto 0) := (others => '0');
			--Instruction
			ID_INSTR: out std_logic_vector(31 downto 0)
		);
	end component;
	
	component ID_EX_REG
	
		port(
			--INPUT
			--Clock signal
			CLOCK: in std_logic;
			ENABLE: in std_logic;
			--Reset
			RESET: in std_logic;
			--Program counter
			ID_PC: in std_logic_vector(31 downto 0);
			--Instruction
			ID_INSTR: in std_logic_vector(31 downto 0);
			--Register values
			ID_REG_A: in std_logic_vector(31 downto 0);
			ID_REG_B: in std_logic_vector(31 downto 0);
			--Immediate
			ID_IMMEDIATE: in std_logic_vector(31 downto 0);
			--Control signals
			ID_CONTROL_VECTOR: in std_logic_vector(11 downto 0);
			
			--OUTPUT
			EX_PC: out std_logic_vector(31 downto 0);
			--Instruction
			EX_INSTR: out std_logic_vector(31 downto 0);
			--Register values
			EX_REG_A: out std_logic_vector(31 downto 0);
			EX_REG_B: out std_logic_vector(31 downto 0);
			--Immediate
			EX_IMMEDIATE: out std_logic_vector(31 downto 0);
			--Control signals
			EX_CONTROL_VECTOR: out std_logic_vector(11 downto 0)
		);
	
	end component;
	
	component EX_MEM_REG
	
		port(
			--INPUT
			--Clock signal
			CLOCK: in std_logic;
			ENABLE: in std_logic;
			RESET: in std_logic;
			EX_PC: in std_logic_vector(31 downto 0);
			--Results
			EX_R: in std_logic_vector(63 downto 0);
			--Operand B forwarding
			EX_B_FW: in std_logic_vector(31 downto 0) := (others => '0');
			--Instruction
			EX_INSTR: in std_logic_vector(31 downto 0);
			--Control signals
			EX_CONTROL_VECTOR: in std_logic_vector(11 downto 0);
			
			--OUTPUT
			MEM_PC: out std_logic_vector(31 downto 0);
			--Results
			MEM_R: out std_logic_vector(63 downto 0);
			--Operand B forwarding
			MEM_B_FW: out std_logic_vector(31 downto 0);
			--Instruction
			MEM_INSTR: out std_logic_vector(31 downto 0);
			--Control signals
			MEM_CONTROL_VECTOR: out std_logic_vector(11 downto 0)
		);
	
	end component;
	
	component MEM_WB_REG
	
		port(
			--INPUT
			--Clock signal
			CLOCK: in std_logic;
			ENABLE: in std_logic;
			--Reset
			RESET: in std_logic;
			--PC
			MEM_DATA: in std_logic_vector(31 downto 0);
			MEM_ADDR: in std_logic_vector(63 downto 0);
			MEM_INSTR: in std_logic_vector(31 downto 0);
			MEM_CONTROL_VECTOR: in std_logic_vector(11 downto 0);
			
			WB_DATA: out std_logic_vector(31 downto 0);
			WB_ADDR: out std_logic_vector(63 downto 0);
			WB_INSTR: out std_logic_vector(31 downto 0);
			WB_CONTROL_VECTOR: out std_logic_vector(11 downto 0)
		);
	
	end component;
	
	component MEMORY
	
	GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns;
		from_file : boolean := true;
		file_in : string := "program.txt";
		to_file : boolean := true;
		file_out : string := "output.txt";
		sim_limit : time := 10000 ns
	);

	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO (ram_size/4)-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
	
	end component;
	
	component CACHE
		generic(
			ram_size : INTEGER := 32768
		);
		port(
			clock : in std_logic;
			reset : in std_logic;
			
			-- Avalon interface --
			s_addr : in std_logic_vector (31 downto 0);
			s_read : in std_logic;
			s_readdata : out std_logic_vector (31 downto 0);
			s_write : in std_logic;
			s_writedata : in std_logic_vector (31 downto 0);
			s_waitrequest : out std_logic; 
				
			m_addr : out integer range 0 to ram_size-1;
			m_read : out std_logic;
			m_readdata : in std_logic_vector (31 downto 0);
			m_write : out std_logic;
			m_writedata : out std_logic_vector (31 downto 0);
			m_waitrequest : in std_logic
		);
	end component;
	
		component CACHE_ARBITER
	
	    port(
        --Input Pipeline
        CLOCK : in std_logic;
        IF_ADDRESS, MEM_ADDRESS : in std_logic_vector(31 downto 0);
        IF_DATA_IN,MEM_DATA_IN : in std_logic_vector(31 downto 0);
				IF_RD: in std_logic;
        IF_WR : in std_logic;
				MEM_RD: in std_logic;
				MEM_WR: in std_logic;

        --Input Memory
        WAITREQUEST : in std_logic;

        --Output
        ENABLE : out std_logic;
				IF_DATA_OUT, MEM_DATA_OUT: out std_logic_vector(31 downto 0);
				
				CACHE_ADDR,CACHE_WRITEDATA: out std_logic_vector(31 downto 0);
				CACHE_WRITE,CACHE_READ: out std_logic;
				CACHE_READDATA: in std_logic_vector(31 downto 0)

    );
		
	end component;

begin

	--Stages and registers, in order.

	IF_ST: IF_STAGE port map(
		--INPUT
		--Clock signal
		CLOCK,
		ENABLE,
		--PC reset signal
		RESET,
		--PC output selection
		BRANCH_SEL,
		
		--Alt. PC from the ALU
		EX_R(31 downto 0),
		
		--OUTPUT
		--PC output
		IF_PC,
		--Fetched instruction
		IF_INSTR,
		IF_CACHE_IN,
		IF_CACHE_OUT
	);
	
	IF_ID_R: IF_ID_REG port map(
		--INPUT
		--Clock signal
		CLOCK,
		ENABLE,
		--Reset
		RESET,
		--Program counter
		IF_PC,
		--Instruction
		IF_INSTR,
		
		--OUTPUT
		--Program counter
		ID_PC,
		--Instruction
		ID_INSTR
	);
	
	ID_ST: ID_STAGE port map(
		--INPUT
		--Clock signal
		CLOCK,
		--Instruction
		ID_INSTR,
		--Writeback source
		ID_WB_SRC,
		--Writeback data
		ID_WB_DATA,
		WB_CONTROL_VECTOR(3),
		EX_PC,
		
		--OUTPUT
		--Register A
		ID_REG_A,
		--Register B
		ID_REG_B,
		--Sign-extended immediate
		ID_IMMEDIATE,
		--Control signals
		ID_CONTROL_VECTOR
	);
	
	ID_EX_R: ID_EX_REG port map(
		--INPUT
		--Clock signal
		CLOCK,
		ENABLE,
		--Reset
		RESET,
		--Program counter
		ID_PC,
		--Instruction
		ID_INSTR,
		--Register values
		ID_REG_A,
		ID_REG_B,
		--Immediate
		ID_IMMEDIATE,
		--Control signals
		ID_CONTROL_VECTOR,
		
		--OUTPUT
		--Program counter
		EX_PC,
		--Instruction
		EX_INSTR,
		--Register values
		EX_REG_A,
		EX_REG_B,
		--Immediate
		EX_IMMEDIATE,
		--Control signals
		EX_CONTROL_VECTOR
	);

	EX_ST: EX_STAGE port map(
		--INPUT
		--Program counter
		EX_PC,
		--Operands
		EX_REG_A,
		EX_REG_B,

		EX_IMMEDIATE,
		--Control signals
		EX_CONTROL_VECTOR,
		--Instruction
		EX_INSTR,
		
		--OUTPUT
		--Results
		EX_R,
		EX_BRANCH
	);
	
	EX_MEM_R: EX_MEM_REG port map(
		--INPUT
		--Clock signal
		CLOCK,
		ENABLE,
		RESET,
		EX_PC,
		--Results
		EX_R,
		--Operand B forwarding
		EX_REG_B,
		--Instruction
		EX_INSTR,
		--Control signals
		EX_CONTROL_VECTOR,
		
		--OUTPUT
		MEM_PC,
		--Results
		MEM_R,
		--Operand B forwarding
		MEM_B_FW,
		--Instruction
		MEM_INSTR,
		--Control signals
		MEM_CONTROL_VECTOR
	
	);
	
	MEM_ST: MEM_STAGE port map(
		--INPUT
		--Clock
		CLOCK,
		--Reset
		RESET,
		--Control signals
		MEM_CONTROL_VECTOR,
		--Results from ALU
		MEM_R,
		--B fwd
		MEM_B_FW,
		
		--OUTPUT
		MEM_DATAREAD,
		IF_CACHE_IN,
		IF_CACHE_OUT
	);
	
	MEM_WB_R: MEM_WB_REG port map(
		--INPUT
		--Clock signal
		CLOCK,
		ENABLE,
		--Reset
		RESET,
		--PC
		MEM_DATAREAD,
		MEM_R,
		MEM_INSTR,
		MEM_CONTROL_VECTOR,
		
		WB_DATA,
		WB_ADDR,
		WB_INSTR,
		WB_CONTROL_VECTOR
	);
	
	MAIN_MEMORY: MEMORY port map(
		CLOCK,
		MAIN_MEM_WRITEDATA,
		MAIN_MEM_ADDR,
		MAIN_MEM_MEMWRITE,
		MAIN_MEM_MEMREAD,
		MAIN_MEM_READDATA,
		MAIN_MEM_MEMSTALL
	);
	
	UNIFIED_CACHE: CACHE port map(
		CLOCK,
		RESET,
		CACHE_ADDR,
		CACHE_MEMREAD,
		CACHE_READDATA,
		CACHE_MEMWRITE,
		CACHE_WRITEDATA,
		CACHE_MEMSTALL,
		
		MAIN_MEM_ADDR,
		MAIN_MEM_MEMREAD,
		MAIN_MEM_READDATA,
		MAIN_MEM_MEMWRITE,
		MAIN_MEM_WRITEDATA,
		MAIN_MEM_MEMSTALL
	);
	
	CA: CACHE_ARBITER port map(
		CLOCK,
		IF_CACHE_OUT(65 downto 34), 
		MEM_CACHE_OUT(65 downto 34),
		IF_CACHE_OUT(33 downto 2),
		MEM_CACHE_OUT(33 downto 2),
		IF_CACHE_OUT(1),
		IF_CACHE_OUT(0),
		MEM_CACHE_OUT(1),
		MEM_CACHE_OUT(0),

		--Input Memory
		CACHE_MEMSTALL,

		--Output
		ENABLE,
		IF_CACHE_IN(32 downto 1),
		MEM_CACHE_OUT(32 downto 1),
		
		CACHE_ADDR,CACHE_WRITEDATA,
		CACHE_MEMWRITE,CACHE_MEMREAD,
		CACHE_READDATA
	
	);
	
	BRANCH_SEL <= '1' when EX_CONTROL_VECTOR(7) = '1' or (EX_BRANCH = '1' and EX_INSTR(31 downto 26) = "000100") or (EX_BRANCH = '0' and EX_INSTR(31 downto 26) = "000101" ) else
		'0';

	WB: process(CLOCK)
	
	begin
	
		if falling_edge(CLOCK) then
		
			if WB_CONTROL_VECTOR(2) = '1' then
		
					ID_WB_DATA <= WB_DATA;
				
			elsif (WB_INSTR(5 downto 0) = "011000" and WB_INSTR(31 downto 26) = "000000") or (WB_INSTR(5 downto 0) = "011010" and WB_INSTR(31 downto 26) = "000000") then
			
				HI <= WB_ADDR(63 downto 32);
				LO <= WB_ADDR(31 downto 0);
			
			elsif (WB_INSTR(5 downto 0) = "010000" and WB_INSTR(31 downto 26) = "000000") then
					ID_WB_DATA <= HI;
			elsif	(WB_INSTR(5 downto 0) = "010010" and WB_INSTR(31 downto 26) = "000000") then
					ID_WB_DATA <= LO;
			else
			
				ID_WB_DATA <= WB_ADDR(31 downto 0);
			
			end if;
			
			if WB_INSTR(31 downto 26) = "000000" then
				ID_WB_SRC(4 downto 0) <= WB_INSTR(15 downto 11);
			else
				ID_WB_SRC(4 downto 0) <= WB_INSTR(20 downto 16);
			end if;
				
			ID_WB_SRC(31 downto 5) <= (others => '0');
			
		end if;
		
	end process;

end architecture;