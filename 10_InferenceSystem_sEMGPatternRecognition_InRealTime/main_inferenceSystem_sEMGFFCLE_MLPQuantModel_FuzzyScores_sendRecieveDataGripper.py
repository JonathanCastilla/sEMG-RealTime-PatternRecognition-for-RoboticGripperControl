# Importación de bibliotecas necesarias
import os
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
# Deshabilitar el manejo de Ctrl+C en Fortran
os.environ['FOR_DISABLE_CONSOLE_CTRL_HANDLER'] = '1'

import pandas as pd
import time
import serial  # Biblioteca para la comunicación serial con la ESP32
import numpy as np  # Biblioteca para realizar operaciones matemáticas y numéricas
from collections import deque  # Estructura de datos eficiente para el manejo de ventanas deslizantes
import time  # Biblioteca para manejar tiempos de espera
import tensorflow as tf  # Biblioteca para cargar y trabajar con modelos de redes neuronales
from tensorflow import keras
# from keras.models import load_model  # Función para cargar el modelo previamente entrenado
from queue import Queue  # Cola para compartir datos entre hilos
import threading  # Biblioteca para manejar hilos
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
# from scipy import stats
import math
# import signal
import sys
import atexit
# import ctypes
import csv
from collections import defaultdict

# IMPORTACIÓN DE ARCHIVOS CON FUNCIONES AUXILIARES PARA EL SISTEMA DE INFERENCIA EN TIEMPO REAL 

from fuzzyClassifierWithScores_sEMG_FFC_LE import infer_class as fuzzy_predict # Importación de función de inferencia del clasificador de tipo difuso
from featuresFunctions_for_sEMG_FFC_LE_inference import compute_dasdv, compute_iemg, compute_variance, compute_wl, compute_mwl
from export_results_as_csv_files_sEMG_FFC_LE import create_results_folders, to_export_labels_csv, to_export_data_from_plot_csv, to_export_history_to_excel, to_export_data_from_robotic_gripper_csv, to_export_calibration_data_for_inference
from plot_data_results_for_inference_sEMG_FFC_LE import plot_data_and_save_plot

# ======== FUNCIONES AUXILIARES ========
def min_max_normalization(data, X_min, X_max):
    """
    Aplica la normalización Min-Max a cada columna del conjunto de datos usando un único valor de X_min y X_max.

    Parámetros:
        data (numpy.ndarray): Matriz de datos donde cada fila es un segmento y cada columna es una característica.
        X_min (float): Valor mínimo para la normalización (se aplica a todas las columnas).
        X_max (float): Valor máximo para la normalización (se aplica a todas las columnas).

    Retorna:
        normalized_data (numpy.ndarray): Matriz de datos normalizada.
    """
    # Evitar división por cero en caso de que X_min == X_max
    if X_max == X_min:
        raise ValueError("X_max no puede ser igual a X_min (división por cero).")

    # Aplicar la normalización Min-Max
    normalized_data = (data - X_min) / (X_max - X_min)
    return normalized_data


