library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Entidade principal do processador
entity riscv_datapath_controller is
    Port (
        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        saida_temp : out STD_LOGIC_VECTOR(15 downto 0);
        halted     : out STD_LOGIC
    );
end riscv_datapath_controller;

architecture datapath_controller of riscv_datapath_controller is

    -- Definição da máquina de estados
    type state_type is (FETCH, DECODE, EXECUTE, WRITEBACK, HALT);
    signal state : state_type := FETCH;

    -- === Sinais da Parte Operativa (Datapath) ===

    -- Definição da Memória (256 posições de 16 bits)
    type mem_type is array(0 to 255) of STD_LOGIC_VECTOR(15 downto 0);

    -- ============================================
    -- AQUI TESTAREMOS O PROGRAMA 1
    -- ============================================
    signal Mem : mem_type := (
        0      => x"2075", -- ADDI r1, r0, 7
        1      => x"4085", -- ADDI r2, r0, 8
        2      => x"6540", -- ADD r3, r1, r2
        3      => x"8145", -- ADDI r4, r0, 20
        4      => x"7009", -- SW r3, r4, 0
        5      => x"000F", -- HLT
        others => (others => '0')
    );
    -- ============================================
    -- FIM DO PROGRAMA 1
    -- ============================================

    -- Definição do banco de registradores
    type reg_file_type is array(0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
    signal Regs : reg_file_type := (others => (others => '0'));

    -- Registradores de estado
    signal PC          : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal IR          : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_out_reg : STD_LOGIC_VECTOR(15 downto 0); -- Registrador de saída da ULA
    signal running     : STD_LOGIC := '1';

    -- Sinais decodificados da instrução
    signal opcode         : STD_LOGIC_VECTOR(3 downto 0);
    signal rd, rs1, rs2   : INTEGER range 0 to 7;
    signal imm_from_ir    : STD_LOGIC_VECTOR(5 downto 0);
    signal offset_from_ir : SIGNED(5 downto 0);

    -- Sinais de dados (saídas do banco de registradores)
    signal data_rs1, data_rs2, data_rd : STD_LOGIC_VECTOR(15 downto 0);

    -- Sinais da ULA (combinacionais)
    signal alu_out_comb     : STD_LOGIC_VECTOR(15 downto 0);
    signal pc_plus_1        : STD_LOGIC_VECTOR(7 downto 0);
    signal pc_branch_target : STD_LOGIC_VECTOR(7 downto 0);
    signal pc_in            : STD_LOGIC_VECTOR(7 downto 0);
    signal reg_write_data   : STD_LOGIC_VECTOR(15 downto 0);
    signal branch_cond_beq  : BOOLEAN;
    signal branch_cond_bne  : BOOLEAN;

    -- === Sinais da Parte de Controle (Controller) ===
    signal s_pc_we, s_ir_we, s_reg_we, s_mem_we, s_alu_out_we : STD_LOGIC;
    signal s_pc_sel : STD_LOGIC;
    signal s_wb_sel : STD_LOGIC;

begin

    -- ======================================================
    -- PARTE OPERATIVA (DATAPATH) - LÓGICA COMBINACIONAL
    -- ======================================================

    -- Decodificador de instrução
    opcode         <= IR(3 downto 0);
    rd             <= to_integer(unsigned(IR(15 downto 13)));
    rs1            <= to_integer(unsigned(IR(12 downto 10)));
    rs2            <= to_integer(unsigned(IR(9 downto 7)));
    imm_from_ir    <= IR(9 downto 4);
    offset_from_ir <= signed(IR(9 downto 4));

    -- Saídas do banco de registradores
    data_rs1 <= Regs(rs1);
    data_rs2 <= Regs(rs2);
    data_rd  <= Regs(rd);

    -- Lógica de cálculo do próximo PC
    pc_plus_1        <= std_logic_vector(unsigned(PC) + 1);
    pc_branch_target <= std_logic_vector(signed(PC) + offset_from_ir);

    -- Mux do PC
    pc_in <= pc_branch_target when s_pc_sel = '1' else pc_plus_1;

    -- Lógica de condição de desvio
    branch_cond_beq <= (data_rs1 = data_rd);
    branch_cond_bne <= (data_rs1 /= data_rd);

    -- Mux de escrita no registrador
    reg_write_data <= alu_out_reg;

    -- ULA combinacional
    alu_comb: process(opcode, data_rs1, data_rs2, imm_from_ir, PC, Mem)
        variable imm_6bit   : STD_LOGIC_VECTOR(5 downto 0);
        variable sw_lw_addr : unsigned(7 downto 0);
    begin
        imm_6bit := imm_from_ir;
        
        -- Lógica de endereço para SW/LW
        sw_lw_addr := unsigned(data_rs1(7 downto 0)) + unsigned(imm_6bit);

        case opcode is
            when "0000" => -- ADD
                alu_out_comb <= std_logic_vector(signed(data_rs1) + signed(data_rs2));
            when "0001" => -- SUB
                alu_out_comb <= std_logic_vector(signed(data_rs1) - signed(data_rs2));
            when "0010" => -- AND
                alu_out_comb <= data_rs1 and data_rs2;
            when "0011" => -- OR
                alu_out_comb <= data_rs1 or data_rs2;
            when "0100" => -- XOR
                alu_out_comb <= data_rs1 xor data_rs2;
            
            when "0101" => -- ADDI
                alu_out_comb <= std_logic_vector(signed(data_rs1) + signed(resize(unsigned(imm_6bit), 16)));
            when "0110" => -- ANDI
                alu_out_comb <= data_rs1 and std_logic_vector(resize(unsigned(imm_6bit), 16));
            when "0111" => -- ORI
                alu_out_comb <= data_rs1 or std_logic_vector(resize(unsigned(imm_6bit), 16));
            
            when "1000" => -- LW
                alu_out_comb <= Mem(to_integer(sw_lw_addr));
            when "1001" => -- SW
                alu_out_comb <= std_logic_vector(resize(sw_lw_addr, 16)); -- Passa endereço calculado
            
            when "1100" => -- JAL
                alu_out_comb <= std_logic_vector(resize(unsigned(PC), 16));
            when "1101" => -- LUI
                alu_out_comb <= "000000" & imm_6bit & "0000";
            
            when others => 
                alu_out_comb <= (others => '0');
        end case;
    end process alu_comb;

    halted     <= not running;
    saida_temp <= alu_out_reg;

    -- ======================================================
    -- PARTE OPERATIVA (DATAPATH) - LÓGICA SEQUENCIAL
    -- ======================================================
    -- Gerencia todos os registradores e a memória
    datapath_regs: process(clk, rst)
    begin
        if rst = '1' then
            -- Reset dos registradores
            PC          <= (others => '0');
            IR          <= (others => '0');
            Regs        <= (others => (others => '0'));
            alu_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            if running = '1' then
                
                -- Atualização do IR (no estado FETCH)
                if s_ir_we = '1' then
                    IR <= Mem(to_integer(unsigned(PC)));
                end if;

                -- Atualização do PC (no estado FETCH ou em desvios)
                if s_pc_we = '1' then
                    PC <= pc_in;
                end if;

                -- Atualização do banco de registradores (no estado WRITEBACK)
                if s_reg_we = '1' then
                    Regs(rd) <= reg_write_data;
                end if;

                -- Escrita na memória (no estado EXECUTE para SW)
                -- O endereço vem da saída da ULA (calculado combinacionalmente)
                if s_mem_we = '1' then
                    Mem(to_integer(unsigned(alu_out_comb(7 downto 0)))) <= data_rd;
                end if;

                -- Registrador de saída da ULA (no estado EXECUTE)
                if s_alu_out_we = '1' then
                    alu_out_reg <= alu_out_comb;
                end if;

            end if;
        end if;
    end process datapath_regs;

    -- ======================================================
    -- PARTE DE CONTROLE (CONTROLLER) - LÓGICA SEQUENCIAL
    -- ======================================================
    -- Gerencia a FSM e gera todos os sinais de controle

    

    controller_fsm: process(clk, rst)
    begin
        if rst = '1' then
            state        <= FETCH;
            running      <= '1';
            s_pc_we      <= '0'; 
            s_ir_we      <= '0'; 
            s_reg_we     <= '0'; 
            s_mem_we     <= '0';
            s_alu_out_we <= '0'; 
            s_pc_sel     <= '0'; 
            s_wb_sel     <= '0';
        elsif rising_edge(clk) then
            if running = '1' then
                -- Reset padrão dos sinais de controle para pulso
                s_pc_we      <= '0'; 
                s_ir_we      <= '0'; 
                s_reg_we     <= '0'; 
                s_mem_we     <= '0';
                s_alu_out_we <= '0'; 
                s_pc_sel     <= '0'; 
                s_wb_sel     <= '0';

                case state is
                    when FETCH =>
                        s_ir_we  <= '1'; -- IR <= Mem[PC]
                        s_pc_we  <= '1'; -- PC <= PC + 1
                        s_pc_sel <= '0'; -- Seleciona PC+1
                        state    <= DECODE;

                    when DECODE =>
                        state <= EXECUTE;

                    when EXECUTE =>
                        case opcode is
                            -- Instruções R, I, LW, LUI
                            when "0000" | "0001" | "0010" | "0011" | "0100" | "0101" | "0110" | "0111" | "1000" | "1101" =>
                                s_alu_out_we <= '1';
                                state        <= WRITEBACK;

                            when "1001" => -- SW
                                s_mem_we <= '1';
                                state    <= FETCH;

                            when "1010" => -- BEQ
                                if branch_cond_beq then
                                    s_pc_we  <= '1';
                                    s_pc_sel <= '1';
                                end if;
                                state <= FETCH;

                            when "1011" => -- BNE
                                if branch_cond_bne then
                                    s_pc_we  <= '1';
                                    s_pc_sel <= '1';
                                end if;
                                state <= FETCH;

                            when "1100" => -- JAL
                                s_alu_out_we <= '1';
                                s_pc_we      <= '1';
                                s_pc_sel     <= '1';
                                state        <= WRITEBACK;

                            when "1110" => -- NOP
                                state <= FETCH;

                            when "1111" => -- HLT
                                running <= '0';
                                state   <= HALT;

                            when others =>
                                state <= FETCH;
                        end case;

                    when WRITEBACK =>
                        s_reg_we <= '1';
                        state    <= FETCH;

                    when HALT =>
                        running <= '0';

                end case;
            end if;
        end if;
    end process controller_fsm;

end architecture datapath_controller;