library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity riscv_bram_tb is
end riscv_bram_tb;

architecture simulation of riscv_bram_tb is

    -- Componente do Processador RISC-V
    component RiscV16 is
        Port (
            clk              : in  STD_LOGIC;
            rst              : in  STD_LOGIC;
            halted           : out STD_LOGIC;
            mem_address      : out STD_LOGIC_VECTOR(7 downto 0);
            mem_data_out     : in  STD_LOGIC_VECTOR(15 downto 0);
            mem_data_in      : out STD_LOGIC_VECTOR(15 downto 0);
            mem_write_enable : out STD_LOGIC
        );
    end component;

    -- Componente da Memória BRAM (Gerado pelo IP Catalog / Wizard)
    component memoria_programa is
        Port (
            clka  : in  STD_LOGIC;
            ena   : in  STD_LOGIC;
            wea   : in  STD_LOGIC_VECTOR(0 downto 0);
            addra : in  STD_LOGIC_VECTOR(7 downto 0);
            dina  : in  STD_LOGIC_VECTOR(15 downto 0);
            douta : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Sinais de controle do testbench
    constant CLK_PERIOD : time := 10 ns;
    
    signal clk_tb    : STD_LOGIC := '0';
    signal rst_tb    : STD_LOGIC;
    signal halted_tb : STD_LOGIC;

    -- Sinais para conectar o Processador (DUT) com a BRAM
    signal s_mem_address        : STD_LOGIC_VECTOR(7 downto 0);
    signal s_mem_data_from_bram : STD_LOGIC_VECTOR(15 downto 0);
    signal s_mem_data_to_bram   : STD_LOGIC_VECTOR(15 downto 0);
    signal s_mem_write_enable   : STD_LOGIC;

begin

    -- Instancia o Processador (Device Under Test)
    DUT: RiscV16
    port map (
        clk              => clk_tb,
        rst              => rst_tb,
        halted           => halted_tb,
        mem_address      => s_mem_address,
        mem_data_out     => s_mem_data_from_bram,
        mem_data_in      => s_mem_data_to_bram,
        mem_write_enable => s_mem_write_enable
    );

    -- Instancia a Memória BRAM
    -- Nota: 'wea' na BRAM geralmente é um vetor, por isso mapeamos o bit (0)
    BRAM_inst: memoria_programa
    port map (
        clka   => clk_tb,
        ena    => '1', -- Memória sempre habilitada
        wea(0) => s_mem_write_enable,
        addra  => s_mem_address,
        dina   => s_mem_data_to_bram,
        douta  => s_mem_data_from_bram
    );

    -- Processo para gerar o clock
    clk_process: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
        
        if halted_tb = '1' then
            wait; -- Para a simulação se o processador der HALT
        end if;
    end process;

    -- Processo para gerar o reset
    stimulus_process: process
    begin
        rst_tb <= '1';
        wait for CLK_PERIOD * 2;
        
        rst_tb <= '0';
        
        wait;
    end process;

end simulation;