def normalize_features_GlobalMinMaxNormalization(globalMinMaxValuesNormalization, features_FDS, features_EDC):
    """
    Normaliza las características de FDS y EDC utilizando normalización Min-Max.
    Parámetros:
        minMaxValuesNormalization (tuple): Tupla con los valores mínimos y máximos para la normalización.
        features_FDS (numpy.ndarray): Características del músculo FDS.
        features_EDC (numpy.ndarray): Características del músculo EDC.
    Retorna:
        numpy.ndarray: Un array con las características normalizadas de FDS y EDC combinadas.
    """
    X_min_valuesNom = globalMinMaxValuesNormalization[0]
    X_max_valuesNom = globalMinMaxValuesNormalization[1]


    # Normalizar características para FDS
    iemg_nom_FDS = min_max_normalization(features_FDS[0], X_min_valuesNom[0], X_max_valuesNom[0])          # IEMG
    wl_nom_FDS = min_max_normalization(features_FDS[1], X_min_valuesNom[1], X_max_valuesNom[1])        # MWL
    mwl_nom_FDS = min_max_normalization(features_FDS[2], X_min_valuesNom[2], X_max_valuesNom[2])   # WL
    variance_nom_FDS = min_max_normalization(features_FDS[3], X_min_valuesNom[3], X_max_valuesNom[3])           # Variance
    dasdv_nom_FDS = min_max_normalization(features_FDS[4], X_min_valuesNom[4], X_max_valuesNom[4])          # DASDV
    # kurtosis_nom_FDS = min_max_normalization(features_FDS[5], X_min_valuesNom_FDS[5], X_max_valuesNom_FDS[5])     # Curtosis

    # Normalizar características para EDC
    iemg_nom_EDC = min_max_normalization(features_EDC[0], X_min_valuesNom[0], X_max_valuesNom[0])          # IEMG
    wl_nom_EDC = min_max_normalization(features_EDC[1], X_min_valuesNom[1], X_max_valuesNom[1])        # MWL
    mwl_nom_EDC = min_max_normalization(features_EDC[2], X_min_valuesNom[2], X_max_valuesNom[2])   # WL
    variance_nom_EDC = min_max_normalization(features_EDC[3], X_min_valuesNom[3], X_max_valuesNom[3])           # Variance
    dasdv_nom_EDC = min_max_normalization(features_EDC[4], X_min_valuesNom[4], X_max_valuesNom[4])          # DASDV
    # kurtosis_nom_EDC = min_max_normalization(features_EDC[5], X_min_valuesNom_EDC[5], X_max_valuesNom_EDC[5])     # Curtosis

    # Concatenar las características normalizadas de FDS y EDC en un solo vector de salida
    features_normalized = np.array([iemg_nom_EDC, wl_nom_EDC, mwl_nom_EDC, variance_nom_EDC, dasdv_nom_EDC,
                                    iemg_nom_FDS, wl_nom_FDS, mwl_nom_FDS, variance_nom_FDS, dasdv_nom_FDS])
    
    return features_normalized


def extract_features(window, X_min_sEMGsignal, X_max_sEMGsignal):
    """
    Extrae características estadísticas (Varianza, Desviación Estándar, DASDV, SSI, WL, Curtosis) de la ventana de datos
    tanto para el músculo FDS como para el músculo EDC.
    Parámetros:
        window (numpy.ndarray): Ventana de datos con 2 filas (sEMG_FFC_FDS, sEMG_FFC_EDC)
        y 297 columnas (muestras) de datos.
    Retorna:
        numpy.ndarray: Un vector de 12 características extraídas (6 para FDS, 6 para EDC).
    """
    # Obtener la señal del músculo FDS (primera fila)
    sEMG_FDS_window = window[0, :]
    sEMG_FDS_nom_window = min_max_normalization(sEMG_FDS_window, X_min_sEMGsignal, X_max_sEMGsignal)
    
    # Calcular características para FDS
    iemg_FDS = compute_iemg(sEMG_FDS_nom_window)              # IEMG
    wl_FDS = compute_wl(sEMG_FDS_nom_window)        # WL
    mwl_FDS = compute_mwl(sEMG_FDS_nom_window)  # MWL
    variance_FDS = compute_variance(sEMG_FDS_nom_window)    # Variance
    dasdv_FDS = compute_dasdv(sEMG_FDS_nom_window)            # DASDV
    
    # Obtener la señal del músculo EDC (segunda fila)
    sEMG_EDC_window = window[1, :]
    sEMG_EDC_nom_window = min_max_normalization(sEMG_EDC_window, X_min_sEMGsignal, X_max_sEMGsignal)
    
    # Impresión de prueba
    # print([sEMG_EDC_nom_window, sEMG_FDS_nom_window])

    # Calcular características para EDC
    iemg_EDC = compute_iemg(sEMG_EDC_nom_window)              # IEMG
    wl_EDC = compute_wl(sEMG_EDC_nom_window)        # WL
    mwl_EDC = compute_mwl(sEMG_EDC_nom_window)  # MWL
    variance_EDC = compute_variance(sEMG_EDC_nom_window)            # Variance
    dasdv_EDC = compute_dasdv(sEMG_EDC_nom_window)            # DASDV

    # Retornar las características de FDS y EDC como dos arrays separados
    features_FDS = np.array([iemg_FDS, wl_FDS, mwl_FDS, variance_FDS, dasdv_FDS])
    features_EDC = np.array([iemg_EDC, wl_EDC, mwl_EDC, variance_EDC, dasdv_EDC])
    
    return features_FDS, features_EDC

