import processing.serial.*; 

Serial puertoArduino;
String bufferLinea = "";

// Ultimos datos recibidos desde Arduino
String estadoArduino = "SIN_DEDO";
int valorSensor = 0;
int valorPot = 512;
int estadoLed = 0;

void setup() {
  size(800, 400);
  println("Puertos disponibles:");
  printArray(Serial.list());

  // Reemplaza Serial.list()[0] por el indice o nombre exacto de tu puerto COM
  if (Serial.list().length > 0) {
    puertoArduino = new Serial(this, Serial.list()[0], 9600);
    puertoArduino.bufferUntil('\n'); // Dispara serialEvent() cada vez que llega '\n'
  }
}

void draw() {
  background(0); // Fondo negro
  
fill(255);
textSize(14);
text("Estado: " + estadoArduino + " | Sensor: " + valorSensor + " | Pot: " + valorPot + " | LED: " + estadoLed, 20, 28);

//color de la onda
  if (estadoArduino.equals("CON_DEDO")) {
    stroke(255, 50, 50);//rojo
  } else {
    stroke(50, 255, 80);//verde
  }

  // altura de la onda
  float escala = map(valorPot, 0, 1023, 20, 140);
//tipo de onda
  noFill();
  beginShape();
  for (int x = 0; x < width; x++) {
    float angulo = TWO_PI * x / 180.0 + frameCount * 0.05;
    float y = height / 2.0 - sin(angulo) * escala;
    vertex(x, y);
  }
  endShape();
}

// Se ejecuta automaticamente cuando llega una linea terminada en '\n' desde Arduino
void serialEvent(Serial p) {
  String linea = p.readStringUntil('\n');
  if (linea != null) {
    linea = trim(linea); // Quita espacios, '\r' y '\n'
    String[] partes = split(linea, ',');

    // Esperamos exactamente 4 campos: ESTADO,SENSOR,POTENCIOMETRO,LED
    if (partes.length == 4) {
      estadoArduino = partes[0];
      valorSensor = int(partes[1]);
      valorPot = int(partes[2]);
      estadoLed = int(partes[3]);
    }
  }
}

// comunicacion processing a arduino
void keyPressed() {
  if (puertoArduino == null) return;

  if (key == '1') {
    puertoArduino.write("LED_ON\n");
  } else if (key == '2') {
    puertoArduino.write("LED_OFF\n");
  } else if (key == '0') {
    puertoArduino.write("AUTO\n");
  }
}
