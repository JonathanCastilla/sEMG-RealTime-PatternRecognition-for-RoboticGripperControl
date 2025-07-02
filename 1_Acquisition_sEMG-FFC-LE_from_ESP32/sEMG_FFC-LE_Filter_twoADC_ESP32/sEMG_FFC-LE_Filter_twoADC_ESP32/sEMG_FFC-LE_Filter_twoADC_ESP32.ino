#include "esp32-hal-timer.h"
#include "EMGFilters.h"

EMGFilters myFilter1;
EMGFilters myFilter2;

// Asegúrate de usar los valores correctos definidos por el enum en EMGFilters.h
SAMPLE_FREQUENCY sampleRate = SAMPLE_FREQ_1000HZ;
NOTCH_FREQUENCY humFreq = NOTCH_FREQ_60HZ;

#define SensorInputPin1 36 // Usa un pin ADC válido en la ESP32
#define SensorInputPin2 39 // Usa otro pin ADC válido en la ESP32

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
int sample1 = 0; // inicializar muestra adquirida
int sample2 = 0; // inicializar muestra adquirida
int last_sample1 = ADC_range_ESP32 / 2; // establecer última muestra
int last_sample2 = ADC_range_ESP32 / 2; // establecer última muestra
int ds1 = 0; // inicializar la diferencia entre dos muestras sucesivas
int ds2 = 0; // inicializar la diferencia entre dos muestras sucesivas
int64_t  S1 = 0; // inicializar la suma del Promedio Móvil
int64_t  S2 = 0; // inicializar la suma del Promedio Móvil
int win_size_bits = 6; // Número de potencia de corrimiento de bits (2^6) para desplazamiento de bits en vez de realizar la división (Reducción de costo computacional) 
unsigned int win_len = pow(2, win_size_bits); // longitud de la ventana para computar EMG-LE (potencia de 2)
unsigned int EMG_level1 = 0; // inicializar el nivel de actividad EMG
unsigned int EMG_level2 = 0; // inicializar el nivel de actividad EMG
int64_t  ACC1 = 0L; // inicializar acumulador
int64_t  ACC2 = 0L; // inicializar acumulador

volatile bool newDataReady = false;
int sampleToPrint1 = 0;
int sampleToPrint2 = 0;
int sampleFFCToPrint1 = 0;
int sampleFFCToPrint2 = 0;
unsigned int EMG_levelToPrint1 = 0;
unsigned int EMG_levelToPrint2 = 0;
/*
FILTRO MEDIA MÓVIL (MOVIL AVERAGE)
Filtro de 20 coeficientes
*/
// arreglo de 20 elementos para implementar un filtro de Promedio Móvil de 20 coeficientes
int MAv1[20] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int MAv2[20] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

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

  /* CANAL 1: PIN ADC GPIO36 */
  // Leer la señal sEMG cruda actual
  int sampleBeforeFilter1 = analogRead(SensorInputPin1); // En ESP32 se usa un pin ADC adecuado, como GPIO36
  sample1 = myFilter1.update(sampleBeforeFilter1); // Procesamiento del filtro
  ds1 = sample1 - last_sample1; // Computar la diferencia entre dos muestras sucesivas
  // Actualizar la suma del Promedio Móvil (Movil Average)
  S1 = S1 - MAv1[k];
  MAv1[k] = ds1;
  S1 = S1 + MAv1[k];
  // Actualizar el acumulador
  ACC1 = ACC1 + abs(S1);
  // Actualizar la última muestra
  last_sample1 = sample1;

  /* CANAL 2 */
  // Leer la señal sEMG cruda actual
  int sampleBeforeFilter2 = analogRead(SensorInputPin2); // En ESP32, se usa un pin ADC adecuado, como GPIO39
  sample2 = myFilter2.update(sampleBeforeFilter2); // Procesamiento del filtro
  ds2 = sample2 - last_sample2; // Computar la diferencia entre dos muestras sucesivas
  // Actualizar la suma del Promedio Móvil (Movil Average)
  S2 = S2 - MAv2[k];
  MAv2[k] = ds2;
  S2 = S2 + MAv2[k];
  // Actualizar el acumulador
  ACC2 = ACC2 + abs(S2);
  // Actualizar la última muestra
  last_sample2 = sample2;

  // Actualizar el contador del Promedio Móvil (Movil Average)
  if (k < 19) {
    k = k + 1;
  } else {
    k = 0;
  }

  // Actualizar el reloj
  clk = clk + 1;

/*
  // Computar EMG-LE aplicando un promedio móvil (Movil Average) con una ventana de 128 muestras en el valor absoluto del EMG filtrado por el filtro FFC.
  // La división por 128 (2^7) se realiza desplazando el bit string (que representa la variable EMG_level) 7 posiciones a la derecha.
*/

  if (clk >= win_len) {
    EMG_level1 = ACC1 >> win_size_bits;
    EMG_level2 = ACC2 >> win_size_bits;
    // Reiniciar el acumulador y el reloj
    ACC1 = 0;
    ACC2 = 0;
    clk = 0;
  }

  // Almacenar valores en variables temporales
  sampleFFCToPrint1 = S1;
  sampleToPrint1 = sample1;
  EMG_levelToPrint1 = EMG_level1;
  sampleFFCToPrint2 = S2;
  sampleToPrint2 = sample2;
  EMG_levelToPrint2 = EMG_level2;
  newDataReady = true;  // Bandera para indicar que hay datos nuevos
}

void setup() {
  Serial.begin(115200);

  // conectar la salida sEMG cruda del sensor analógico sEMG a la entrada de tipo analógica
  pinMode(SensorInputPin1, INPUT);
  pinMode(SensorInputPin2, INPUT);

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
  if (newDataReady) {
    //Serial.print(sampleToPrint1);
    //Serial.print(" ");
    //Serial.print(sampleFFCToPrint1);
    //Serial.print(" ");
    Serial.print(EMG_levelToPrint1);
    Serial.print(" ");
    //Serial.print(sampleToPrint2);
   // Serial.print(" ");
    //Serial.print(sampleFFCToPrint2);
    //Serial.println(sampleFFCToPrint2);
    //Serial.print(" ");
    Serial.println(EMG_levelToPrint2);
    newDataReady = false;  // Resetear bandera después de imprimir
  }
}
