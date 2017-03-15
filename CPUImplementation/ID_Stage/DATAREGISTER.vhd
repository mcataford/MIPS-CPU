
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DATAREGISTER is

    port(

        ---Inputs---
        CLOCK : in std_logic;
        READ_REG1 : in std_logic_vector (4 downto 0);
        READ_REG2 : in std_logic_vector (4 downto 0);
        WRITE_REG : in std_logic_vector (4 downto 0);
        WRITE_DATA : in std_logic_vector (31 downto 0);
        
        ---Internal Signals---
        PC_IN : in std_logic_vector (31 downto 0);

        ---Control Signals---
        CONTROL_LINK : in std_logic;
        CONTROL_REG_WRITE : in std_logic;
        CONTROL_GET_HI : in std_logic;
        CONTROL_GET_LO : in std_logic;

        ---Outputs---

        READ_DATA_OUT1 : out std_logic_vector (31 downto 0);
        READ_DATA_OUT2 : out std_logic_vector (31 downto 0)

    );
end DATAREGISTER;

architecture arch of DATAREGISTER is

    type MEM is array (31 downto 0) of std_logic_vector(31 downto 0);
    signal REG : MEM:=("00000000000000000000000000000000","00000000000000000000000000000001","00000000000000000000000000000010","00000000000000000000000000000011","00000000000000000000000000000100","00000000000000000000000000000101","00000000000000000000000000000110","00000000000000000000000000000111","00000000000000000000000000001000","00000000000000000000000000001001","00000000000000000000000000001010","00000000000000000000000000001011","00000000000000000000000000001100","00000000000000000000000000001101","00000000000000000000000000001110","00000000000000000000000000001111","00000000000000000000000000000000","00000000000000000000000000000001","00000000000000000000000000000010","00000000000000000000000000000011","00000000000000000000000000000100","00000000000000000000000000000101","00000000000000000000000000000110","00000000000000000000000000000111","00000000000000000000000000001000","00000000000000000000000000001001","00000000000000000000000000001010","00000000000000000000000000001011","00000000000000000000000000001100","00000000000000000000000000001101","00000000000000000000000000001110","00000000000000000000000000000000");
    --type MEM is array (3 downto 0) of std_logic_vector(31 downto 0);
    --signal REG : MEM := ("00000000000000000000000000000000","00000000000000000000000000000001","01010101010101010101010101010101","00000000000000000000000000000000");
    signal rs, rt, rd : integer;

    begin

        --- Continuously sets $0 = 0x0000;
        REG(0) <= "00000000000000000000000000000000";

        --- Decode addresses to integers
        rs <= to_integer(unsigned(READ_REG1));
        rt <= to_integer(unsigned(READ_REG2));
        rd <= to_integer(unsigned(WRITE_REG));

        reg_op : process(CLOCK, READ_REG1, READ_REG2)
            begin
            if(falling_edge(CLOCK) AND CONTROL_REG_WRITE = '1') then
                REG(rd) <= WRITE_DATA;
            end if;
            if(rising_edge(CLOCK)) then
                if(CONTROL_LINK = '1') then
                    REG(3) <= PC_IN;
                end if;
                READ_DATA_OUT1 <= REG(rs);
                READ_DATA_OUT2 <= REG(rt);
            end if;
        end process reg_op;
end arch;