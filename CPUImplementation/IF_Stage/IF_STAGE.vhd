library IEEE;
use IEEE.std_logic_1164.all;		
use IEEE.numeric_std.all;

entity IF_STAGE is
	port(
		--INPUT--
		--Clock signal--
		CLOCK: in std_logic;
		--Reset signal--
		RESET: in std_logic;
		--PC MUX select signal--
		PC_SRC: in std_logic;
		--Feedback from ALU for PC calc.--
		ALU_PC: in integer range 0 to 4096;
		
		--OUTPUT--
		--PC output--
		PC_OUT: out integer range 0 to 4096;
		--Fetched instruction--
		INSTR: out std_logic_vector(31 downto 0)
	);
end IF_STAGE;

architecture IF_STAGE_Impl of IF_STAGE is	

	--Intermediate signals--

	signal PC_CURRENT, PC_INCR, PC_FEEDBACK: std_logic_vector(31 downto 0) := (others => '0');
	
	
	signal INSTR_ADDR: integer := 0;
	
	signal WAIT_REQ, WFA_Cout: std_logic := '0';


	signal INSTR_FETCHED: std_logic_vector(31 downto 0) := (others => 'U');
	signal PC_NEXT: std_logic_vector(31 downto 0) := (others => '0');

	constant pc_limit : integer := 32768/4;

	--Components--

	component WORDFULLADDER 
		port(
			--Operands--
			A,B: in	std_logic_vector(31 downto 0);
			--Result--
			S: out std_logic_vector(31 downto 0);
			--Carry out--
			Cout: out std_logic
		);
	end component;

	component MUX
		port (
			--Multiplexer inputs--
			A,B: in std_logic_vector(31 downto 0);
			--Multiplexer selector--
			SELECTOR: in std_logic;
			--Multiplexer output--
			OUTPUT: out std_logic_vector(31 downto 0)
		);
		
	end component;

	component PC_Register is 
		port(
			--Clock signal--
			CLOCK: in std_logic;
			--Reset signal--
			RESET: in std_logic;
			--Write access--
			REG_WRITE: in std_logic;
			--Write input--
			DATA_IN: in std_logic_vector(31 downto 0);
			--Write output--
			DATA_OUT: out std_logic_vector(31 downto 0)
		);
	end component PC_Register;

	component memory is
		GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns;
		from_file : boolean := true;		
		file_in : string := "program.txt";
		to_file : boolean := false;
		file_out : string := "output.txt";
		sim_limit : time := 10 ns
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

	begin

	--Component instantiation--

	-- --Word-width full adder--
	-- WFA : WORDFULLADDER port map(
		-- --Last recorded PC
		-- PC_CURRENT, 
		-- --Const. 4, one word forward
		-- std_logic_vector(to_unsigned(4,32)), 
		-- --New PC
		-- PC_INCR,
		-- --Unused, Carry-out
		-- WFA_Cout
	-- );
	
	--Program counter accumulator register--
	PC_REG : PC_Register port map(
		--Clock signal
		CLOCK, 
		--Reset: disabled
		'0', 
		--REG_WRITE: enabled
		'1', 
		--Input
		PC_FEEDBACK,
		--Output
		PC_CURRENT
	);

	--Multiplexer--
	MX : MUX port map(
		--Input 1
		PC_INCR, 
		--Input 2
		ALU_PC, 
		--Selector
		PC_SRC, 
		--Output
		PC_NEXT
	);

	--Instruction memory--
	INSTR_MEM : memory port map(
		--Clock
		CLOCK, 
		--Write data, disabled
		std_logic_vector(to_unsigned(0,32)), 
		--Addr. for fetch
		INSTR_ADDR, 
		--REGWRITE: disabled
		'0', 
		--REGREAD: enabled
		'1', 
		--Instr. out
		INSTR_FETCHED,
		--Wait signal
		WAIT_REQ
	);
	
	--Sequential logic

	--Address feed to the instruction memory.
	--Synchronized with the clock signal.
	
	process(CLOCK, INSTR_FETCHED)

	begin

		if rising_edge(CLOCK) then	
		
			--Only proceed if the PC is legal

			if to_integer(unsigned(PC_CURRENT)) < pc_limit - 4 then
			
				--Generate a new instr. addr. to send to the instr. mem.
				INSTR_ADDR <= to_integer(unsigned(PC_CURRENT)) / 4;
				
				PC_OUT <= PC_NEXT;
				PC_FEEDBACK <= PC_NEXT;
				INSTR <= INSTR_FETCHED;
				
				PC_CURRENT <= 
				
				report "IF: New instr. addr. generated.";
				
			end if;
			
		elsif INSTR_FETCHED'event then
		
			--Refresh stage outputs.
	

		
			report "IF: Stage output refresh.";
		
		end if;

	end process;

end architecture; 