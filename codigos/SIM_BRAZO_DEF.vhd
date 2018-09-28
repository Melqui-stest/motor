----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.09.2018 17:12:41
-- Design Name: 
-- Module Name: SIM_BRAZO_DEF - tb
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SIM_BRAZO_DEF is
--  Port ( );
end SIM_BRAZO_DEF;

architecture tb of SIM_BRAZO_DEF is
component BRAZO_DEF
 Port(
      clk : in std_logic;
      reset: in std_logic;-- será el reset(btnc)-btn0
 -----Stepmotor
      swdir : in std_logic;--control de la dirección--swt0
      swenable: in std_logic;--enable--desactiva todo
      swoff: in std_logic;--boton para activar o desactivar movimmiento sin tocar el enable, por que si activas el enable deja de haber movimiento pero tambien fuerza
     --desactiva movimiento pero mantiene fuerza
      swgirostep: in std_logic_vector(2 downto 0);--control del giro
      enable: out std_logic;--led0
      dir: out std_logic; -- 0 gira sentido horario y 1 sentido antihorario --led 4
      step : out std_logic; -- señal para cada micropaso--led5 
-----Servomotor
      swselservos: in std_logic_vector(5 downto 0);
      swgiroservos: in std_logic_vector(3 downto 0);--ELECCION DE GIRO
      JD: out std_logic_vector( 5 downto 0)
      );
 end component;
 ----------Señales
 ---Servomotor
 -- Inputs
   signal clk : std_logic;
   signal reset: std_logic;-- será el reset(btnc)
   signal swselservos : std_logic_vector(5 downto 0);
   signal  swgiroservos: std_logic_vector(3 downto 0);
   --Outputs
   signal JD: std_logic_vector( 5 downto 0);
 --Stepmotor
 --Inputps
 --signal clk : std_logic;
 --signal reset: std_logic;-- será el reset(btnc)
 signal swdir : std_logic;--control de la dirección(btnU)
 signal swenable: std_logic;--enable--desactiva todo
 signal swoff: std_logic;--enable--desactiva todo
 signal swgirostep:  std_logic_vector(2 downto 0);--control del giro
 --Outputs
 signal  dir: std_logic; -- 0 gira sentido horario y 1 sentido antihorario --led 4
 signal step : std_logic; -- señal para cada micropaso--led5
 signal enable: std_logic;--led0
begin
UnidadEnPruebas: BRAZO_DEF
  Port Map (
  --Stepmotor
              clk     =>  clk,
              reset   =>  reset,
              swdir  =>  swdir,
              swenable    =>  swenable,
              swoff    =>  swoff,
              swgirostep      =>  swgirostep,
              enable  =>  enable,
              dir     =>  dir,
              step    =>  step,
   --Servomotor
              swselservos     =>  swselservos,
              swgiroservos     =>  swgiroservos,
              JD      =>  JD
    );
--------ESTÍMULOS
P_clk:process
begin
     clk <='0';
     wait for 5 ns;
     clk <='1';
     wait for 5 ns;
end process;
 
P_reset:process
begin
     reset <='1';
     wait for 100 ns;
     reset <='0';
     --Servos
     swselservos<="000001";
     swgiroservos<="1010";
     --Stepmotor
     swdir <= '0';
     swoff<='0';
     swgirostep<="000";
     --swgirostept<="111";
     swenable<='1';
     wait for 1000 ns;
     --Servos
     swselservos<="000100";
     swgiroservos<="1010";
     --Stepmotor
     swdir <= '1';
     swgirostep<="001";
     --swgirostept<="101";
     swenable<='0';
     wait for 100 ms;
     --Servos
     swselservos<="000010";
     swgiroservos<="0011";
     --Stepmotor
     swdir <= '1';
     swgirostep<="010";
     --swgirostept<="010";
     swenable<='0';
     wait for 400 ms;
     --Servos
     swselservos<="100001";
     swgiroservos<="1001";
     --Stepmotor
     swgirostep<="001";
     --swgirostept<="000";
     swenable<='0';
     swdir <= '0';
     wait for 400 ms;
     --Servos
     swselservos<="010000";
     swgiroservos<="0001";
     --Stepmotor
     swgirostep<="000";
     --swgirostept<="000";
     swenable<='0';
     swdir <= '0';
     wait for 1 ms;
     --Servos
     swselservos<="001000";
     swgiroservos<="1000";
     --Stepmotor
     swgirostep<="100";
     --swgirostept<="000";
     swenable<='0';
     swdir <= '0';
     wait;
  end process;
        
end tb;
