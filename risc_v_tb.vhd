library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity riscv_tb is
end riscv_tb;

architecture riscv_architecture of riscv_tb is

    -- Declaração do componente (DUT - Device Under Test)
    component riscv is
        Port (
            clk        : in  STD_LOGIC;
            rst        : in  STD_LOGIC;
            halted     : out STD_LOGIC;
            saida_temp : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Sinais do testbench
    signal clk_tb    : STD_LOGIC := '0';
    signal rst_tb    : STD_LOGIC;
    signal halted_tb : STD_LOGIC;
    signal saida_tb  : STD_LOGIC_VECTOR(15 downto 0);

    -- Constantes
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instanciação do DUT
    DUT: riscv
    port map (
        clk        => clk_tb,
        rst        => rst_tb,
        halted     => halted_tb,
        saida_temp => saida_tb
    );

    -- Processo de geração de clock
    -- O clock para de rodar quando o processador envia o sinal de halted
    clk_process: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;

        if halted_tb = '1' then
            wait; -- Para a simulação indefinidamente
        end if;
    end process;

    -- Processo de estímulo (Reset)
    stimulus_process: process
    begin
        -- Sequência de Reset
        rst_tb <= '1';
        wait for CLK_PERIOD * 2;
        
        rst_tb <= '0';

        -- Aguarda o processador terminar a execução
        wait until halted_tb = '1';
        
        -- Fim do teste
        wait;
    end process;

end riscv_architecture;