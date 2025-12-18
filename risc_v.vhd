library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity riscv is
    Port (
        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        halted     : out STD_LOGIC;
        saida_temp : out STD_LOGIC_VECTOR(15 downto 0)
    );
end riscv;

architecture riscv_arquitecture of riscv is

    -- Máquina de estados
    type state_type is (FETCH, DECODE, EXECUTE, WRITEBACK, HALT);
    signal state : state_type := FETCH;

    -- Definição da memória (256 posições de 16 bits)
    type mem_type is array (0 to 255) of STD_LOGIC_VECTOR(15 downto 0);
    signal Mem : mem_type := (others => (others => '0'));

    -- =============================================================================
    -- INSERIR AQUI, UM DE CADA VEZ, OS TRECHOS PARA TESTBENCH DOS PROGRAMAS 1, 2 E 3
    -- =============================================================================
    -- ...
    -- =============================================================================
    -- FIM DOS TRECHOS PARA TESTBENCH DOS PROGRAMAS 1, 2 E 3
    -- =============================================================================

    -- Banco de registradores (8 registradores de 16 bits)
    type reg_file_type is array(0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
    signal Regs : reg_file_type := (others => (others => '0'));

    -- Sinais internos do processador
    signal PC      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal IR      : STD_LOGIC_VECTOR(15 downto 0);
    signal running : STD_LOGIC := '1';

    -- Sinais para decodificação da instrução
    signal opcode : STD_LOGIC_VECTOR(3 downto 0);
    signal rd     : INTEGER range 0 to 7;
    signal rs1    : INTEGER range 0 to 7;
    signal rs2    : INTEGER range 0 to 7;
    signal imm    : STD_LOGIC_VECTOR(5 downto 0);
    signal offset : SIGNED(5 downto 0);

    -- Sinais para a ULA e escrita nos registradores
    signal alu_out    : STD_LOGIC_VECTOR(15 downto 0);
    signal write_en   : STD_LOGIC := '0';
    signal write_addr : INTEGER range 0 to 7;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset de todos os sinais e registradores
            PC       <= (others => '0');
            IR       <= (others => '0');
            Regs     <= (others => (others => '0'));
            running  <= '1';
            state    <= FETCH;
            write_en <= '0';
        elsif rising_edge(clk) then
            if running = '1' then
                case state is
                    when FETCH =>
                        -- Busca a instrução da memória e incrementa o PC
                        IR <= Mem(to_integer(unsigned(PC)));
                        PC <= std_logic_vector(unsigned(PC) + 1);
                        state <= DECODE;

                    when DECODE =>
                        -- Decodifica a instrução (IR) em seus campos
                        opcode <= IR(3 downto 0);
                        rd     <= to_integer(unsigned(IR(15 downto 13)));
                        rs1    <= to_integer(unsigned(IR(12 downto 10)));
                        rs2    <= to_integer(unsigned(IR(9 downto 7)));
                        imm    <= IR(9 downto 4); -- Imediato de 6 bits
                        offset <= signed(IR(9 downto 4));
                        state  <= EXECUTE;

                    when EXECUTE =>
                        write_en <= '0';
                        case opcode is
                            when "0000" => -- ADD
                                alu_out <= std_logic_vector(signed(Regs(rs1)) + signed(Regs(rs2)));
                                state   <= WRITEBACK;

                            when "0001" => -- SUB
                                alu_out <= std_logic_vector(signed(Regs(rs1)) - signed(Regs(rs2)));
                                state   <= WRITEBACK;

                            when "0010" => -- AND
                                alu_out <= Regs(rs1) and Regs(rs2);
                                state   <= WRITEBACK;

                            when "0011" => -- OR
                                alu_out <= Regs(rs1) or Regs(rs2);
                                state   <= WRITEBACK;

                            when "0100" => -- XOR
                                alu_out <= Regs(rs1) xor Regs(rs2);
                                state   <= WRITEBACK;

                            when "0101" => -- ADDI
                                alu_out <= std_logic_vector(signed(Regs(rs1)) + signed(resize(unsigned(imm), 16)));
                                state   <= WRITEBACK;

                            when "0110" => -- ANDI
                                alu_out <= Regs(rs1) and std_logic_vector(resize(unsigned(imm), 16));
                                state   <= WRITEBACK;

                            when "0111" => -- ORI
                                alu_out <= Regs(rs1) or std_logic_vector(resize(unsigned(imm), 16));
                                state   <= WRITEBACK;

                            when "1000" => -- LW
                                alu_out <= Mem(to_integer(signed(Regs(rs1)) + offset));
                                state   <= WRITEBACK;

                            when "1001" => -- SW
                                Mem(to_integer(signed(Regs(rs1)) + offset)) <= Regs(rd);
                                state <= FETCH; -- SW não tem writeback, volta para FETCH

                            when "1010" => -- BEQ
                                if Regs(rs1) = Regs(rd) then
                                    PC <= std_logic_vector(signed(PC) + offset);
                                end if;
                                state <= FETCH;

                            when "1011" => -- BNE
                                if Regs(rs1) /= Regs(rd) then
                                    PC <= std_logic_vector(signed(PC) + offset);
                                end if;
                                state <= FETCH;

                            when "1100" => -- JAL
                                alu_out <= std_logic_vector(resize(unsigned(PC), 16));
                                PC      <= std_logic_vector(signed(PC) + offset);
                                state   <= WRITEBACK;

                            when "1101" => -- LUI
                                alu_out <= "000000" & imm & "0000";
                                state   <= WRITEBACK;

                            when "1110" => -- NOP
                                state <= FETCH;

                            when "1111" => -- HLT
                                running <= '0';
                                state   <= HALT;

                            when others =>
                                state <= FETCH;
                        end case;

                        -- Lógica de controle de escrita (Write Enable)
                        if (opcode < "1001" or opcode = "1100" or opcode = "1101") then
                            write_en   <= '1';
                            write_addr <= rd;
                        end if;

                    when WRITEBACK =>
                        if write_en = '1' then
                            Regs(write_addr) <= alu_out;
                        end if;
                        state <= FETCH;

                    when HALT =>
                        running <= '0';
                end case;
            end if;
        end if;
    end process;

    halted     <= not running;
    saida_temp <= alu_out;

end riscv_arquitecture;