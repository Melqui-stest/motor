----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.09.2018 17:52:56
-- Design Name: 
-- Module Name: BRAZO_STEPMOTOR_DEF - Behavioral
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

entity BRAZO_STEPMOTOR_DEF is
Port ( --INPUTS
       clk : in std_logic;--Señal de reloj de período 10ns( mitad a 1 y mitad a 0)
       reset: in std_logic;--Reset del código y se corresponde con el botón btnc de la FPGA
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
end BRAZO_STEPMOTOR_DEF;

architecture Behavioral of BRAZO_STEPMOTOR_DEF is
--Para generar s1microseg
  signal cuenta100 : natural range 0 to 2**17-1;--Señal que lleva la cuenta de los clk para obtener s1microseg.
  ------------------------------------------------El rango es: cienfincuenta=100.000<2^17
  constant cienfincuenta: natural:=100000;--Fin de cuenta para generar señal de período 1 microsegundo
  signal s1microseg: std_logic; --Señal con periodo 1 microsegundo.
--Señal auxiliar s1micropaso
  signal s1micropaso: std_logic;--señal que tiene valor de un microseg a 1 y un microseg a 0, con la que cada ciclo de esta(2microsegundos)
  --------------------------------el motor gira un micropaso.
--Para step
  signal sstep: std_logic;--Señal axiliar sstep que será asignada al puerto salida señal step
  signal sstepgiro: std_logic; --Señal que enlazará con la sstep en el multiplexor cuando se mantenga el giro.
--Para detector de flancos de btn1
    signal btn1reg1 : std_logic;
    signal btn1reg2 : std_logic;
    signal pulsobtn1 : std_logic;
--Señales para la seleccion del nro de pasos a dar: para 1 paso completo=360º
  signal fincuentapasos: natural range 0 to 2**29-1;--deberia ser una cte???
  -----------------------------------------------------señal a la que se le asigna el fin de cuenta para generar el giro reuqerido.
  -----------------------------------------------------Giro máximo=90º-->máximo valor de fincuentapasos=160.000.000< 2^28 (rango)
  signal cuentamicropasos: natural  range 0 to 2**29-1;--cuenta se hace en grados pero tendremos decimales en nuestra cuenta
  -----------------------------------------------------señal que lleva la cuenta de los clk para que el motor gire en micropasos(0,1125º)
  -----------------------------------------------------hasta el giro seleccionado(máximo 90º)--rango igual que fincuentapasos, pues es el máximo 
  -----------------------------------------------------valor que puede tomar
  signal zfincuentapasos: natural range 0 to 2**29-1;--deberia ser una cte???
  -----------------------------------------------------Señal retrasada un clk respecto fincuentapasos a la que se le  asigna su valor, 
  -----------------------------------------------------por lo que tienen el mismo rango.
  signal sgiro: std_logic;-- señal que se pone a 1 cuando termina el giro especificado--para que el motor se pare; si esta en 0 sigue contando pasos y motor gira al ritmo de s1micropasos.
--Para dir
  signal sdir: std_logic;--Señal auxiliar que tendrá el valor de la direccion y se le asignará a dir.
  
begin
--/////////////////////////////////////////Proceso s1micropaso
--Con este proceso mediante un contador se obtiene la señal que da lugar al giro de 1 micropaso(0,1125º)
--Se actualiza la cuenta100 cada clk, hasta alcanzar el fin de cuenta (cienfincuenta) que es el correspondiente para generar la señal de período 
--1microsegundo. 
----clk-->f=100Mhz;T=10ns///s1microseg-->T=1micros;f=1.000.000Hz// fincuenta0con1ms=100.000.000Hz/1.000.000=100
----Dicho valor se tomó como inicial pero el movimiento del motor era demasiado brusco y se saturaba.
----Se optó por aumentar el fin de cuenta 100 veces mas, de modo que: fincuenta0con1ms=100.000.000 con la que conseguía un movimiento más controlado.
----Esto se debe porque se aumenta tanto el período como el ancho de pulso 100 veces, de forma que la cuenta tarda más en completarse, consiguiéndose asi
----un movimiento más lento.
--Y mediante un biestable T, se crea la señal s1micropaso, en el que cada 1 microsegundo se niega el valor anterior de esta, obteniendo
--la señal s1micropaso, 1microseg a 1 y otro a 0, que es la que da lugar al giro de 1 micropaso, posteriormente se le asignará a step cuando se requiera
--el giro del motor.
P_conta1microseg:Process (reset, clk)
begin
 if reset='1' then
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

--/////////////////////////////////////////ON/OFF del motor(P_step)
--Se implementa mediante dos multiplexores conectados en cascada
sstepgiro <= '0' when sgiro='1' else s1micropaso;--Esta sentencia implementa el primer multiplexor, en el que
---------------------------------------------------si el giro ha terminado(sgiro=1) el motor se para(sstepgiro=0), y si no ha terminado(sgiro=0)
---------------------------------------------------la señal sstegiro recibe los valores de s1micropaso y el motor sigue girando.
---------------------------------------------------La salida sstepgiro de este multiplexor es entrada de otro multiplexor,que es el de la siguiente sentencia
sstep <= '0' when swoff='1' else sstepgiro; --------En este se implementa la opción de parar el giro(salida sstep=0) en cualquier momento, 
---------------------------------------------------activando swt 4(swoff=1) manteniendo la fuerza del motor.Si dicho interruptor está apagado, la señal de salida
---------------------------------------------------sstep recibe el valor de la salida del primer multiplexor(sstepgiro), por lo que gire o no 
---------------------------------------------------depende de lo que se seleccione en las entradas del primero.

--Si giro no ha terminado sgiro=0 y swt=0 (enable=0) el motor gira(señal s1micropaso=step)
step<=sstep;

--///////////////////////////////////////ENABLE del motor
enable<=(swenable);--La salida enable activa o desactiva directamente el motor.Ésta vendrá dada por el valor que tome el interruptor (swenable).
-----------------Pues si se activa, enable tomará el valor de 1 y el motor se desactivará. Si se mantiene a 0 el motor sigue en funcionamiento.

--/////////////////////////////////////////Proceso de selección de la dirección del motor
P_direccion:Process(clk,reset)------En este proceso mediante un biestable se consigue el cambio en la direccion de giro del motor.
------------------------------------De tal forma que en cada flanco de subida de la señal del reloj, la direccion de giro se actualiza.
begin-------------------------------En el caso de que el interruptor de la direccion(swt0dir=1) se active, la señal auxiliar de la direccion también
------------------------------------se activará, y con ello la señal de salida dir, proporcionando un giro antihorario en el motor.Por defecto si 
------------------------------------el interruptor está apagado(swt0dir=0) o se resetea el control, dir valdrá 0 y el giro del  motor será horario.
 if reset='1' then 
   sdir<='0';--Por defecto gira a la derecha(horario)
 elsif clk'event and clk='1' then
      if swdir='1' then 
        sdir<='1';--Si se activa btn1 cambia a girar a la izqda(antihorario)
      else
       sdir<='0';
      end if;
    --end if;
 end if;
end process; 
dir<=sdir;
--///////////////////////////////////////Proceso para generar el giro requerido
--Mediante este proceso se implementa un contador,en el que mediante la señal cuentamicropasos,se cuentan los ciclos de reloj hasta que se alcancen 
--el nro correspondiente al findecuenta establecido(fincuentapasos-1), para dar el giro requerido. Cuando esta cuenta acaba se activa una señal
--sgiro que indica que el giro seleccionado ha acabado, por lo que el motor para como se estableció en las sentencias ON/OFF del motor.
--La cuenta se reinica cuando se selecciona un nuevo fincuentapasos, es decir, se selecciona un nuevo paso y el giro del motor se activa hasta completarlo.
P_nropasos:Process(clk,reset)
begin
 if reset='1' then 
   cuentamicropasos<=0;
   sgiro<='0';
 elsif clk'event and clk='1' then
    if cuentamicropasos=fincuentapasos-1 then
     sgiro<='1';--Giro completado
     if fincuentapasos/= zfincuentapasos then --Cuenta se reinicia cuando se cambia el valor de fin de cuenta que será cuando se mandé 
     --orden de otro giro estableciendo un nuevo valor de fincuentapasos, diferente al de zfincuentapasos ya que guarda el valor anterior de 
     --fincuentapasos, porque va retrasado un ciclo de reloj.
        cuentamicropasos <=0;
     end if;
    else 
     cuentamicropasos<= cuentamicropasos+1 ;--Cuenta de los micropasos cuenta cada clk
     --El giro se dará por micropasos, en funcion de la resolución elegida hasta que complete el establecido por el fincuentapasos.
     --Para nuestro caso serán micropasos de :(1/16)*1,8º=0,1125º-->que se corresponde con la cuenta de 200.000 clk 
     --Por lo que angulo de giro a dar se ajustará con fincuentapasos.Por ej: 0,1125º*10=1,125º--200.000clk*10=2.000.000clk
     sgiro<='0';            
     if fincuentapasos/= zfincuentapasos then --Cuenta se reinicia cuando se cambia el valor de fin de cuenta al igual que antes.
        cuentamicropasos <=0;
     end if;
    end if;
  end if;
end process;

--////////////////////////////////////////--Reinicio de cuentas
P_Reinic:Process(reset,clk)--En este proceso se reinicia el findecuenta seleccionado, como medida si se requiere volver a efectuar el giro,
-----------------------------se quiere cambiar a otro angulo de giro diferente y no ha terminado el anterior, o se quiere volver a la pposicion anterior para cambiar giro??????? 
begin------------------------se consigue implementando un biestable, de forma que se pone a 1 la señal zfincuentapasos cuando se activa el reset y, 
 if reset='1' then-----------cuando se comienza a contar ciclos de reloj de nuevo, se le vuelve a asignar la el findecuenta selecciionado(señal fincuentapasos).
 zfincuentapasos<=1;
 elsif clk'event and clk='1' then
  zfincuentapasos<=fincuentapasos;
 end if;
end process;

--////////////////////////////////////////--Selección de giro
--Se implementa un multiplexor mediante el que se selecciona el angulo de giro del motor, sin olvidar que el paso de giro elegido será efectuado en micropasos de 0,1125º
-----1/16 de paso=0,1125º--El fin de cuenta para efectuar este micropaso--seria 200.000, es decir, 
-----necesita contar 200.000 clk(mitad a 0 mitad a 1) para conseguir este giro.
-----Por lo que si multiplicamos podemos obtener giros adecuados para mover nuestro robot.
--------0,1125ºx100=11,25º  --> fin de cuenta=200.000x100=20.000.000
--------0,1125ºx200=22,5º   --> fin de cuenta=200.000x200=40.000.000
--------0,1125ºx300=33,75º  --> fin de cuenta=200.000x300=60.000.000
--------0,1125ºx400=45º     --> fin de cuenta=200.000x400=80.000.000
--------0,1125ºx500=56,25º  --> fin de cuenta=200.000x500=100.000.000
--------0,1125ºx600=67,5º   --> fin de cuenta=200.000x600=120.000.000
--------0,1125ºx700=78,75º  --> fin de cuenta=200.000x700=140.000.000
--------0,1125ºx800=90º     --> fin de cuenta=200.000x800=160.000.000
--La suma de los micropasos de 0,1125º dará lugar el paso de giro el que aparece a continuacion.
fincuentapasos<=20000000    when swgirostep="000" else  --11,25º   
                40000000    when swgirostep="001" else  --22,5º   
                60000000    when swgirostep="010" else  --33,75º   
                80000000    when swgirostep="011" else  --45º  
                100000000   when swgirostep="100" else  --56,25º 
                120000000   when swgirostep="101" else  --67,5º  
                140000000   when swgirostep="110" else  --78,75º
                160000000;                      --90º
                --En el caso de que no quiera que el motor gire(0º) pero mantenga su fuerza se consigue con swoff=1
end Behavioral;
