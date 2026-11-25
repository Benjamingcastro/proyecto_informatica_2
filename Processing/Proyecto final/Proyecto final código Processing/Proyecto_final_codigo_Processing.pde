import processing.serial.*;

// CLASE NODO: representa una muestra en la lista enlazada
class Nodo {
  float x;       // Posicion horizontal en pantalla (0 = izquierda, ancho = derecha)
  float valorY;  // Valor normalizado de la onda (senoidal + perturbacion simetrica)
  Nodo siguiente;

  Nodo(float x, float valorY) {
    this.x = x;
    this.valorY = valorY;
    this.siguiente = null;
  }
}

// CLASE LISTA ENLAZADA: historial deslizante de derecha a izquierda
class ListaEnlazada {
  Nodo cabeza;
  int cantidad;

  ListaEnlazada() {
    cabeza = null;
    cantidad = 0;
  }

  // Desplaza todos los nodos hacia la izquierda y elimina los que salen de x < 0
  void desplazarIzquierda(float deltaX) {
    while (cabeza != null && cabeza.x - deltaX < 0) {
      cabeza = cabeza.siguiente;
      cantidad = max(0, cantidad - 1);
    }

    Nodo actual = cabeza;
    while (actual != null) {
      actual.x -= deltaX;
      actual = actual.siguiente;
    }
  }

  // Inserta una nueva muestra al final (lado derecho)
  void agregarAlFinal(float x, float valorY) {
    Nodo nuevo = new Nodo(x, valorY);
    if (cabeza == null) {
      cabeza = nuevo;
    } else {
      Nodo actual = cabeza;
      while (actual.siguiente != null) {
        actual = actual.siguiente;
      }
      actual.siguiente = nuevo;
    }
    cantidad++;
  }

  // Devuelve el i-esimo nodo (0 a cantidad - 1)
  Nodo obtenerEn(int indice) {
    if (indice < 0 || indice >= cantidad) return null;
    Nodo actual = cabeza;
    int idx = 0;
    while (actual != null) {
      if (idx == indice) return actual;
      actual = actual.siguiente;
      idx++;
    }
    return null;
  }
}

// CLASE METODO NUMERICO: interpolacion lineal entre dos nodos
class MetodoNumerico {
  // y(x) = y1 + ((y2 - y1) / (x2 - x1)) * (x - x1)
  float interpolarLineal(float x, float x1, float y1, float x2, float y2) {
    if (abs(x2 - x1) < 1e-6) {
      return y1;
    }
    float t = (x - x1) / (x2 - x1);
    return y1 + t * (y2 - y1);
  }
}


// CLASE SIMULADOR ONDA: perturbacion simetrica centrada en el eje medio
class SimuladorOnda {
  ListaEnlazada muestras;
  MetodoNumerico metodo;
  int pasoMuestreo;      // Separacion horizontal entre nodos (en pixeles)
  float faseContinua;    // Fase temporal continua para la onda base
  int sensorAnterior;    // Ultima lectura del sensor para calcular variacion (delta)
  boolean tieneLecturaPrevia;

  SimuladorOnda(int pasoMuestreo) {
    this.pasoMuestreo = max(4, pasoMuestreo);
    this.muestras = new ListaEnlazada();
    this.metodo = new MetodoNumerico();
    this.faseContinua = 0;
    this.sensorAnterior = 0;
    this.tieneLecturaPrevia = false;
  }

  // Inicializa la cinta de nodos a lo largo de la ventana al arrancar
  void inicializarHistorial(int anchoVentana) {
    muestras.cabeza = null;
    muestras.cantidad = 0;
    faseContinua = 0;
    sensorAnterior = 0;
    tieneLecturaPrevia = false;

    for (int x = 0; x <= anchoVentana; x += pasoMuestreo) {
      float faseLocal = x * 0.035;
      float val = sin(faseLocal);
      muestras.agregarAlFinal(x, val);
    }
  }

