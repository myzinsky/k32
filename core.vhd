library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity core is
    PORT(
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        done       : out std_logic
    );
end core;

Architecture behavior of core is

    signal pc      : unsigned(31 downto 0)         := (others => '0'); -- Programm Counter
    signal pc_addr : unsigned(31 downto 0)         := (others => '0'); -- Programm Counter Address

    signal inst    : std_logic_vector(31 downto 0) := (others => '0'); -- Current Instruction
    signal funct3  : std_logic_vector( 2 downto 0) := (others => '0'); -- TODO
    signal funct7  : std_logic_vector( 6 downto 0) := (others => '0'); -- TODO
    signal opcode  : std_logic_vector( 6 downto 0) := (others => '0'); -- TODO
    signal rs1     : std_logic_vector( 4 downto 0) := (others => '0'); -- TODO
    signal rs2     : std_logic_vector( 4 downto 0) := (others => '0'); -- TODO
    signal rd      : std_logic_vector( 4 downto 0) := (others => '0'); -- TODO
    signal imm     : std_logic_vector(31 downto 0) := (others => '0'); -- TODO
    signal bne_imm : std_logic_vector(31 downto 0) := (others => '0'); -- TODO
    signal jal_imm : std_logic_vector(31 downto 0) := (others => '0'); -- TODO
    signal sign    : std_logic_vector( 0 downto 0) := (others => '0'); -- TODO

    type reg_t is array (0 to 31) of std_logic_vector(31 downto 0);
    signal reg : reg_t;

    type program_t is array (0 to 64) of std_logic_vector(31 downto 0);
    signal program : program_t := (
        x"00000293",
        x"00900313",
        x"00100393",
        x"00100413",
        x"00100493",
        x"007404B3",
        x"008003B3",
        x"00900433",
        x"00128293",
        x"FE629863",
        others => x"00000000"
    );

    type memory_t is array (0 to 64) of std_logic_vector(31 downto 0);
    signal memory : memory_t :=(others => x"00000000");

    type state_t is (
        S_FE,
        S_DE,
        S_EX,
        S_WB,
        S_ID
    );

    constant op_add  : std_logic_vector(6 downto 0) := "0110011";
    constant op_addi : std_logic_vector(6 downto 0) := "0010011";
    constant op_mul  : std_logic_vector(6 downto 0) := "0110011";
    constant op_lw   : std_logic_vector(6 downto 0) := "0000011";
    constant op_sw   : std_logic_vector(6 downto 0) := "0100011";
    constant op_jal  : std_logic_vector(6 downto 0) := "1101111";
    constant op_jr   : std_logic_vector(6 downto 0) := "1100111";
    constant op_bne  : std_logic_vector(6 downto 0) := "1100011";

    constant f3_add  : std_logic_vector(2 downto 0) := "000";
    constant f3_addi : std_logic_vector(2 downto 0) := "000";
    constant f3_mul  : std_logic_vector(2 downto 0) := "000";
    constant f3_lw   : std_logic_vector(2 downto 0) := "010";
    constant f3_sw   : std_logic_vector(2 downto 0) := "010";
    constant f3_jr   : std_logic_vector(2 downto 0) := "000";
    constant f3_bne  : std_logic_vector(2 downto 0) := "001";

    constant f7_add  : std_logic_vector(6 downto 0) := "0000000";
    constant f7_mul  : std_logic_vector(6 downto 0) := "0000001";

    signal state : state_t := S_FE;