def normalizeMinMax_sEMG_LEpercentileValue(window, X_min_sEMGsignal, X_max_sEMGsignal):
    """
    Normalización de las ventanas de recorrido de las señales de ambos canales analógicos: EDC y FDS
    """
    # Obtener la señal del músculo FDS (primera fila)
    sEMG_FDS_window = window[0, :]
    sEMG_FDS_nom_window = min_max_normalization(sEMG_FDS_window, X_min_sEMGsignal, X_max_sEMGsignal)
    sEMG_FDS_nom_perValue = np.percentile(sEMG_FDS_nom_window, 75)

    # Obtener la señal del músculo EDC (segunda fila)
    sEMG_EDC_window = window[1, :]
    sEMG_EDC_nom_window = min_max_normalization(sEMG_EDC_window, X_min_sEMGsignal, X_max_sEMGsignal)
    sEMG_EDC_nom_perValue = np.percentile(sEMG_EDC_nom_window, 75)

    return sEMG_FDS_nom_perValue, sEMG_EDC_nom_perValue
    

# Función para capturar el valor máximo global (FDS o EDC)
def capture_max_value(duration=7, biasMaxValue_segurity_range = 100):
    print(f"Por favor, realice la extensión máxima durante {duration} segundos...")
    max_global = 0  # Inicializar en 0
    start_time = time.time()
    
    while time.time() - start_time < duration:
        if not data_queue.empty():
            values = data_queue.get()
            current_max = max(values)  # Tomar el mayor entre FDS y EDC
            if current_max > max_global:
                max_global = current_max  # Actualizar si es mayor
    
    max_global += biasMaxValue_segurity_range
    print(f"Valor máximo global capturado: {max_global}")
    return max_global


def capture_bias_REP(duration=7):
    """Calcula el bias (EDC - FDS) promedio durante 'duration' segundos."""
    print(f"Calculando bias_REP_analog_channel (EDC - FDS) durante {duration} segundos...")
    bias_values_EDC = []
    bias_values_FDS = []
    start_time = time.time()
    
    while time.time() - start_time < duration:
        if not data_queue.empty():
            fds, edc = data_queue.get()
            bias_values_FDS.append(fds)
            bias_values_EDC.append(edc)
    
    if not bias_values_EDC and not bias_values_FDS:
        return 1,1  # Evitar división por cero

    bias_REP_analog_channel_EDC = round(np.percentile(bias_values_EDC, 75)) # Q3: Valor del tercer cuartil de los datos que caracterizan el reposo en el EDC
    bias_REP_analog_channel_FDS = round(np.percentile(bias_values_FDS, 75)) # Q3: Valor del tercer cuartil de los datos que caracterizan el reposo en el FDS
    print(f" bias_REP_analog_channel calculado: {bias_REP_analog_channel_EDC, bias_REP_analog_channel_FDS }")
    return bias_REP_analog_channel_EDC, bias_REP_analog_channel_FDS


