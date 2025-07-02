#include "esp32-hal-timer.h"
#include "EMGFilters.h"

EMGFilters myFilter;

// Asegúrate de usar los valores correctos definidos por el enum en EMGFilters.h
SAMPLE_FREQUENCY sampleRate = SAMPLE_FREQ_1000HZ;
NOTCH_FREQUENCY humFreq = NOTCH_FREQ_60HZ;

#define SensorInputPin 36 // Usa un pin ADC válido en la ESP32

// Declarar temporizador
hw_timer_t * timer = NULL;
volatile SemaphoreHandle_t timerSemaphore;
portMUX_TYPE timerMux = portMUX_INITIALIZER_UNLOCKED;

volatile uint32_t isrCounter = 0;
volatile uint32_t lastIsrAt = 0;

// Calibración
static int Threshold = 25;
int ADC_range_ESP32 = 4096;

// Declarar variables globales
unsigned int clk = 0; // inicializar reloj
unsigned int k = 0; // inicializar contador
int sample = 0; // inicializar muestra adquirida
// Punto de partida central en el rango de lectura analógica de la ESP32
int last_sample = ADC_range_ESP32 / 2; // establecer última muestra
int ds = 0; // inicializar la diferencia entre dos muestras sucesivas
int64_t  S = 0; // inicializar la suma del Promedio Móvil
int win_size_bits = 6; // Número de potencia de corrimiento de bits (2^6) para desplazamiento de bits en vez de realizar la división (Reducción de costo computacional) 
unsigned int win_len = pow(2, win_size_bits); // longitud de la ventana para computar EMG-LE (potencia de 2)
unsigned int EMG_level = 0; // inicializar el nivel de actividad EMG
int64_t  ACC = 0L; // inicializar acumulador

volatile bool newDataReady = false;
int sampleToPrint = 0;
int lastSampleToPrint = 0;
int sampleFFCToPrint = 0;
unsigned int EMG_levelToPrint = 0;
/*
FILTRO MEDIA MÓVIL (MOVIL AVERAGE)
Filtro de 20 coeficientes
*/
// arreglo de 20 elementos para implementar un filtro de Promedio Móvil de 20 coeficientes
int MAv[20] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
//int MAv[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

/* 
FUNCIÓN EMG_LE():
// 1) Muestreo de la señal EMG cruda proporcionada por el sensor EMG (por ejemplo, MyoWare Muscle Sensor);
// 2) Aplicar el filtro Feed-Forward Comb (FFC) (utilizado para eliminar interferencias de línea eléctrica y artefactos de movimiento)
// 3) Computar el EMG-LE
La función es activada (ejecutada) por el interrupción del temporizador
*/

void ARDUINO_ISR_ATTR EMG_LE(){
  // Increment the counter and set the time of ISR
  portENTER_CRITICAL_ISR(&timerMux);
  isrCounter = isrCounter + 1;
  lastIsrAt = millis();
  portEXIT_CRITICAL_ISR(&timerMux);
  // Give a semaphore that we can check in the loop
  xSemaphoreGiveFromISR(timerSemaphore, NULL);
  // It is safe to use digitalRead/Write here if you want to toggle an output

  // Leer la señal EMG cruda actual
  int sampleBeforeFilter = analogRead(SensorInputPin); // En ESP32, usa un pin ADC adecuado, como GPIO36
  // sample = analogRead(SensorInputPin); // En ESP32, usa un pin ADC adecuado, como GPIO36

  // Procesamiento del filtro
  sample = myFilter.update(sampleBeforeFilter);

  // Computar la diferencia entre dos muestras sucesivas
  ds = sample - last_sample;

  // Actualizar la suma del Promedio Móvil (Movil Average)
  S = S - MAv[k];
  MAv[k] = ds;
  S = S + MAv[k];

  // Actualizar el contador del Promedio Móvil (Movil Average)
  if (k < 19) {
    k = k + 1;
  } else {
    k = 0;
  }

  // Actualizar el acumulador
  ACC = ACC + abs(S);

  // Actualizar la última muestra
  last_sample = sample;

  // Actualizar el reloj
  clk = clk + 1;

/*
  // Computar EMG-LE aplicando un promedio móvil (Movil Average) con una ventana de 128 muestras en el valor absoluto del EMG filtrado por el filtro FFC.
  // La división por 128 (2^7) se realiza desplazando el bit string (que representa la variable EMG_level) 7 posiciones a la derecha.
*/

  if (clk >= win_len) {
    EMG_level = ACC >> win_size_bits;
    // Reiniciar el acumulador y el reloj
    ACC = 0;
    clk = 0;
  }

  // Enviar por el puerto serie la señal EMG-LE para ser utilizada en el control de Interfaces Hombre-Máquina (HMI)
  //Serial.print(sample);
  //Serial.print(" ");
  //Serial.println(EMG_level);

  // Almacenar valores en variables temporales
  sampleFFCToPrint = S;
  sampleToPrint = sample;
  //lastSampleToPrint = last_sample;
  EMG_levelToPrint = EMG_level;
  newDataReady = true;  // Bandera para indicar que hay datos nuevos
}

void setup() {
  Serial.begin(115200);

  // conectar la salida RAW del sensor EMG a la entrada analógica - pin GPIO36
  pinMode(36, INPUT);

  // Create semaphore to inform us when the timer has fired
  timerSemaphore = xSemaphoreCreateBinary();

  // Set timer frequency to 1Mhz
  timer = timerBegin(1000000);
  // Attach onTimer function to our timer.
  timerAttachInterrupt(timer, &EMG_LE);
  // Set alarm to call onTimer function every second (value in microseconds).
  // Repeat the alarm (third parameter) with unlimited count = 0 (fourth parameter).
  timerAlarm(timer, 833, true, 0);
}

void loop() {
  // If Timer has fired
  //while(1){}
  if (newDataReady) {
        Serial.print(sampleToPrint);
        Serial.print(" ");
        Serial.print(sampleFFCToPrint);
        Serial.print(" ");
        Serial.println(EMG_levelToPrint);
        newDataReady = false;  // Resetear bandera después de imprimir
    }
};