begin

    -- Concurrent Assignments:
    pc_addr <= "00" & pc(31 downto 2);

    -- CPU FSM:

    core_fsm : process(clk)
        variable tmp : std_logic_vector(63 downto 0);
    begin
        if rising_edge(clk) then
            if reset_n = '0' then 
                state  <= S_FE;
                pc     <= (others => '0');
                reg(0) <= (others => '0');
                done   <= '1';
            else
                case state is
                    -------------------
                    when S_FE =>
                        if pc_addr <= 9 then -- TODO fix me :-)
                            inst  <= program(to_integer(pc_addr));
                            state <= S_DE;
                        else 
                            state <= S_ID;
                        end if;
                    -------------------
                    when S_DE =>
                        funct7 <= inst(31 downto 25);    
                        rs2    <= inst(24 downto 20); -- 00000001111100000000000000000000
                        rs1    <= inst(19 downto 15); -- 00000000000011111000000000000000
                        funct3 <= inst(14 downto 12);
                        rd     <= inst(11 downto  7); -- 00000000000000000000111110000000
                        opcode <= inst(6  downto  0);
                        sign   <= inst(31 downto 31);

                        if inst(31) = '1' then -- Sign Extension
                            imm <= "11111111111111111111" & inst(31 downto 20); 
                        else
                            imm <= "00000000000000000000" & inst(31 downto 20);
                        end if;

                        if inst(31) = '1' then -- Sign Extension
                            bne_imm <= "11111111111111111111" & inst(31 downto 25) & inst(11 downto 7); 
                        else
                            bne_imm <= "00000000000000000000" & inst(31 downto 25) & inst(11 downto 7);
                        end if;

                        if inst(31) = '1' then -- Sign Extension
                            jal_imm <= "111111111111" & inst(31 downto 12);
                        else
                            jal_imm <= "000000000000" & inst(31 downto 12);
                        end if;
                        
                        state  <= S_EX; 
                    -------------------
                    when S_EX =>

                        pc    <= pc + 4;
                        state <= S_WB; 

                        if inst = x"00000000" then -- NOP
                            -- NOP
                        elsif opcode = op_add and funct3 = f3_add and funct7 = f7_add then -- ADD
                            reg(to_integer(unsigned(rd))) <= std_logic_vector(
                                signed(reg(to_integer(unsigned(rs1)))) + signed(reg(to_integer(unsigned(rs2))))
                            );
                        elsif opcode = op_addi and funct3 = f3_addi then -- ADDI
                            reg(to_integer(unsigned(rd))) <= std_logic_vector(
                                signed(reg(to_integer(unsigned(rs1)))) + signed(imm)
                            );
                        elsif opcode = op_mul and funct3 = f3_mul and funct7 = f7_mul then -- MUL
                            tmp := std_logic_vector(
                                signed(reg(to_integer(unsigned(rs1)))) * signed(reg(to_integer(unsigned(rs2))))
                            );
                            reg(to_integer(unsigned(rd))) <= tmp(31 downto 0);
                            state <= S_ID;
                        elsif opcode = op_lw and funct3 = f3_lw then -- LW
                            reg(to_integer(unsigned(rd))) <= memory(to_integer(
                                signed(reg(to_integer(unsigned(rs1)))) + signed(imm)
                            ));
                        elsif opcode = op_sw and funct3 = f3_sw then -- SW
                            memory(to_integer(
                                signed(reg(to_integer(unsigned(rs1)))) + signed(bne_imm)
                            )) <= reg(to_integer(unsigned(rs2)));
                        elsif opcode = op_jal then -- JAL
                            reg(to_integer(unsigned(rd))) <= std_logic_vector(pc + 4);
                            pc <= unsigned(signed(pc) + signed(jal_imm));
                        elsif opcode = op_jr and funct3 = f3_jr then -- JR
                            pc <= unsigned(reg(to_integer(unsigned(rs1))));
                        elsif opcode = op_bne and funct3 = f3_bne then -- BNE:
                            if not ((reg(to_integer(unsigned(rs1)))) = (reg(to_integer(unsigned(rs2))))) then
                                pc <= unsigned(signed(pc) + signed(bne_imm));
                            end if;
                        else 
                            state <= S_ID; 
                        end if;
                    -------------------
                    when S_WB =>
                        state <= S_FE;
                    -------------------
                    when S_ID =>
                        done <= '0';
                end case;
            end if;
        end if;
    end process;
end behavior;
