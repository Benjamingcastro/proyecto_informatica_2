Simulador de Onda Base y Perturbación por Pulso (Arduino + Processing)



Grafica una onda sinusoidal en tiempo real en Processing sobre fondo negro y suma una perturbación o variación de pulso al detectar el dedo en el sensor KY-039 con Arduino Uno, permitiendo escalar o acercar/alejar la gráfica con un potenciómetro.



Conexiones (Arduino Uno)

Sensor KY-039: pin analógico `A1` (umbral de detección: `800`).

Potenciómetro: pin analógico `A0` (escala / zoom / amplitud de la gráfica).

LED indicador: pin digital `11` con resistencia a `GND` (estado de detección).



Estados principales

Estado base (`SIN\_DEDO`): onda sinusoidal en verde en tiempo real, escalada con el potenciómetro.

Estado alterado (`CON\_DEDO`): al superar el umbral, se suma la perturbación de pulso a la onda sinusoidal y cambia a rojo.


Diseño del circuito estilo tinkercad:
<img width="1536" height="598" alt="diseño del circuito" src="https://github.com/user-attachments/assets/7e4df57e-5f2f-45b8-b476-6e445697e0a8" />