def capture_gain_from_channel_REP(bias_REP_analog_channel_EDC, bias_REP_analog_channel_FDS):
    """Calcula la proporción de ganancia entre los canales EDC y FDS para estabilizarlos en 
     gesto de reposo capturado en 'duration' segundos."""
    
    print(f"\nCalculando gain_from_analog_channel_REP en EDC y FDS ...")
    duration = 1
    time.sleep(duration)

    # Se supone una ganancia de 1 para ambos canales
    gain_for_EDC_channel = 1
    gain_for_FDS_channel = 1

    if bias_REP_analog_channel_EDC > bias_REP_analog_channel_FDS:
        gain_for_FDS_channel = math.ceil(bias_REP_analog_channel_EDC / bias_REP_analog_channel_FDS) + 1
    else:
        gain_for_EDC_channel = round(bias_REP_analog_channel_FDS / bias_REP_analog_channel_EDC)
   
    print(f"\ngain_from_analog_channel_REP (FDS, EDC): {gain_for_FDS_channel, gain_for_EDC_channel }")
    return gain_for_EDC_channel, gain_for_FDS_channel


def delay_with_message(duration=10, message="Inicio de recepción de datos y sistema de inferencia"):
    """Muestra un mensaje y espera 'duration' segundos antes de continuar"""
    print(f"\n{message} en {duration} segundos...")
    time.sleep(duration)
    print("Sistema listo para procesamiento en tiempo real\n")

# ======

# ========== IMPORTACIÓN DE DATOS NUMPY PARA NORMALIZACIÓN EN TIEMPO REAL =========

X_min_sEMGsignal = 0
X_max_sEMGsignal = 0

# Importación de valores min-max de cada característica para su normalización en tiempo real
# globalMinMaxValuesNormalization = np.load('globalMinMaxValuesNormalization_sEMGnomMinMax_FFC_LE_ESP32_featuresSet_PCA+MatCorr_300ms75%.npy')
globalMinMaxValuesNormalization = np.load('globalMinMaxValuesNormalization_sEMGnomMinMax_FFC_LE_ESP32_featuresSet_PCA+MatCorr_300ms75%_V2.npy')

print('Mínimos: ', globalMinMaxValuesNormalization[0])
print('Máximos: ', globalMinMaxValuesNormalization[1])

# ======= CONIFGURACIÓN DEL PUERTO SERIAL Y ENFOQUE DE VENTANAS ===========
# Parámetros de configuración
PORT_READ = 'COM3'  # Puerto serial donde se encuentra el microcontrolador ESP32 que recibe señal sEMG
PORT_WRITE = 'COM4' # Puerto serial dónde se manda los resultados del clasificador al otro microcontrolador ESP32
BAUDRATE = 115200  # Tasa de transmisión del puerto serial (debe coincidir con la configurada en la ESP32)
WINDOW_SIZE = 360  # Número de muestras en la ventana deslizante
FREQ_SAMPLING = 1200  # Frecuencia de muestreo de la señal sEMG (Hz)

# ====================== MODELO MLP EN TensorFlow Lite ===================

# Cargar el modelo de la red neuronal MLP previamente entrenado
# Cargar el modelo TensorFlow Lite cuantizado
# interpreter = tf.lite.Interpreter(model_path='model_MLP_withREP_75Overlapping_sEMGnomMinMaxForSubject_FFC_LE_MatCorr+PCA_quantDynRange_300ms75%.tflite')  # Reemplaza con tu modelo cuantizado
interpreter = tf.lite.Interpreter(model_path='model_MLP_withREP_75Overlapping_sEMGnomMinMaxForSubject_FFC_LE_MatCorr+PCA_quantDynRange_300ms75%_V2.tflite')  # Reemplaza con tu modelo cuantizado
interpreter.allocate_tensors()

# Obtener detalles de entrada y salida
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# ===================== SERIAL =====================
# Inicialización del puerto serial
ser_read = serial.Serial(PORT_READ, BAUDRATE, timeout=0.01)  # Configuración del puerto serial con tiempo de espera de 0.1 segundos
ser_read.flushInput()  # Vaciar el buffer de entrada antes de empezar a leer
# ser_io = io.BufferedReader(ser, buffer_size=4096)

ser_write = serial.Serial(PORT_WRITE, BAUDRATE, timeout=0.01)  # Configuración del puerto serial con tiempo de espera de 0.1 segundos
ser_write.flushOutput()  # Vaciar el buffer de salida antes de empezar a leer
# ser_io = io.BufferedReader(ser, buffer_size=4096)

