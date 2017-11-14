----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.11.2017 16:35:21
-- Design Name: 
-- Module Name: simmotor - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity simmotor is
--  Port ( );
end simmotor;

architecture tb of simmotor is
component motor
Port(   clk : in std_logic;
        btn0: in std_logic;-- será el reset(btnc)
        btn1 : in std_logic;--control de la dirección(btnU)
        swt5: in std_logic;--enable--desactiva todo
        swt : in std_logic_vector( 2 downto 0);--control del micropaso ms
        sw: in std_logic_vector(10 downto 8);
        --swt8:in std_logic;--a 1 seleccion para que de 1 paso
        --swt9:in std_logic;--a 1 seleccion para que de 10 pasos
        --swt10:in std_logic;--a 1 seleccion para que de 100 pasos
        ---ms : out std_logic_vector( 2 downto 0);
        ms1: out std_logic; --led 0
        ms2 : out std_logic; --led 1
        ms3 : out std_logic; --led 2
        dir: out std_logic; -- 0 gira sentido horario y 1 sentido antihorario --led 4
        step : out std_logic -- señal para cada micropaso--led5
     );
 end component;
--Inputps
signal clk : std_logic;
signal btn0: std_logic;-- será el reset(btnc)
signal btn1 : std_logic;--control de la dirección(btnU)
signal swt5: std_logic;--enable--desactiva todo
signal  swt : std_logic_vector( 2 downto 0);--control del micropaso ms
signal  sw: std_logic_vector(10 downto 8);
--Outputs
signal ms1: std_logic; --led 0
signal   ms2 : std_logic; --led 1
signal   ms3 : std_logic; --led 2
signal  dir: std_logic; -- 0 gira sentido horario y 1 sentido antihorario --led 4
signal step : std_logic; -- señal para cada micropaso--led5

begin
UnidadenPruebas : motor
Port Map(
 clk => clk,
 btn0 => btn0,
 btn1 => btn1,
 swt5 => swt5,
 swt => swt,
 sw => sw,
 ms1 => ms1,
 ms2 => ms2,
 ms3 => ms3,
 dir => dir,
 step => step
);
P_clk:process
 begin
 clk <='0';
 wait for 10 ns;
 clk <='1';
 wait for 10 ns;
 end process;
P_reset:process
  begin
  btn0 <='1';
  wait for 100 ns;
  btn0 <='0';
  sw<="001";
  swt<="111";
  swt5<='0';
  wait for 1000 ns;
  sw<="001";
  swt<="101";
  swt5<='1';
  wait for 1 ms;
  sw<="001";
  swt<="010";
  swt5<='0';
  wait for 1 ms;
   sw<="100";
   swt<="000";
   swt5<='0';
  wait;
end process;
end tb;
