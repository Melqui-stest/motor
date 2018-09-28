----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.09.2018 16:26:11
-- Design Name: 
-- Module Name: BRAZO_SERVOMOTOR_DEF - Behavioral
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
entity BRAZO_SERVOMOTOR_DEF is
Port ( --INPUTS
        clk : in std_logic;--Se�al de reloj de per�odo 10ns( mitad a 1 y mitad a 0)
        reset: in std_logic;--Reset del c�digo y se corresponde con el bot�n btnc de la FPGA.
        swselservos: in std_logic_vector(5 downto 0);--SW14 SW13 SW12 SW11 SW10-->Interruptores con los que se selecciona los servos correspondientes 
        ------------------------------------------------------------------------- a la articulaci�n en la que se quiera el movimiento 
        swgiroservos: in std_logic_vector(3 downto 0);--SW9 SW8 SW7 SW6-->Interruptores con los que se elige el angulo de giro del servo 
        ------swgiroservos----------Giro(�)
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
        JD: out std_logic_vector( 5 downto 0)--JD5 JD4 JD3 JD2 JD1 JD0-->Puerto de salida por donde se obtiene la se�al de control de cada servo.
        ---------------------------------------Cada pin de salida JDi se corresponde  con la se�al de control de un servo diferente.
        );

end BRAZO_SERVOMOTOR_DEF;

architecture Behavioral of BRAZO_SERVOMOTOR_DEF is
--Se�ales auxiliares para generar se�al s0con1ms
signal s0con1ms : std_logic; --Se�al con per�odo 0,1 ms
constant fincuenta0con1ms :natural:=10000;--Fin de cuenta para generar se�al de per�odo 0,1ms.
signal cuenta0con1ms: natural range 0 to 2**14-1;--Se�al que lleva la cuenta de los clk para obtener s0con1ms.
  -------------------------------------------------El rango es: fincuenta0con1ms=10.000<2^14
--Se�ales auxiliares para generar se�al s20ms
signal s20ms : std_logic;--Se�al con per�odo 20ms y f=50hz con ancho de pulso igual a un ciclo de clk(10n,)) creada a partir de la de 0,1ms
constant fincuenta20ms: natural:=200;----Fin de cuenta para generar se�al de per�odo 20ms.
signal cuenta20ms : natural range 0 to 2**8-1;--Se�al que lleva la cuenta de los ciclos de s0con1ms para obtener s20ms.
  -------------------------------------------------El rango es: fincuenta20ms=200<2^8
--Se�ales auxiliares para generar se�al s1ms
signal s1ms: std_logic; --Se�al con per�odo 1 ms creada a partir de la de 0,1ms
constant fincuenta1ms:natural:=10;----Fin de cuenta para generar se�al de per�odo 1ms
signal cuenta1ms: natural range 0 to 2**4-1;--Se�al que lleva la cuenta de los ciclos de s0con1ms para obtener s1ms.
  -------------------------------------------------El rango es: fincuenta1ms=10<2^4
--Se�al auxiliar digital que va a recibir el fin de cuenta correspondiente al giro deseado
signal fincuentasrelojt : unsigned(3 downto 0);
--Se�al auxiliar decimal que recibe el valor convertido del fin de cuenta, correspondiente al giro deseado que est� en binario.
signal fincuentasrelojtnat : natural range 0 to 2**4-1;
--Se�ales auxiliares para generar la se�al de control del motor
signal scontrolservo : std_logic; ---Se�al auxiliar que ser� la se�al de control del servo, y que ser� asignada a los puertos de salida JDi.

begin
--////////////////////////////P_conta0conmiliseg
--Mediante este proceso se implementa un contador,en el que mediante la se�al cuenta0con1ms, se cuentan los ciclos de reloj hasta que se alcancen 
--el nro correspondiente al fin de cuenta establecido(fincuenta0con1ms-1),que se corresponde con los ciclos de reloj necesarios para generar la se�al de 
--per�odo 0,1 ms y ancho de pulso un ciclo de reloj. El fin de cuenta establecido es el siguiente:
--clk-->f=100Mhz;T=10ns///s0con1ms-->T=0,1ms;f=10.000Hz// fincuenta0con1ms=100.000.000Hz/10.000=10.000
--Cuando la cuenta acaba se activa dicha se�al, que se reinicia en el siguiente ciclo de la clk. 
---Adem�s la cuenta se puede interrumpir mediante reset, reiniciando cuentas y se�ales, y poor tanto tamien la posici�n???????????????????
P_conta0con1miliseg:Process (reset, clk)
begin
 if reset='1' then
   cuenta0con1ms<=0;
   s0con1ms<='0';
 elsif clk'event and clk='1' then
   if cuenta0con1ms= fincuenta0con1ms-1 then
     cuenta0con1ms<=0;
     s0con1ms<='1';
   else 
     cuenta0con1ms<= cuenta0con1ms+1;
     s0con1ms<='0';
   end if;
 end if;