  // Evalua la muestra en el borde derecho con aporte centrado en 0 y delta simetrico
  float evaluarMuestraDerecha(boolean hayDedo, int valorSensor) {
    faseContinua += 0.14;
    float senoidal = sin(faseContinua);

    float perturbacion = 0;
    if (hayDedo) {
      int lecturaAcotada = constrain(valorSensor, 950, 1023);

      // Centrado alrededor de 0 (-0.9 a +0.9) para no empujar la onda siempre hacia arriba
      float aporteNivel = map(lecturaAcotada, 950, 1023, -0.9, 0.9);

      // Variacion (delta) simetrica entre lecturas consecutivas
      float aporteDelta = 0;
      if (tieneLecturaPrevia) {
        int deltaSensor = valorSensor - sensorAnterior;
        if (abs(deltaSensor) >= 3) {
          aporteDelta = constrain(deltaSensor / 40.0, -1.8, 1.8);
        }
      }

      perturbacion = aporteNivel + aporteDelta;
    } else {
      tieneLecturaPrevia = false;
    }

    sensorAnterior = valorSensor;
    if (hayDedo) {
      tieneLecturaPrevia = true;
    }

    return senoidal + perturbacion;
  }

  // Avanza el historial hacia la izquierda e inserta la muestra nueva a la derecha
  void actualizarHistorial(int anchoVentana, boolean hayDedo, int valorSensor) {
    if (frameCount % 2 == 0) {
      muestras.desplazarIzquierda(pasoMuestreo);
      float nuevaMuestraY = evaluarMuestraDerecha(hayDedo, valorSensor);
      muestras.agregarAlFinal(anchoVentana, nuevaMuestraY);
    }
  }

  // Dibuja la onda interpolando linealmente entre cada par de nodos consecutivos
  void dibujar(String estadoArduino, int valorSensor, int valorPot, int anchoVentana, int altoVentana) {
    boolean hayDedo = estadoArduino.equals("CON_DEDO");
    float escala = map(valorPot, 0, 1023, 25, 115);

    actualizarHistorial(anchoVentana, hayDedo, valorSensor);

    // Linea central de referencia (eje 0 simetrico)
    stroke(60);
    line(0, altoVentana / 2.0, anchoVentana, altoVentana / 2.0);

    if (hayDedo) {
      stroke(255, 50, 50); // Rojo: con perturbacion simetrica del sensor
    } else {
      stroke(50, 255, 80); // Verde: onda base
    }

    noFill();
    beginShape();

    for (int i = 0; i < muestras.cantidad - 1; i++) {
      Nodo n1 = muestras.obtenerEn(i);
      Nodo n2 = muestras.obtenerEn(i + 1);
      if (n1 == null || n2 == null) continue;

      int xInicio = max(0, int(n1.x));
      int xFin = min(anchoVentana, int(n2.x));

      for (int x = xInicio; x <= xFin; x++) {
        float yInterpolado = metodo.interpolarLineal(x, n1.x, n1.valorY, n2.x, n2.valorY);
        float yPantalla = altoVentana / 2.0 - yInterpolado * escala;
        vertex(x, yPantalla);
      }
    }

    endShape();
  }
}

// PROGRAMA PRINCIPAL PROCESSING 
Serial puertoArduino;
SimuladorOnda simulador;

String estadoArduino = "SIN_DEDO";
int valorSensor = 0;
int valorPot = 512;
int estadoLed = 0;

void setup() {
  size(1000, 560);
  simulador = new SimuladorOnda(20);
  simulador.inicializarHistorial(width);

  println("Puertos disponibles:");
  printArray(Serial.list());

  if (Serial.list().length > 0) {
    puertoArduino = new Serial(this, Serial.list()[0], 9600);
    puertoArduino.bufferUntil('\n');
  }
}

void draw() {
  background(0);

  fill(255);
  textSize(14);
  text(
    "Estado: " + estadoArduino +
    " | Sensor: " + valorSensor +
    " | Pot: " + valorPot +
    " | LED: " + estadoLed +
    " | Nodos: " + simulador.muestras.cantidad,
    20, 28
  );

  simulador.dibujar(estadoArduino, valorSensor, valorPot, width, height);
}

void serialEvent(Serial p) {
  String linea = p.readStringUntil('\n');
  if (linea != null) {
    linea = trim(linea);
    String[] partes = split(linea, ',');
    if (partes.length == 4) {
      estadoArduino = partes[0];
      valorSensor = int(partes[1]);
      valorPot = int(partes[2]);
      estadoLed = int(partes[3]);
    }
  }
}

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
