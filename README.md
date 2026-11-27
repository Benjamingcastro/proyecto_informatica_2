Simulador de Onda Base y Perturbación por Pulso (Arduino + Processing)



Grafica una onda sinusoidal en tiempo real en Processing sobre fondo negro y suma una perturbación o variación de pulso al detectar el dedo en el sensor KY-039 con Arduino Uno, permitiendo escalar o acercar/alejar la gráfica con un potenciómetro.

Lista de materiales:
-> 1 arduino UNO
-> 1 Cable USB tipo B (el de impresora, para conectar el arduino con la pc)
-> 1 Protoboard
-> 1 sensor de pulso cardiaco KY-039
-> 1 Potenciometro
-> 1 Led, color a eleccion
-> 1 resistencia de 220 ohm, para la conexion del led
-> cables jumper :  macho - macho (6  aprox)
                    macho - hembra (3 aprox)
 a nivel software:
-> IDE Arduino
-> Processing
 
Conexiones (Arduino Uno)

Sensor KY-039: pin analógico `A1` (umbral de detección: `800`).

Potenciómetro: pin analógico `A0` (escala / zoom / amplitud de la gráfica).

LED indicador: pin digital `11` con resistencia a `GND` (estado de detección).



Estados principales

Estado base (`SIN\_DEDO`): onda sinusoidal en verde en tiempo real, escalada con el potenciómetro.

Estado alterado (`CON\_DEDO`): al superar el umbral, se suma la perturbación de pulso a la onda sinusoidal y cambia a rojo.


Diseño del circuito estilo tinkercad:
<img width="1536" height="598" alt="diseño del circuito" src="https://github.com/user-attachments/assets/7e4df57e-5f2f-45b8-b476-6e445697e0a8" />

Esquematico:
<img width="1008" height="582" alt="Captura de pantalla 2026-11-26 234801" src="https://github.com/user-attachments/assets/be4a2d5e-f7f4-45c9-a99f-09d2ecdb481f" />

 - Aclaración - Como el sensor de pulso, KY-039, no está disponible en la librería de Tinkercad, el diagrama esquemático emplea un transistor de tres terminales (T1) como sustituto de referencia para representar el conexionado de alimentación, masa y señal (conectada a A1), manteniendo el resto del circuito con el potenciómetro (RPOT1), el LED (D1) y su resistencia (R1).