end process;

--/////////////////////////////P_conta20miliseg
--Mediante este proceso se implementa un contador,en el que mediante la se�al cuenta20ms, se cuentan los ciclos de subida de la se�al s0con1ms.
--Cada flanco de subida de s0con1ms, la cuenta se actualiza, hasta alcanzar el valor del fin de cuenta establecido(fincuenta20ms-1), que se corresponde
--con los ciclos de la se�al de per�odo 0,1 ms necesarios para generar la se�al de per�odo 20 ms(s20ms).El fin de cuenta establecido es el siguiente:
----s0con1ms-->T=0,1ms; f=10.000Hz///s20ms-->T=20ms;f=50Hz///fincuenta20ms=10.000Hz/50Hz=200.
--La cuenta de los ciclos de la se�al de per�odo 0,1ms, se encuentra adem�s sincronizada con la clk, de forma se actualiza con cada flanco de subida 
--de la clk. Mientras s0con1ms se encuentra en nivel bajo, s20ms recibe el valor bajo y la cuenta20ms guarda el valor anterior. 
--Cuando la cuenta acaba se activa dicha se�al(s20ms), que se reinicia en el siguiente ciclo de la clk.
---Adem�s la cuenta se puede interrumpir mediante reset, reiniciando cuentas y se�ales, y poor tanto tamien la posici�n???????????????????
P_conta20miliseg:Process (reset, clk)
begin
 if reset='1' then
   cuenta20ms<=0;
   s20ms<='0';
 elsif clk'event and clk='1' then
  s20ms<='0';
  if s0con1ms='1' then---
   if cuenta20ms= fincuenta20ms-1 then
     cuenta20ms<=0;
     s20ms<='1';
   else 
     cuenta20ms<= cuenta20ms+1;
     s20ms<='0';     
   end if;
  end if;
 end if;
end process;

--/////////////////////////////P_conta1miliseg
--Mediante este proceso se implementa un contador,en el que mediante la se�al cuenta1ms, se cuentan los ciclos de subida de la se�al s0con1ms.
--Cada flanco de subida de s0con1ms, la cuenta se actualiza, hasta alcanzar el valor del fin de cuenta establecido(fincuenta1ms-1), que se corresponde
--con los ciclos de la se�al de per�odo 0,1 ms necesarios para generar la se�al de per�odo 1 ms(s1ms).El fin de cuenta establecido es el siguiente:
----s0con1ms-->T=0,1ms; f=10.000Hz///s1ms-->T=1ms;f=1.000Hz///fincuenta1ms=10.000Hz/1.000Hz=10.
--La cuenta de los ciclos de la se�al de per�odo 0,1ms, se encuentra adem�s sincronizada con la clk, de forma se actualiza con cada flanco de subida 
--de la clk. Mientras s0con1ms se encuentra en nivel bajo, s1ms recibe el valor bajo y la cuenta20ms guarda el valor anterior. 
--Cuando la cuenta acaba se activa dicha se�al(s1ms), que se reinicia en el siguiente ciclo de la clk.Esta se�al no se utiliza para obtener la se�al de control
--pero nos sirve como indicaci�n de cada ms que transcurre para regular el ancho de pulso de la misma, para la cu�l si se utilizar� fincuent1ms.
---Adem�s la cuenta se puede interrumpir mediante reset, reiniciando cuentas y se�ales.
P_conta1miliseg:Process (reset, clk)
begin
 if reset='1' then
   cuenta1ms<=0;
   s1ms<='0';
 elsif clk'event and clk='1' then
  s1ms<='0';
  if s0con1ms='1' then--
   if cuenta1ms= fincuenta1ms-1 then
     cuenta1ms<=0;
     s1ms<='1';
   else 
     cuenta1ms<= cuenta1ms+1;
     s1ms<='0';
   end if;
  end if;
 end if;