# time.sleep(2)  # Esperar 2 segundos para asegurar que el puerto serial esté listo

# ============ VARIABLES PARA EL ENFOQUE DE VENTANAS MEDIANTE COLAS E HILOS ==============
# Buffer para almacenar las muestras recibidas desde el puerto serial
data_buffer = deque(maxlen=WINDOW_SIZE)  # Ventana de datos con tamaño 240
stride = 90  # Tamaño del desplazamiento de la ventana

# Cola para compartir datos entre hilos
# data_queue = Queue()
data_queue = Queue(maxsize=1000)  # Establecer un tamaño máximo para la cola

# Variable de control para la ejecución de los hilos
running = True

# Inicialización de gráfico de inferencias en tiempo real
# ------------------------ CONFIGURACIÓN DE COLORES Y ALTURAS ------------------------ #
colors = {'0': '#424861', '1': '#C9F2C7', '2': '#A799B7', '3': '#3C6997'}
heights = {'0': 0.5, '1': 0.5, '2': 1, '3': 0.1}
x_data = []
y_data = []

# Diccionario de nombres para las etiquetas
label_names = {
    '0': 'WF (Flexión de muñeca)',
    '1': 'WE (Extensión de muñeca)',
    '2': 'HC (Cierre de mano)',
    '3': 'REP (Reposo)'
}

# Diccionario para contar las etiquetas
label_counter = {'0': 0, '1': 0, '2': 0, '3': 0}
labels_from_robotic_gripper = ["tempMLX", "FSR_A1", "FSR_A2", "FSR_A3", 
          "FSR_B1", "FSR_B2", "FSR_B3", "FSR_C", "porcAper"]



# Inicializador de etiquetas a exportar
final_labels_data = []
counters_history = []
data_accumulated_from_gripper = []

#
carpeta_resultados = 'resultados_pruebas_finales/sujeto11'

# ===== SOLUCIÓN PARA EVITAR EL ERROR DE FORTRAN CON CTRL+C =====


# Limpieza garantizada con atexit
def cleanup():
    print("\n[LIMPIEZA FINAL] Cerrando recursos...")
    global running
    running = False
    
    # Cierre seguro de puertos seriales
    for port in ['ser_read', 'ser_write']:
        if port in globals() and hasattr(globals()[port], 'is_open'):
            globals()[port].close()
    
    # Mostrar estadísticas finales
    print("\nESTADÍSTICAS FINALES:")
    for label, count in label_counter.items():
        print(f"{label_names.get(label, label)}: {count}")
    
    # Graficar datos
    plot_data_and_save_plot(x_data, y_data, heights, colors, label_names, carpeta=carpeta_resultados, nombre_archivo='grafica_sesionX_S11_1.png')

    # Exportar etiquetas
    to_export_labels_csv(final_labels_data, carpeta_resultados, 'etiquetas_sesionX_S11_1.csv')
    to_export_data_from_plot_csv(x_data, y_data, carpeta_resultados, 'etiquetas_grafico_sesionX_S11_1.xlsx')
    to_export_history_to_excel(counters_history, carpeta_resultados, 'historial_completo_sesionX_S11_1.xlsx')
    to_export_data_from_robotic_gripper_csv(data_accumulated_from_gripper, labels_from_robotic_gripper, carpeta_resultados, 'datos_gripper_sesionX_S11_1.csv')
    to_export_calibration_data_for_inference(data_from_calibration, carpeta_resultados, 'valores_calibracion_sesionX_S11_1.csv')

    # Resultados de la calibración del usuario 

    # Forzar terminación
    os._exit(0)

atexit.register(cleanup)
# ===== FIN DE LA SOLUCIÓN =====

# Creación de carpeta de resultados
# Crear carpeta
# carpeta_resultados = create_results_folders("resultados_pruebas_finales")

