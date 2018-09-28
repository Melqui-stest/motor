----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.09.2018 16:37:07
-- Design Name: 
-- Module Name: BRAZO_DEF - Behavioral
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
entity BRAZO_DEF is
  Port (
          clk : in std_logic;--Señal de reloj de período 10ns( mitad a 1 y mitad a 0)
          reset: in std_logic;--Reset del código y se corresponde con el botón btnc de la FPGA.
  --------------------SERVOMOTOR
          --INPUTS
          swselservos: in std_logic_vector(5 downto 0);--SW14 SW13 SW12 SW11 SW10-->Interruptores con los que se selecciona los servos correspondientes 
          ------------------------------------------------------------------------- a la articulación en la que se quiera el movimiento 
          swgiroservos: in std_logic_vector(3 downto 0);--SW9 SW8 SW7 SW6-->Interruptores con los que se elige el angulo de giro del servo 
          ------swgiroservos----------Giro(º)
          --------0000------------------0---
          --------0001------------------18--
          --------0010------------------36--
          --------0011------------------54--
          --------0100------------------72--
          --------0101------------------90--
          --------0110------------------108--
          --------0111------------------126-
          --------1000------------------144-
          --------1001------------------162-
          --------1010------------------180-
          --OUTPUTS
          JD: out std_logic_vector( 5 downto 0);--JD5 JD4 JD3 JD2 JD1 JD0-->Puerto de salida por donde se obtiene la señal de control de cada servo.
          ---------------------------------------Cada pin de salida JDi se corresponde  con la señal de control de un servo diferente.
      
  --------------------STEPMOTOR
          --INPUTS
          swdir : in std_logic;--SW0-->Control de la dirección de giro.
          swenable: in std_logic;--SW5-->Interruptor enable--desactiva todo
          swoff: in std_logic;--SW4-->Activa o desactiva movimiento sin tocar el enable, por que si activas el enable deja de haber movimiento
          ----------------------------pero tambien fuerza desactiva movimiento pero mantiene fuerza.
          swgirostep: in std_logic_vector(2 downto 0);--SW3 SW2 SW1-->Interruptores con los que se ajusta el paso deseado(control del giro)
                          ---swgirostep    fincuenta     giro(º)
                          ---000    0              0
                          ---001    150.000      15
                          ---010    300.000      30
                          ---011    450.000      45
                          ---100    600.00       60
                          ---101    750.000      75
                          ---110    900.000      90
                          ---111    1.800.000    180
          --OUTPUTS
          enable: out std_logic;--JC1-->Señal con la que se desactiva el motor
          dir: out std_logic; -- JC3-->Señal con la que se establece el la dirección de giro del motor(0 en sentido horario y 1 en sentido antihorario)
          step : out std_logic --JC2-->Señal periódica, con la que cada período se consigue un giro del motor de un micropaso.
          -----------------------------En el caso en el que su valor sea cero, el giro del motor estará desactivado. 
           );
end BRAZO_DEF;

architecture Structural of BRAZO_DEF is
component BRAZO_STEPMOTOR_DEF
 Port(
      clk : in std_logic;
      reset: in std_logic;-- será el reset(btnc)-btn0
      swdir : in std_logic;--control de la dirección--swt0
      swenable: in std_logic;--enable--desactiva todo
      swoff: in std_logic;--boton para activar o desactivar movimmiento sin tocar el enable, por que si activas el enable deja de haber movimiento pero tambien fuerza
     --desactiva movimiento pero mantiene fuerza
      swgirostep: in std_logic_vector(2 downto 0);--control del giro
      enable: out std_logic;--led0
      dir: out std_logic; -- 0 gira sentido horario y 1 sentido antihorario --led 4
      step : out std_logic -- señal para cada micropaso--led5     
      );
 end component;
 
 component BRAZO_SERVOMOTOR_DEF
  Port(
       clk : in std_logic;
       reset: in std_logic;-- será el reset(btnc)-btn0
       swselservos: in std_logic_vector(5 downto 0);
       swgiroservos: in std_logic_vector(3 downto 0);--ELECCION DE GIRO
       JD: out std_logic_vector( 5 downto 0)
       );
  end component;
-----Servomotor
---- Inputs
--  signal clk : std_logic;
--  signal reset: std_logic;-- será el reset(btnc)
--  signal swselservos : std_logic_vector(5 downto 0);
--  signal  swgiroservos: std_logic_vector(3 downto 0);
--  --Outputs
--  signal JD: std_logic_vector( 5 downto 0);
----Stepmotor
----Inputps
----signal clk : std_logic;
----signal reset: std_logic;-- será el reset(btnc)
--signal swdir : std_logic;--control de la dirección(btnU)
--signal swenable: std_logic;--enable--desactiva todo
--signal swoff: std_logic;--enable--desactiva todo
--signal swgirostep:  std_logic_vector(2 downto 0);--control del giro
----Outputs
--signal  dir: std_logic; -- 0 gira sentido horario y 1 sentido antihorario --led 4
--signal step : std_logic; -- señal para cada micropaso--led5
--signal enable: std_logic;--led0
begin
Portmap_stepmotor: BRAZO_STEPMOTOR_DEF
Port map (
            clk     =>  clk,
            reset   =>  reset,
            swdir  =>  swdir,
            swenable    =>  swenable,
            swoff    =>  swoff,
            swgirostep      =>  swgirostep,
            enable  =>  enable,
            dir     =>  dir,
            step    =>  step
          );
          
Portmap_servomotor: BRAZO_SERVOMOTOR_DEF
Port map (
            clk     =>  clk,
            reset   =>  reset,
            swselservos     =>  swselservos,
            swgiroservos     =>  swgiroservos,
            JD      =>  JD
           );
end Structural;