end process;

--/////////////////////////////P_resoluciongiro
--En este proceso se implementa un mutiplexor mediante el cual se selecciona el fin de cuenta que se utilizar� en el proceso P_scontrol. En funci�n 
--Cada fin de cuenta "fincuentasrelojt" se corresponde con lo que ser� un �ngulo de giro diferente. 
--Estos fin de cuentas se han definido, en digital,con la consideracion de poder regular el ancho de pulso de una se�al con per�odo entre 0 y 1 ms.
--Por lo que teniendo en cuenta que para generar una se�al de per�odo 1ms, a partir de la cuenta de flancos de subida de una se�al de 0,1ms de per�odo
--(cuenta1ms),se ha necesitado un fin de cuenta(fincuenta1ms)de 10(en binario , se ha procedido a obtener el correspondiete fin de cuenta 
--en incrementos de 0,1 ms
----Ancho de pulso(t(ms))-----fincuentasrelojt
-----------0------------------------0000------
----------0,1-----------------------0001------
----------0,2-----------------------0010------
----------0,3-----------------------0011------
----------0,4-----------------------0100------
----------0,5-----------------------0101------
----------0,6-----------------------0110------
----------0,7-----------------------0111------
----------0,8-----------------------1000------
----------0,9-----------------------1001------
-----------1------------------------1010------
--Este fin de cuenta "fincuentasrelojt" viene determinado por el valor que se mande de la posici�n de los interruptores "swgiroservos".
--Con este fin de cuenta se consigue regular el ancho de pulso(TON) de la se�al de control, ya que siempre estar� entre 1 y 2ms.Por lo que con el
--correspondiente al giro que se quiera dar,seleccionado mediante "swgiroservos", y sumado al finde cuenta fijo que genera la se�al de 1ms de per�odo
--se conseguir� la se�al de control del servo con el ancho de pulso modulado, y que podremos cambiar con la posicion de los interruptores "swgiroservos".
P_resoluciongiro:Process(swgiroservos)--Multiplexor para seleccionar grados de giro
begin
   case swgiroservos is
     when "0000"=>
      fincuentasrelojt<="0000";--fin de cuenta para generar se�al de TON=1ms--0�
     when "0001"=>
      fincuentasrelojt<="0001";--fin de cuenta para generar se�al de TON=1,1ms--18�
     when "0010"=>
      fincuentasrelojt<="0010";--fin de cuenta para generar se�al de TON=1,2ms--36�
     when "0011"=>
      fincuentasrelojt<="0011";--fin de cuenta para generar se�al de TON=1,3ms--54�
     when "0100"=>
      fincuentasrelojt<="0100";--fin de cuenta para generar se�al de TON=1,4ms--72�
     when "0101"=>
      fincuentasrelojt<="0101";--fin de cuenta para generar se�al de TON=1,5ms--90�
     when "0110"=>
      fincuentasrelojt<="0110";--fin de cuenta para generar se�al de TON=1,6ms--108�
     when "0111"=>
      fincuentasrelojt<="0111";--fin de cuenta para generar se�al de TON=1,7ms--126�
     when "1000"=>
      fincuentasrelojt<="1000";--fin de cuenta para generar se�al de TON=1,8ms--144�
     when "1001"=>
      fincuentasrelojt<="1001";--fin de cuenta para generar se�al de TON=1,9ms--162�
     when "1010"=>
      fincuentasrelojt<="1010";--fin de cuenta para generar se�al de TON=2ms--180�
     when "01011"=>
       fincuentasrelojt<="1011";--fin de cuenta para generar se�al de TON=2,1ms--198�
      when "01100"=>
                  fincuentasrelojt<="1100";--fin de cuenta para generar se�al de TON=2,2ms--216�
      when "01101"=>
                  fincuentasrelojt<="1101";--fin de cuenta para generar se�al de TON=2,3ms--234�
     when "01110"=>
                   fincuentasrelojt<="1110";--fin de cuenta para generar se�al de TON=2,4ms--252�
      when "01111"=>
                   fincuentasrelojt<="1111";--fin de cuenta para generar se�al de TON=2,5ms--270�
--      when "10000"=>
--                                  fincuentasrelojt<="10000";--fin de cuenta para generar se�al de TON=2,6ms--288�
--        when "10001"=>
--                                    fincuentasrelojt<="10001";--fin de cuenta para generar se�al de TON=2ms--180�
--        when "10010"=>
--                                     fincuentasrelojt<="10010";--fin de cuenta para generar se�al de TON=2ms--180�                                                                                                                                                                   
--       when "10011"=>
--                                     fincuentasrelojt<="10011";--fin de cuenta para generar se�al de TON=2ms--180�     
       when others=>
      fincuentasrelojt<="0000";--fin de cuenta para generar se�al de TON=1ms--0�
    end case;
end process; 
--/////////////////////////////Conversi�n en decimal
--Como el valor del findecuenta que se selecciona antes mediante interruptores, est� en binario, para poder operar junto a "fincuenta1ms" que 
--est� en decimal, se convierte a este �ltimo mediante la funci�n to_integer.
fincuentasrelojtnat<=to_integer(fincuentasrelojt);

--/////////////////////////////P_scontrol
--Mediante este proceso se consigue generar la se�al de control final del servo, que recibe el nombre de "scontrolservo" y se le asignar� a 
--los puertos de salida JD. Esta se consigue haciendo una comparaci�n de la cuenta20ms que, que cuenta ciclos de la se�al de per�odo 0,1ms, con 
--la suma del fin de cuenta correspondiente para crear se�al de 1ms de per�odo(fincuenta1ms) m�s el fin de cuenta 
--correspondiente a la se�al variable de entre 0 y 1ms de per�odo(fincuentasrelojtnat). Mientras la suma de ambas sea menor que "cuenta20ms", la se�al
--de control del servo se encontrar� a 1 con el ancho de pulso correspondiente al giro que se quiera efectuar en el servo.
--Una vez supere su valor la se�al de control entrar� en su nivel bajo.
--Mediante reset se puede reiniciar dicha se�al.
P_scontrol:Process (reset, clk)
begin
 if reset='1' then
   scontrolservo<='0';
  elsif clk'event and clk='1' then
    if cuenta20ms<=(fincuenta1ms+fincuentasrelojtnat-1) then
      if s20ms='1' then  --generamos latch para guardar el valor anterior cuando s20ms no es 1
       scontrolservo<='1';
      end if;
    else 
      scontrolservo<='0';
    end if;
  end if;
  end process;
         
--////////////////////////P_seleccionmotor
--En este proceso se implementa un mutiplexor mediante el cual se selecciona qu� servos reciben la se�al de control modulada por ancho de pulso, a trav�s
--de la posici�n de los interruptores "swselservos" , correspondiendose cada uno a un servo diferente.
--El movimiento del brazo proporcionado por estos servos, se dar� articulacion por articulaci�n a trav�s de este proceso. De forma que con cada interruptor
--se activa un motor diferente, pero el movimiento s�lo se dar� en un articulacion a la vez. En caso de que se haya activado el movimiento de varias 
--articulaciones a la vez, tendr�n m�s prioridad de movimiento las articulaciones m�s cercanas al extremo fijo del brazo.
P_seleccionmotor:process(swselservos)
begin
if swselservos(0)='1' then       --Se activan los dos servos correspondientes al hombro, ya que realizan el mismo movimiento, y pertencen 
    JD(0)<=scontrolservo;        --a la misma articulaci�n.-->SERVOS 1 y 2
    JD(1)<=scontrolservo;
elsif swselservos(1)='1' then    --Se activa servo correspondiente al movimiento del codo.-->SERVO 3
    JD(2)<=scontrolservo;
elsif swselservos(2)='1' then    --Se activa servo correspondiente al movimiento de la mu�eca.-->SERVO 4
    JD(3)<=scontrolservo;
elsif swselservos(3)='1' then    --Se activa servo correspondiente al giro de la mano del robot.-->SERVO 5
    JD(4)<=scontrolservo;
elsif swselservos(4)='1' then    --Se activa servo correspondiente al movimiento de agarre de la pinza.-->SERVO 6
    JD(5)<=scontrolservo;
else                     --En caso de no estar ningun interruptor activo no se activa el movimiento de ningun motor.
    JD<="000000";
end if;
end process;

end Behavioral;
