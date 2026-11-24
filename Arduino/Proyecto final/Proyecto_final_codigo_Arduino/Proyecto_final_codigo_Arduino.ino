
const int PIN_POTENCIOMETRO = A0; // Entrada analogica A0: controla escala / zoom de la onda
const int PIN_SENSOR_KY039  = A1; // Entrada analogica A1: lectura del sensor optico KY-039
const int PIN_LED           = 11; // Salida digital 11: LED indicador del estado de deteccion

// PARAMETROS DE CONTROL Y TIEMPOS
const int UMBRAL_DEDO = 800; // A partir de este valor en A1 consideramos que hay un dedo puesto

// Cada cuantos milisegundos enviamos una linea de datos por Serial.
// Con 9600 baudios conviene un intervalo como 50 ms para no saturar el buffer.
const unsigned long INTERVALO_SERIAL_MS = 50;

// MAQUINA DE ESTADOS FINITOS (FSM)
enum EstadoDeteccion {
  SIN_DEDO, // Lectura menor a 800 
  CON_DEDO  // Lectura mayor o igual a 800 
};

// Modos del LED para permitir control desde Processing (comunicacion de ida y vuelta)
enum ModoLed {
  MODO_AUTO,         // El LED sigue al estado actual
  MODO_FORZADO_ON,   
  MODO_FORZADO_OFF   
};

// Variables de estado y ultimas lecturas
EstadoDeteccion estadoActual = SIN_DEDO;
ModoLed modoLed = MODO_AUTO;
//guarda las ultimas lecturas
int valorSensor = 0;          
int valorPot = 0;             
int estadoLedSalida = LOW;    
unsigned long ultimoEnvioMs = 0; 
String comandoEntrada = "";   // Acumula los caracteres que llegan desde la PC / Processing

// compara la lectura con el umbral
EstadoDeteccion evaluarEstado(int lecturaSensor) {
  if (lecturaSensor >= UMBRAL_DEDO) {
    return CON_DEDO;
  }
  return SIN_DEDO;
}

// Aplica el estado fisico al LED del pin 11 respetando el modo actual
void actualizarLed(EstadoDeteccion estado) {
  if (modoLed == MODO_FORZADO_ON) {
    estadoLedSalida = HIGH;
  } else if (modoLed == MODO_FORZADO_OFF) {
    estadoLedSalida = LOW;
  } else {
    // En modo automatico
    estadoLedSalida = (estado == CON_DEDO) ? HIGH : LOW;
  }

  digitalWrite(PIN_LED, estadoLedSalida);
}

// lee los datos enviados desde processing
void procesarComandoSerial(String cmd) {
  cmd.trim();        
  cmd.toUpperCase(); // Convierte a mayusculas para evitar problemas de mayusculas/minusculas

  if (cmd == "LED_ON") {
    modoLed = MODO_FORZADO_ON;
    Serial.println("ACK:LED_ON"); // Confirmamos a quien envio el comando
  } else if (cmd == "LED_OFF") {
    modoLed = MODO_FORZADO_OFF;
    Serial.println("ACK:LED_OFF");
  } else if (cmd == "AUTO") {
    modoLed = MODO_AUTO;
    Serial.println("ACK:AUTO");
  } else if (cmd == "PING") {
    Serial.println("PONG"); // Respuesta simple para comprobar que Arduino responde
  } else if (cmd.length() > 0) {
    // Si llego texto no vacio que no reconocemos, avisamos el error
    Serial.print("ERR:CMD_DESCONOCIDO:");
    Serial.println(cmd);
  }
}

// Lee caracteres hasta encontrarel fin de linea
void leerComandosSerial() {
  while (Serial.available() > 0) {
    char c = (char)Serial.read();

    if (c == '\n') {
      // limpia
      procesarComandoSerial(comandoEntrada);
      comandoEntrada = "";
    } else if (c != '\r') {
      
      comandoEntrada += c;
    }
  }
}

// Envia una linea de telemetria ESTADO,SENSOR,POTENCIOMETRO,LED
void enviarTelemetria() {
  const char* etiquetaEstado = (estadoActual == CON_DEDO) ? "CON_DEDO" : "SIN_DEDO";

  Serial.print(etiquetaEstado);
  Serial.print(",");
  Serial.print(valorSensor);
  Serial.print(",");
  Serial.print(valorPot);
  Serial.print(",");
  Serial.println(estadoLedSalida); // println agrega el '\n' final para marcar el fin de la trama
}

void setup() {
  pinMode(PIN_LED, OUTPUT);    // Configuramos el pin 11 como salida para el LED
  digitalWrite(PIN_LED, LOW);  // Arrancamos con el LED apagado
  Serial.begin(9600);          // Iniciamos comunicacion serie a 9600 baudios
}

void loop() {
  //Revisamos si llego algun comando desde la PC o Processing
  leerComandosSerial();

  //Leemos ambos sensores analogicos
  valorSensor = analogRead(PIN_SENSOR_KY039);
  valorPot = analogRead(PIN_POTENCIOMETRO);

  // Actualizamos la maquina de estados y el LED del pin 11
  estadoActual = evaluarEstado(valorSensor);
  actualizarLed(estadoActual);

  //Cada intervalo ms mandamos los datos actuales por Serial
  unsigned long ahora = millis();
  if (ahora - ultimoEnvioMs >= INTERVALO_SERIAL_MS) {
    ultimoEnvioMs = ahora;
    enviarTelemetria();
  }
}