--------------------------------------------------------------------
-- Arquivo   : exp5_trena_tb.vhd
-- Projeto   : Experiencia 5 - Trena Digital com Saida Serial
--------------------------------------------------------------------
-- Descricao : testbench para circuito de trena digital
--
--             1) array de casos de teste contém valores de  
--                largura de pulso de echo do sensor
-- 
--------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor                    Descricao
--     19/09/2021  1.0     Edson Midorikawa         versao inicial
--     12/09/2022  1.1     Edson Midorikawa         revisao
--     25/09/2022  1.2     Pedro Henrique Viveiros  adaptacao
--------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;

entity exp5_trena_tb is
end entity;

architecture tb of exp5_trena_tb is
  
  -- Componente a ser testado (Device Under Test -- DUT)
  component exp5_trena is
    port (
      clock 				   : in  std_logic;
      reset 				   : in  std_logic;
      mensurar 			   : in  std_logic;
      echo 			  	   : in  std_logic;
      trigger 			   : out std_logic;
      saida_serial 	   : out std_logic;
      medida0 			   : out std_logic_vector (6 downto 0);
      medida1 			   : out std_logic_vector (6 downto 0);
      medida2 			   : out std_logic_vector (6 downto 0);
      pronto 				   : out std_logic;
      db_estado 			 : out std_logic_vector (6 downto 0);
      db_estado_medida : out std_logic_vector (6 downto 0)
    );
   end component;
  
  -- Declaração de sinais para conectar o componente a ser testado (DUT)
  --   valores iniciais para fins de simulacao (GHDL ou ModelSim)
  signal clock_in             : std_logic := '0';
  signal reset_in             : std_logic := '0';
  signal mensurar_in          : std_logic := '0';
  signal echo_in              : std_logic := '0';
  signal trigger_out          : std_logic := '0';
  signal saida_serial_out     : std_logic := '0';
  signal medida0_out          : std_logic_vector (6 downto 0) := "0000000";
  signal medida1_out          : std_logic_vector (6 downto 0) := "0000000";
  signal medida2_out          : std_logic_vector (6 downto 0) := "0000000";
  signal pronto_out           : std_logic := '0';
  signal db_estado_out        : std_logic_vector (6 downto 0) := "0000000";
  signal db_estado_medida_out : std_logic_vector (6 downto 0) := "0000000";

  -- Configurações do clock
  constant clockPeriod   : time      := 20 ns; -- clock de 50MHz
  signal keep_simulating : std_logic := '0';   -- delimita o tempo de geração do clock
  
  -- Array de casos de teste
  type caso_teste_type is record
      id    : natural; 
      tempo : integer; 
  end record;

  type casos_teste_array is array (natural range <>) of caso_teste_type;
  constant casos_teste : casos_teste_array :=
      (
        (1, 1177),  -- 1177us (20cm)
        (2, 1194),  -- 1194us (20,3cm) truncar para 20cm
        (3, 1882),  -- 1882us (32cm)
        (4, 1929),  -- 1929us (32,8cm)  arredondar para 33cm
        (5, 235),   -- 235us  (4cm) 
        (6, 1177)   -- 279us  (4,75cm) arredondar para 5cm
        -- inserir aqui outros casos de teste (inserir "," na linha anterior)
      );

  signal larguraPulso: time := 1 ns;

begin
  -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o período
  -- especificado. Quando keep_simulating=0, clock é interrompido, bem como a 
  -- simulação de eventos
  clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
  
  -- Conecta DUT (Device Under Test)
  dut: exp5_trena
       port map( 
           clock            => clock_in,
           reset            => reset_in,
           mensurar         => mensurar_in,
           echo             => echo_in,
           trigger          => trigger_out,
           saida_serial     => saida_serial_out,
           medida0          => medida0_out,
           medida1          => medida1_out,
           medida2          => medida2_out,
           pronto           => pronto_out,
           db_estado        => db_estado_out,
           db_estado_medida => db_estado_medida_out
       );

  -- geracao dos sinais de entrada (estimulos)
  stimulus: process is
  begin
  
    assert false report "Inicio das simulacoes" severity note;
    keep_simulating <= '1';
    
    ---- valores iniciais ----------------
    mensurar_in <= '0';
    echo_in     <= '0';

    ---- inicio: reset ----------------
    wait for 2*clockPeriod;
    reset_in <= '1'; 
    wait for 2 us;
    reset_in <= '0';
    wait until falling_edge(clock_in);

    ---- espera de 100us
    wait for 100 us;

    ---- loop pelos casos de teste
    for i in casos_teste'range loop
        -- 1) determina largura do pulso echo
        assert false report "Caso de teste " & integer'image(casos_teste(i).id) & ": " &
            integer'image(casos_teste(i).tempo) & "us" severity note;
        larguraPulso <= casos_teste(i).tempo * 1 us; -- caso de teste "i"

        -- 2) envia pulso medir
        wait until falling_edge(clock_in);
        mensurar_in <= '1';
        wait for 5*clockPeriod;
        mensurar_in <= '0';
     
        -- 3) espera por 400us (tempo entre trigger e echo)
        wait for 400 us;
     
        -- 4) gera pulso de echo (largura = larguraPulso)
        echo_in <= '1';
        wait for larguraPulso;
        echo_in <= '0';
     
        -- 5) espera final da medida
      	wait until pronto_out = '1';
        assert false report "Fim do caso " & integer'image(casos_teste(i).id) severity note;
     
        -- 6) espera entre casos de tese
        wait for 100 us;

    end loop;

    ---- final dos casos de teste da simulacao
    assert false report "Fim das simulacoes" severity note;
    keep_simulating <= '0';
    
    wait; -- fim da simulação: aguarda indefinidamente (não retirar esta linha)
  end process;

end architecture;
