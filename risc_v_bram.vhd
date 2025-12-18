library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RiscV16 is
    Port (
        clk              : in  STD_LOGIC;
        rst              : in  STD_LOGIC;
        halted           : out STD_LOGIC;
        -- Interface da BRAM
        mem_address      : out STD_LOGIC_VECTOR(7 downto 0);
        mem_data_out     : in  STD_LOGIC_VECTOR(15 downto 0);
        mem_data_in      : out STD_LOGIC_VECTOR(15 downto 0);
        mem_write_enable : out STD_LOGIC
    );
end RiscV16;

architecture rtl of RiscV16 is

    -- Nova máquina de estados com estados de espera para memória síncrona
    type state_type is (FETCH, FETCH_WAIT, DECODE, EXECUTE, LW_WAIT, WRITEBACK, HALT);
    signal state : state_type := FETCH;

    -- Banco de registradores
    type reg_file_type is array(0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
    signal Regs : reg_file_type := (others => (others => '0'));

    -- Sinais internos
    signal PC           : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal IR           : STD_LOGIC_VECTOR(15 downto 0);
    signal running      : STD_LOGIC := '1';

    -- Sinais decodificados
    signal opcode       : STD_LOGIC_VECTOR(3 downto 0);
    signal rd, rs1, rs2 : INTEGER range 0 to 7;
    signal imm          : STD_LOGIC_VECTOR(5 downto 0);
    signal offset       : SIGNED(5 downto 0);

    -- Sinais da ULA e Controle
    signal alu_out      : STD_LOGIC_VECTOR(15 downto 0);
    signal write_en     : STD_LOGIC := '0';
    signal write_addr   : INTEGER range 0 to 7;
    signal mem_data_reg : STD_LOGIC_VECTOR(15 downto 0); -- Registrador temporário para LW

begin

    -- O dado de entrada da memória pode ficar fixo no registrador apontado por RD
    -- A escrita só ocorre efetivamente quando mem_write_enable for '1'
    mem_data_in <= Regs(rd);

    process(clk, rst)
    begin
        if rst = '1' then
            PC               <= (others => '0');
            IR               <= (others => '0');
            Regs             <= (others => (others => '0'));
            running          <= '1';
            state            <= FETCH;
            write_en         <= '0';
            mem_write_enable <= '0';
            mem_address      <= (others => '0');
            
        elsif rising_edge(clk) then
            if running = '1' then
                
                -- Default para sinais de controle de pulso
                mem_write_enable <= '0';
                write_en         <= '0';

                case state is
                    when FETCH =>
                        mem_address <= PC;
                        PC          <= std_logic_vector(unsigned(PC) + 1);
                        state       <= FETCH_WAIT;

                    when FETCH_WAIT =>
                        -- Aguarda o dado da BRAM estar disponível
                        IR    <= mem_data_out;
                        state <= DECODE;

                    when DECODE =>
                        opcode <= IR(3 downto 0);
                        rd     <= to_integer(unsigned(IR(15 downto 13)));
                        rs1    <= to_integer(unsigned(IR(12 downto 10)));
                        rs2    <= to_integer(unsigned(IR(9 downto 7)));
                        imm    <= IR(9 downto 4);
                        offset <= signed(IR(9 downto 4));
                        state  <= EXECUTE;

                    when EXECUTE =>
                        case opcode is
                            when "1000" => -- LW
                                mem_address <= std_logic_vector(signed(Regs(rs1)) + offset);
                                state       <= LW_WAIT;

                            when "1001" => -- SW
                                mem_address      <= std_logic_vector(signed(Regs(rs1)) + offset);
                                -- O dado mem_data_in já está conectado a Regs(rd)
                                mem_write_enable <= '1'; 
                                state            <= FETCH;

                            -- Lógica da ULA (Restaurada para funcionamento)
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
                            
                            -- Imediatos e outros
                            when "0101" => -- ADDI
                                alu_out <= std_logic_vector(signed(Regs(rs1)) + signed(resize(unsigned(imm), 16)));
                                state   <= WRITEBACK;
                            when "1100" => -- JAL
                                alu_out <= std_logic_vector(resize(unsigned(PC), 16)); -- Salva PC atual
                                PC      <= std_logic_vector(signed(PC) + offset - 1);  -- Salta (ajuste -1 pois PC já incrementou)
                                state   <= WRITEBACK;
                            when "1101" => -- LUI
                                alu_out <= "000000" & imm & "0000";
                                state   <= WRITEBACK;

                            -- Desvios
                            when "1010" => -- BEQ
                                if Regs(rs1) = Regs(rd) then
                                    PC <= std_logic_vector(signed(PC) + offset - 1);
                                end if;
                                state <= FETCH;
                            when "1011" => -- BNE
                                if Regs(rs1) /= Regs(rd) then
                                    PC <= std_logic_vector(signed(PC) + offset - 1);
                                end if;
                                state <= FETCH;

                            when "1111" => -- HLT
                                state <= HALT;

                            when others => -- NOP ou inválido
                                state <= FETCH;
                        end case;

                        -- Define se haverá escrita no registrador (Write Back)
                        if (opcode < "1001" or opcode = "1100" or opcode = "1101") then
                            write_en   <= '1';
                            write_addr <= rd;
                        end if;

                    when LW_WAIT =>
                        mem_data_reg <= mem_data_out; -- Captura o dado da memória
                        state        <= WRITEBACK;

                    when WRITEBACK =>
                        -- Efetua a escrita no banco de registradores
                        if write_en = '1' then
                            if (opcode = "1000") then -- Se for LW
                                Regs(write_addr) <= mem_data_reg;
                            else -- Se for instrução de ULA
                                Regs(write_addr) <= alu_out;
                            end if;
                        end if;
                        state <= FETCH;

                    when HALT =>
                        running <= '0';

                end case;
            end if;
        end if;
    end process;

    halted <= not running;

end rtl;