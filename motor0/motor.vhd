--Diseño del programa de control de motor paso a paso mediante FPGA, placa ramps y dirve pololu
--Se podrá ajustar el tamaño de paso con el que se quiere hacer girar el motor(1 micropaso(1,8º);1/2 micropaso;1/4 micropaso; 1/8 micropasos;1/16 micropasos)
--Tambien tenemos la orden para dar 1 paso(360º) completo seguido, 10 pasos y 100 pasos.
--Control de la direccion???.-

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity motor is
 Port ( clk : in std_logic;
        btn0: in std_logic;-- será el reset(btnc)
        btn1 : in std_logic;--control de la dirección(btnU)
        swt5: in std_logic;--enable--desactiva todo
        swt : in std_logic_vector( 2 downto 0);--control del micropaso ms
        sw: in std_logic_vector(2 downto 0);
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
end motor;

architecture Behavioral of motor is
--Señales auxiliares que serán asignadas a los puertos salidas ms1 ms2 ms3
  signal ms: std_logic_vector( 2 downto 0);
--Para s1microseg
  signal cuenta100 : natural range 0 to 2**7-1;
  constant cienfincuenta: natural:=100;
  signal s1microseg: std_logic; --señal con periodo 1 microsegundo.
--Señal axiliar sstep que será asignada al puerto salida señal step
  signal sstep: std_logic;
  signal sstepgiro: std_logic; --señal que enlazará con la sstep en el multiplexor
--Señal auxiliar s1micropaso--indica que el motor esta funcionando
  signal s1micropaso: std_logic;
--Para s200ns
    signal cuenta5 : natural range 0 to 2**3-1;
    constant cincofincuenta: natural:=5;
    signal s200ns: std_logic; --señal con periodo 200 ns.
--Para detector de flancos de btn1
    signal btn1reg1 : std_logic;
    signal btn1reg2 : std_logic;
    signal pulsobtn1 : std_logic;
--Señales para la seleccion del nro de pasos a dar: para 1 paso completo=360º
   signal cuentamicropasos: natural  range 0 to 2**22-1;--cuenta se hace en grados pero tendremos decimales en nuestra cuenta
   signal fincuentapasos: natural range 0 to 2**29-1;--deberia ser una cte???
    --max valor 100pasosx360ºx10.000=360.000.000<2**29
        --360ºx10.000x1paso-1girocompleto=1paso
        --360ºx10.000x10pasos-1girocompleto=10pasos
        --360ºx10.000x100pasos-1girocompleto=100pasos
   signal sgiro: std_logic;-- señal que se pone a 1 cuando termina el giro especificado--para que el motor se pare; si esta en 0 sigue contando pasos y motor gira al ritmo de s1micropasos
   signal res: natural range 0 to 2**15-1;--deberia ser una cte???
   --la resolucion de los micropasos(micropasox10.000)--max:1,8x10.000=18.000<2**15-min;(1,8/16)x10.000=1125<2**11
   
   --Señal auxiliarpara dir
   signal sdir: std_logic;
begin
P_conta1microseg:Process (btn0, clk)
begin
 if btn0='1' then
   cuenta100<=0;
   s1microseg<='0';
   s1micropaso<='0';
 elsif clk'event and clk='1' then
   if cuenta100= cienfincuenta-1 then
     cuenta100<=0;
     s1microseg<='1';
     s1micropaso<= not s1micropaso;
   else 
     cuenta100<= cuenta100+1;
     s1microseg<='0';
     --s1micropaso se guarda valor anterior no ha pasado microsegundo=biestable
   end if;
 end if;
end process;
-- s1microseg<='1' when cuenta100= cienfincuenta-1 then s1microseg='1' else '0';
-- s1micropaso<= not s1micropaso when s1microseg='1' else s1micropaso;

--//////////////////////////////////////////
--Multiplexor para on/off del motor
sstepgiro <= '0' when sgiro='1' else s1micropaso;--Si el giro ha terminado sgiro=1 y motor se para
sstep <= '0' when swt5='1' else sstepgiro; --Si giro no ha terminado sgiro=0 y swt=0 (enable=0) el motor gira(señal s1micropaso=step)
step<=sstep;
--/////////////////////////////////////////

--P_conta200ns:Process (btn0, clk)
--begin
-- if btn0='1' then
--   cuenta5<=0;
--   s200ns<='0';
-- elsif clk'event and clk='1' then
--   if cuenta5= cincofincuenta-1 then
--     cuenta5<=0;
--     s200ns<='1';
--   else 
--     cuenta5<= cuenta5+1;
--     s200ns<='0';
--   end if;
-- end if;
--end process;
--Proceso detector de flancos btn1(del control de la direccion)
biest_detectorflancos: Process ( btn0, clk)--Para btnr
begin
 if btn0 = '1' then
  btn1reg1 <= '0';
  btn1reg2 <= '0';
 elsif Clk'event and Clk='1' then
  btn1reg1 <= btn1;
  btn1reg2 <= btn1reg1;
 end if;
end process;
pulsobtn1 <= '1' when (btn1reg1 = '1' and btn1reg2='0') else '0';
--Proceso direccion
P_direccion:Process(clk,btn0)
begin
 if btn0='1' then 
   sdir<='0';--por defecto gira a la derecha(horario)
 elsif clk'event and clk='1' then
   if s1micropaso='1' then --iria retrasado un ciclo clk respecto s1micropaso,
      if btn1='1' then -- y solo se puede cambiar de direccion mientras el inicio de un nuevo paso(1 de s1micropaso)
        sdir<='1';--si se activa btn1 cambia a girar a la izqda(antihorario)
      else
       sdir<='0';
      end if;
    end if;
 end if;
end process; 
dir<=sdir;
--Proceso resolución de los micropasos.
P_resolucionmicropasos:Process(clk,btn0)
begin
 if btn0='1' then 
   ms<="000";
 elsif clk'event and clk='1' then
  if sstep='1' then--solo se puede elegir la resolucion cuando el motor este on
   if swt="000" then
     ms<="000";--1paso
   elsif swt="001" then
     ms<="100";--medio paso
   elsif swt="010" then
     ms<="010";--cuarto de paso
   elsif swt="011" then
     ms<="110";--octavo de paso
   elsif swt="100" then
     ms<="111";--1 decimoseisavo de paso  
     ----generamos latch al no cubrir posibilidad exlcluyente guardando asi el ultimo valor
    end if;
  end if;
 end if;
end process; 

ms1<=ms(2);
ms2<=ms(1);
ms3<=ms(0);
P_nropasos:Process(clk,btn0)
begin
 if btn0='1' then 
   cuentamicropasos<=0;
   sgiro<='0';
 elsif clk'event and clk='1' then
  if s1micropaso='1' then --iria retrasado un ciclo clk respecto s1micropaso,
    if cuentamicropasos=fincuentapasos-1 then
     cuentamicropasos <=0;
     sgiro<='1';
    else 
     cuentamicropasos<= cuentamicropasos+res ;--la cuenta de los micropasos se suma en funcion de la resolucion elegida
     sgiro<='0';
    end if;
  end if;
 end if;
end process;
P_resolmicropasosparacuentanumeroropasos:process(clk,btn0)
begin
if btn0='1' then 
   res<=0;
 elsif clk'event and clk='1' then
  if sstep='1' then--solo se puede elegir la resolucion cuando el motor este on
    if  swt= "000" then
    res<=(0);--1paso
    elsif  swt= "001" then
    res<=(18000);--1paso
    elsif  swt= "010" then
    res<=(9000);--medio paso
    elsif  swt= "011" then
    res<=(4500);--cuarto de paso
    elsif  swt= "100" then
    res<=(2250);--octavo de paso
    elsif  swt= "101" then
    res<=(1125);--1 decimoseisavo de paso  
     ----generamos latch al no cubrir posibilidad exlcluyente guardando asi el ultimo valor
    end if;
  end if;
 end if;
end process;
--////////////////////////////////////////
P_seleccionumeropasos:Process(clk,btn0)
begin
if btn0='1' then 
   fincuentapasos<=3600000;
 elsif clk'event and clk='1' then
  if sstep='1' then--solo se puede elegir la resolucion cuando el motor este on
   if sw="000"then
    fincuentapasos<=(0);
   elsif sw="001"then
    fincuentapasos<=(3600000);--1paso
   elsif sw="010"then
    fincuentapasos<=(36000000);--10 pasos
   elsif sw="011"then
    fincuentapasos<=(360000000);--100 pasos  
     ----generamos latch al no cubrir posibilidad exlcluyente guardando asi el ultimo valor
    end if;
  end if;
 end if;
end process;
--////////////////////////////////////////////////////////////////
end Behavioral;
