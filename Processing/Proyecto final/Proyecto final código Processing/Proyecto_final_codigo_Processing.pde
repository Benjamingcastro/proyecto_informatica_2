import processing.serial.*;

// ==========================================
// CLASE NODO: unidad basica de la lista enlazada
// Guarda una muestra discreta (posicion x y valor y) y el enlace al siguiente nodo.
// ==========================================
class Nodo {
  float x;      
  float valorY;  
  Nodo siguiente; 

  Nodo(float x, float valorY) {
    this.x = x;
    this.valorY = valorY;
    this.siguiente = null;
  }
}

// CLASE LISTA ENLAZADA: estructura dinamica de muestras en orden temporal/espacial
class ListaEnlazada {
  Nodo cabeza;  // Primer nodo de la lista (extremo izquierdo visible)
  int cantidad; // Cantidad actual de nodos almacenados

  ListaEnlazada() {
    cabeza = null;
    cantidad = 0;
  }


  void desplazarIzquierda(float deltaX) {
    // Elimina desde la cabeza los nodos que tras moverse quedan fuera del borde izquierdo
    while (cabeza != null && cabeza.x - deltaX < 0) {
      cabeza = cabeza.siguiente;
      cantidad = max(0, cantidad - 1);
    }

    // Recorre la lista y actualiza la posicion horizontal de cada muestra restante
    Nodo actual = cabeza;
    while (actual != null) {
      actual.x -= deltaX;
      actual = actual.siguiente;
    }
  }

  // Inserta un nuevo nodo al final de la lista (borde derecho de la ventana)
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

  // Devuelve el nodo ubicado en la posicion 'indice' (0 a cantidad - 1)
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

// CLASE METODO NUMERICO: calculo numerico aplicado al trazado de la curva
// Implementa interpolacion lineal entre dos nodos consecutivos (x1, y1) y (x2, y2).
class MetodoNumerico {
  // Formula de interpolacion lineal: y(x) = y1 + ((y2 - y1) / (x2 - x1)) * (x - x1)
  float interpolarLineal(float x, float x1, float y1, float x2, float y2) {
    // Evita division por cero si dos nodos comparten la misma coordenada x
    if (abs(x2 - x1) < 1e-6) {
      return y1;
    }
    float t = (x - x1) / (x2 - x1); // Parametro normalizado entre 0 y 1 dentro del intervalo
    return y1 + t * (y2 - y1);
  }
}

// CLASE SIMULADOR ONDA: integra señal base, perturbacion del sensor, lista e interpolacion

class SimuladorOnda {
  ListaEnlazada muestras;      // Historial de muestras
  MetodoNumerico metodo;        // Calculadora numerica para reconstruir valores intermedios
  int pasoMuestreo;             // Separacion horizontal entre nodos consecutivos 
  float faseContinua;           // Fase acumulada para generar la onda sinusoidal base
  int sensorAnterior;           // Lectura previa del sensor para calcular variacion (delta)
  boolean tieneLecturaPrevia; // Indica si ya existe una muestra previa valida en estado CON_DEDO

  SimuladorOnda(int pasoMuestreo) {
    this.pasoMuestreo = max(4, pasoMuestreo);
    this.muestras = new ListaEnlazada();
    this.metodo = new MetodoNumerico();
    this.faseContinua = 0;
    this.sensorAnterior = 0;
    this.tieneLecturaPrevia = false;
  }

  // Carga una onda sinusoidal inicial a lo largo del ancho de la ventana
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

  // Calcula el valor normalizado de la nueva muestra que entra por la derecha
  float evaluarMuestraDerecha(boolean hayDedo, int valorSensor) {
    faseContinua += 0.14;
    float senoidal = sin(faseContinua); // Señal base oscilante

    float perturbacion = 0;
    if (hayDedo) {
      int lecturaAcotada = constrain(valorSensor, 800, 1023);

      // Aporte centrado en 0 (-0.9 a +0.9) para mantener simetria respecto al eje medio
      float aporteNivel = map(lecturaAcotada, 800, 1023, -0.9, 0.9);

      // Aporte por variacion (delta) respecto a la lectura anterior del sensor
      float aporteDelta = 0;
      if (tieneLecturaPrevia) {
        int deltaSensor = valorSensor - sensorAnterior;
        if (abs(deltaSensor) >= 0.5) { // Umbral minimo para filtrar micro-ruidos
          aporteDelta = constrain(deltaSensor / 2.0, -5, 5);
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

  // Avanza el historial hacia la izquierda y agrega una muestra nueva en el borde derecho
  void actualizarHistorial(int anchoVentana, boolean hayDedo, int valorSensor) {
    if (frameCount % 2 == 0) {
      muestras.desplazarIzquierda(pasoMuestreo);
      float nuevaMuestraY = evaluarMuestraDerecha(hayDedo, valorSensor);
      muestras.agregarAlFinal(anchoVentana, nuevaMuestraY);
    }
  }

  // Dibuja el eje central, interpola entre nodos y renderiza la onda en pantalla
  void dibujar(String estadoArduino, int valorSensor, int valorPot, int anchoVentana, int altoVentana) {
    boolean hayDedo = estadoArduino.equals("CON_DEDO");
    float escala = map(valorPot, 0, 1023, 25, 115); // Ganancia vertical controlada por el potenciometro

    actualizarHistorial(anchoVentana, hayDedo, valorSensor);

    // Eje horizontal de referencia en el centro de la ventana
    stroke(60);
    line(0, altoVentana / 2.0, anchoVentana, altoVentana / 2.0);

    // Cambio visual de color segun el estado reportado por Arduino
    if (hayDedo) {
      stroke(255, 50, 50); // Rojo cuando hay dedo detectado
    } else {
      stroke(50, 255, 80); // Verde en estado base (sin dedo)
    }

    noFill();
    beginShape();

    // Recorre cada par de nodos consecutivos (n1, n2) e interpola pixel a pixel entre ellos
    for (int i = 0; i < muestras.cantidad - 1; i++) {
      Nodo n1 = muestras.obtenerEn(i);
      Nodo n2 = muestras.obtenerEn(i + 1);
      if (n1 == null || n2 == null) continue;

      int xInicio = max(0, int(n1.x));
      int xFin = min(anchoVentana, int(n2.x));

      for (int x = xInicio; x <= xFin; x++) {
        float yInterpolado = metodo.interpolarLineal(x, n1.x, n1.valorY, n2.x, n2.valorY);
        // En Processing el eje Y crece hacia abajo, por eso se resta al centro altoVentana / 2.0
        float yPantalla = altoVentana / 2.0 - yInterpolado * escala;
        vertex(x, yPantalla);
      }
    }

    endShape();
  }
}

// PROGRAMA PRINCIPA
// Gestiona ventana, comunicacion Serial, telemetria y comandos de teclado

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
    puertoArduino.bufferUntil('\n'); // Dispara serialEvent al recibir un salto de linea
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

// Lee y parsea tramas CSV enviadas por Arduino: ESTADO,SENSOR,POT,LED
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

// Envia comandos de control hacia Arduino segun la tecla presionada
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