# ============ RECEPCIÓN DE DATOS =====================
# Función para recibir datos desde el puerto serial
def receive_data():
    """Versión mejorada para recibir valores completos sin truncamiento"""
    print("Iniciando recepción de datos (modo robusto)...")
    buffer = ""  # Acumula datos crudos entre lecturas
    
    while running:
        try:
            # Leer todos los bytes disponibles
            data = ser_read.read(ser_read.in_waiting or 1).decode('utf-8', errors='ignore')
            buffer += data
            
            # Procesar líneas completas (separadas por \n)
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)  # Extrae la primera línea
                line = line.strip()
                
                if line:
                    try:
                        # Validar formato: dos enteros positivos separados por espacio/tab
                        if line.count(" ") == 1 or line.count("\t") == 1:
                            values = list(map(int, line.split()))
                            if len(values) == 2 and values[1] >= 4:  # Valida EDC ≥10
                                # values[0] = abs(values[0] -15)
                                data_queue.put(values)
                    except ValueError:
                        continue  # Ignora líneas corruptas
        
        except Exception as e:
            print(f"Error crítico: {str(e)}")
            buffer = ""  # Reinicia el buffer ante fallos graves
            continue


# ============ PROCESAMIENTO DE DATOS E INFERENCIA EN TIEMPO REAL ==========
# Función para procesar datos y realizar inferencia
def process_data():
    """
    Procesa los datos recibidos y realiza la inferencia con el modelo MLP.
    """
    print("Iniciando procesamiento de datos...")
    
    # 0. Retardo en segundos con mensaje de inicio
    delay_with_message(message= 'Inicio de calibración...')

    # 1. Capturar bias_REP_analog_channel (EDC - FDS)
    # global bias_REP_analog_channel
    # bias_REP_analog_channel = capture_bias_REP()
    global bias_REP_analog_channel_EDC, bias_REP_analog_channel_FDS
    bias_REP_analog_channel_EDC, bias_REP_analog_channel_FDS = capture_bias_REP()

    # 2. Capturar la ganancia asociada a cada canal analógico en el reposo para estabilizar ganancia de canales
    global gain_for_EDC_channel, gain_for_FDS_channel
    gain_for_EDC_channel, gain_for_FDS_channel = capture_gain_from_channel_REP(bias_REP_analog_channel_EDC, bias_REP_analog_channel_FDS)
    
    # 3. Capturar valor máximo global
    global X_max_sEMGsignal
    X_max_sEMGsignal = capture_max_value()

    # Crear diccionario con los valores únicos
    global data_from_calibration
    data_from_calibration = {
        "bias_REP_analog_channel_EDC": bias_REP_analog_channel_EDC,
        "bias_REP_analog_channel_FDS": bias_REP_analog_channel_FDS,
        "gain_for_EDC_channel": gain_for_EDC_channel,
        "gain_for_FDS_channel": gain_for_FDS_channel,
        "X_max_sEMGsignal": X_max_sEMGsignal
    }

    # 4. Retardo en segundos con mensaje de inicio
    delay_with_message()

    # Declaración de variable para el contador de inferencias por cantidad de tiempo
    inference_count = 0
    # Inicio del temporizador para medir número de clases predichas en cierta cantidad de tiempo
    start_inference_count_timer = time.time()
    # Contador de segundos
    actual_second = 1  # Contador de segundos
    # Contador de etiquetas por cada clase por cantidad de tiempo
    actual_second_counter = defaultdict(int)  # Conteo por clase en el segundo actual

    # Inicio de temporizador para reinicio de posición de la pinza roboótica
    start_gripper_reboot_timer = 1
    label_gripper_reboot = 4
    num_labels_for_reboot = 40
    time_for_session = 25
    time_for_object_change = 10

    interval_step = time_for_session + time_for_object_change

    while running:
        if not data_queue.empty():
            values = data_queue.get()
            
            # Inicio del temporizador para medir el tiempo de inferencia
            start_time = time.time()

            # 1. Recorte de valores por límite inferior 
            # values[0] += round(bias_REP_analog_channel/2) # Ajuste de canal EDC restando el bias
            values[0] -= bias_REP_analog_channel_FDS # Ajuste de canal EDC restando el bias
            values[1] -= bias_REP_analog_channel_EDC # Ajuste de canal EDC restando el bias
             # Aplicación de recorte con límite inferior para valores negativos
            values = [max(0, value) for value in values] # Recorte de límite inferior: max(0, value)

            # 2. Estabilización de ganancias
            values[0] = gain_for_FDS_channel * values[0]
            values[1] = gain_for_EDC_channel * values[1]

            data_buffer.append(values)  # Agregar la tupla (FDS, EDC) al buffer
            
            if len(data_buffer) == WINDOW_SIZE:  # Si la ventana está llena
                # print(data_buffer)
                window_array = np.array(data_buffer).T  # Convertir buffer en array
                # print(window_array)
                features_FDS, features_EDC = extract_features(window_array, X_min_sEMGsignal, X_max_sEMGsignal)  # Extraer características
                sEMG_FDS_nom_perValue, sEMG_EDC_nom_perValue = normalizeMinMax_sEMG_LEpercentileValue(window_array, X_min_sEMGsignal, X_max_sEMGsignal)
                # print(features_FDS, features_EDC)
                # features_normalized = normalize_features_MinMaxNormalization(minMaxValuesNormalization_FDS, minMaxValuesNormalization_EDC, features_FDS, features_EDC)
                features_normalized = normalize_features_GlobalMinMaxNormalization(globalMinMaxValuesNormalization, features_FDS, features_EDC)
                # print(features_normalized)

                # Preparar entrada para el modelo TFLite
                input_data = np.ravel(features_normalized).astype(np.float32)
                input_data = input_data.reshape(input_details[0]['shape'])
                # print(input_data)

                 # ======= INFERENCIA DEL PERCEPTRÓN MULTICAPA =====
                # Realizar inferencia
                interpreter.set_tensor(input_details[0]['index'], input_data)
                interpreter.invoke()
                
                # Obtener resultados
                MLP_labels_scores = interpreter.get_tensor(output_details[0]['index'])
                predicted_class = np.argmax(MLP_labels_scores)
                
                labels = ["WF", "WE", "HC", "REP"]
                MLP_predicted_label = labels[predicted_class]
                # print(f'Predicción (MLP): {MLP_predicted_label}')  # Mostrar resultado

                # ====== INFERENCIA DEL CLASIFICADOR CON LÓGICA DIFUSA =======
                # Inferencia con fuzzy
                fuzzy_predicted_scores_with_labels = fuzzy_predict(sEMG_FDS_nom_perValue, sEMG_EDC_nom_perValue)
                # print(fuzzy_predicted_scores_with_labels)
                fuzzy_labels_scores = np.array([fuzzy_predicted_scores_with_labels[l] for l in labels])
                fuzzy_predicted_label = labels[np.argmax(fuzzy_labels_scores)]
                # print(f'Predicción (Fuzzy): {fuzzy_predicted_label}')

                # ======= VOTACIÓN PONDERADA ======

                # Declaración de pesos asignados para cada clasificador
                # Votación ponderada
                weight_mlp = 0.55
                weight_fuzzy = 0.45

                # Votación condicional ponderada
                # # Asignación de pesos condicionada específicamente para la clase "WF"
                if fuzzy_predicted_label == "WF":
                    weight_mlp = 0.44
                    weight_fuzzy = 0.56


                # Asignación de pesos condicionada específicamente para la clase "HC"
                if fuzzy_predicted_label == "HC":
                    weight_mlp = 0.5
                    weight_fuzzy = 0.5

                # Asignación de pesos condicionada específicamente para la clase "HC"
                if fuzzy_predicted_label == "WE":
                    weight_mlp = 0.55
                    weight_fuzzy = 0.45

                
                # Predicción final
                combined_scores = weight_mlp * MLP_labels_scores + weight_fuzzy * fuzzy_labels_scores
                final_predicted_class = np.argmax(combined_scores)
                final_predicted_label = labels[final_predicted_class]
                # print(f'Predicción final: {final_predicted_label}')
                print(f"MLP pred: {MLP_predicted_label} | Fuzzy pred: {fuzzy_predicted_label} -> Final: {final_predicted_label} | Tiempo inferencia: {(time.time() - start_time)*1000:.2f} ms")

                # Actualizar contador de etiquetas
                label_counter[str(final_predicted_class)] += 1

                # Contador por clase del segundo actual
                actual_second_counter[str(final_predicted_class)] += 1

                # Contar la frecuencia de predicción por el clasificador: Medición de etiquetas por segundo
                inference_count += 1
                if time.time() - start_inference_count_timer >= 1.0:
                    print(f"===== SEGUNDO {actual_second} =====")
                    print(f"Etiquetas por segundo: {inference_count}")

                    # Guardar copia del estado de este segundo
                    counters_history.append(dict(actual_second_counter))  # Clonamos el diccionario

                    # Reiniciar para el siguiente segundo
                    actual_second_counter = defaultdict(int)
                    actual_second += 1
                    start_gripper_reboot_timer = actual_second
                    inference_count = 0
                    start_inference_count_timer = time.time()


                # Dentro de process_data() al final de cada inferencia:
                if ser_write and ser_write.is_open:
                    try:
                        ser_write.write((str(final_predicted_class) + "\n").encode('utf-8'))
                        # time.sleep(0.01)  # Pequeña pausa para dar tiempo de respuesta a la ESP32

                        # Leer respuesta desde el microcontrolador ESP32 de la pinza robótica
                        if ser_write.in_waiting > 0:
                            response = ser_write.readline().decode('utf-8', errors='ignore').strip()
                            # print(f"ESP32 (Pinza Robótica) respondió: {response}")
                            values_from_robotic_gripper = response.split(',')

                            # Verificar longitud correcta
                            if len(values_from_robotic_gripper) == len(labels_from_robotic_gripper):
                                # Convertir a float/int según necesidad
                                fila = {k: float(v.strip()) for k, v in zip(labels_from_robotic_gripper, values_from_robotic_gripper)}
                                data_accumulated_from_gripper.append(fila)
                            else:
                                print(f" --- Línea inválida ignorada: {response}")

                    except Exception as e:
                        print(f"Error al escribir o leer el puerto COM de salida: {e}")

                # Reincio de la pinza robótica para cada sesión
                if start_gripper_reboot_timer % time_for_session == 0 or start_gripper_reboot_timer % interval_step == 0:
                    if start_gripper_reboot_timer % time_for_session == 0:
                        time_for_session += interval_step
                    if ser_write and ser_write.is_open:
                        try:
                            for _ in range(1, num_labels_for_reboot):
                                ser_write.write((str(label_gripper_reboot) + "\n").encode('utf-8'))
                        except Exception as e:
                            print(f"Error al escribir o leer el puerto COM de salida: {e}")


                # Almacenar las etiquetas para su graficación al final como registro de resultados
                x_data.append(len(x_data))
                y_data.append(final_predicted_class)

                # Almacenar las etiquetas para registro de resultados durante la sesión
                final_labels_data.append(final_predicted_label)

                # Desplazar la ventana eliminando las primeras `stride` muestras
                for _ in range(stride):
                    if data_buffer:
                        data_buffer.popleft()  # Eliminar la muestra más antigua


# ------------------------ INICIO DE HILOS ------------------------ #
# Iniciar hilos
receive_thread = threading.Thread(target=receive_data, daemon=True)
process_thread = threading.Thread(target=process_data, daemon=True)

receive_thread.start()
process_thread.start()

# ------------------------ BUCLE PRINCIPAL ------------------------ #
# Mantener el programa en ejecución hasta que se interrumpa
if __name__ == "__main__":
    try:
        while True:
            time.sleep(1)
    except Exception as e:
        print(f"[ERROR] {str(e)}")
    finally:
        sys.exit(0)