library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity riscv_tb is
end riscv_tb;

architecture riscv_architecture of riscv_tb is

    -- DUT (Device Under Test)
    component riscv_datapath_controller is
        Port (
            clk        : in  STD_LOGIC;
            rst        : in  STD_LOGIC;
            halted     : out STD_LOGIC;
            saida_temp : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Sinais para conectar ao DUT
    signal clk_tb    : STD_LOGIC := '0';
    signal rst_tb    : STD_LOGIC;
    signal halted_tb : STD_LOGIC;
    signal saida_tb  : STD_LOGIC_VECTOR(15 downto 0);

    -- Definição do período do Clock
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instancia o DUT
    DUT: riscv_datapath_controller
    port map (
        clk        => clk_tb,
        rst        => rst_tb,
        halted     => halted_tb,
        saida_temp => saida_tb
    );

    -- Processo de geração de Clock
    clk_process: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
        
        if halted_tb = '1' then
            wait; -- Para o clock se o processador sinalizar HALT
        end if;
    end process;

    -- Processo de estímulo (Reset)
    stimulus_process: process
    begin
        rst_tb <= '1';
        wait for CLK_PERIOD * 2;
        
        rst_tb <= '0';
        
        -- Aguarda o fim do programa
        wait until halted_tb = '1';
        wait;
    end process;

end riscv_architecture;