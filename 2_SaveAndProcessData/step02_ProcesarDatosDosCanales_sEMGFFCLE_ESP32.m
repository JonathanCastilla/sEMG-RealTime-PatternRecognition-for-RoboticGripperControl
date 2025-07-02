
% ------------------------------------------------------------
% Nombre del archivo  :   step02_ProcesarDatosDosCanales_sEMGFFCLE_ESP32.m
% Descripción         :   Este código permite procesar y etiquetar de manera indepediente cada canal 
%                         de las señales sEMG adquiridas
%                         de dos canales analógicos (Extensor Común de los Dedos y 
%                         Flexor Superficial de los Dedos) mediante comunicación serial
%                         procesadas con filtro FFC desde
%                         el microcontrolador ESP32. 
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Septiembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.5
% ------------------------------------------------------------


%% PROCESAMIENTO DIGITAL DE LA SEÑAL sEMG ADQUIRIDA:
% Reducción de ruido: Wavelet Denoising
% Filtros Digitales: Feed Forward Comb (FFC) y Infinite Impulse Response
% Extracción de envolvente de sEMG: Envolvente de Hilbert, Envolvente
% Lineal

% LIMPIEZA DEL ESPACIO DE TRABAJO, VENTANA DE COMANDOS Y CIERRE DE VENTANAS GRÁFICAS
clear all; % Limpiar las variables almacenadas en el espacio de trabajo
clc; % Limpiar la ventana de comandos
close all; % Cerrar todas las ventanas gráficas
% format long;

% Cargar datos
% nombre_sEMG_datos = 'datos_sEMG_MAI_A01_B02_P1';
nombre_sEMG_datos = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef/datos_sEMG_MAD_EDC_HC_P3_M3sec.mat';

% Selección de canal a procesar
nombreCanal = input('Escribe las señales sEMG del canal ADCpin a procesar ("ADCpin1" ó "ADCpin2"): ');

if nombreCanal == "ADCpin1"
    load(nombre_sEMG_datos, 'ADCpin1')
    capturaDatos = ADCpin1.capturaDatos;
    variablesMuestreo = ADCpin1.variablesMuestreo;
elseif nombreCanal == "ADCpin2"
    load(nombre_sEMG_datos, 'ADCpin2')
    capturaDatos = ADCpin2.capturaDatos;
    variablesMuestreo = ADCpin2.variablesMuestreo;
else
    disp('Selecciona un canal válido');
    exit;
end

% load(nombre_sEMG_datos, 'capturaDatos', 'variablesMuestreo');

% EXTRACCIÓN DE VARIABLES DE MUESTREO
frecuenciaMuestreo = variablesMuestreo.frecuenciaMuestreo;
muestras = variablesMuestreo.numeroMuestras;
ventana_grafico = variablesMuestreo.ventana_grafico;
ventana_muestras_totales = variablesMuestreo.ventana_muestras_totales;
tiempo = linspace(0, muestras * variablesMuestreo.tiempoMuestreo, muestras);  % Escala de tiempo ajustada según el retardo

% Impresión de las varibles asociadas a la captura de datos
fprintf('----Adquisición de señal sEMG(t) del antebrazo mediante el PIN ADC de la ESP32--- \n')
fprintf('Tiempo de total de captura: %.3f segundos\n', variablesMuestreo.tiempoTotal);
fprintf('Tiempo de actualización de ventana: %.3f segundos\n', variablesMuestreo.periodoActualizacionVentana);
fprintf('Frecuencia de muestreo: %.3f [KHz] \n', variablesMuestreo.frecuenciaMuestreo / 1000);
fprintf('Tiempo de muestreo: %.3e segundos \n', variablesMuestreo.tiempoMuestreo);
fprintf('Número de muestras adquiridas: %8i \n', variablesMuestreo.numeroMuestras);


% DECLARACIÓN DE PALETAS DE COLORES ASOCIADAS A LAS VARIABLES DE COLOR PARA DESPLIGUE DE GRÁFICAS
color.PaletaColores.Earth.Verde = '#8F9E8B';
color.PaletaColores.Earth.Azul = '#96B5B8';
color.PaletaColores.Earth.Morado = '#6B656E';
color.PaletaColores.Earth.Amarillo = '#C7A961';
color.PaletaColores.Earth.Marron = '#9C937A';
color.PaletaColores.Earth.Negro1 = '#42474F';
color.PaletaColores.Earth.Negro2 = '#222222';

color.PaletaColores.Tropical.Naranja = '#FFCBAD';
color.PaletaColores.Tropical.Rosa = '#FFDCE6';
color.PaletaColores.Tropical.Verde1 = '#ADD057';
color.PaletaColores.Tropical.Verde2 = '#00BCA2';
color.PaletaColores.Tropical.Amarillo = '#E2F5B8';
color.PaletaColores.Tropical.Azul = '#85E0D5';

color.PaletaColores.FreshSummer.Naranja = '#FFD5A6';
color.PaletaColores.FreshSummer.Rojo = '#FF887E';
color.PaletaColores.FreshSummer.Verde1 = '#C2CF66';
color.PaletaColores.FreshSummer.Verde2 = '#426D5E';
color.PaletaColores.FreshSummer.Rosa = '#FEC4AE';
color.PaletaColores.FreshSummer.Verde3 = '#AEC8A6';

color.PaletaColores.DarkFall.Verde1 = '#677862';
color.PaletaColores.DarkFall.Verde2 = '#898E70';
color.PaletaColores.DarkFall.Marron1 = '#D3BCA0';
color.PaletaColores.DarkFall.Marron2 = '#A47E67';
color.PaletaColores.DarkFall.Morado = '#6B4B62';

color.PaletaColores.Spring.Amarillo = '#DFFCAD';
color.PaletaColores.Spring.Verde = '#B5F5D8';
color.PaletaColores.Spring.Azul1 = '#A8CCFC';
color.PaletaColores.Spring.Azul2 = '#8970FC';
color.PaletaColores.Spring.Morado = '#5D4CCC';

%% DECLARACIÓN DE ESTRUCTURAS PARA GUARDAR LOS DATOS ADQUIRIDOS DE LA SEÑAL
% sEMG

%% PROCESAR SEÑAL sEMG ADQUIRIDA
% 1. ANALIZAR LA SEÑAL
% Análsis de la señal en el dominio de tiempo-frecuencia a través de
% computar y graficar el escalograma de la señal utilizando Continuos
% Wavelet Transform (CWT)
% figure(3);
% "Continous 1-D Wavelet Transform
% cwt(capturaDatos.sEMGraw_nom);

% 2. REDUCCIÓN DE RUIDO DE LA SEÑALES sEMG y sEMG_FFC (CON FILTRO FEED
% FORWARD COMB) ADQUIRIDAD DE LAS ESP32

% 1. Señal sEMGraw Normalizada: Descomponer la señal y umbralización
[thr,sorh,keepapp] = ddencmp('den', 'wv', capturaDatos.sEMGraw_nom);
%[thr,sorh,keepapp] = ddencmp(in1,in2,x) returns default values for denoising or compression, using wavelets or wavelet packets, 
% of the input data x. x is a real-valued vector or 2-D matrix. thr is the threshold, and sorh indicates soft or hard thresholding. keepapp can be used as a flag to set whether or not the approximation coefficients are thresholded.
% Set in1 to 'den' for denoising or 'cmp' for compression.
% Set in2 to 'wv' to use wavelets or 'wp' to use wavelet packets.
capturaDatos.sEMG_nom_waveletDenosing = wdencmp('gbl', capturaDatos.sEMGraw_nom, 'db6', 4, thr, sorh, keepapp);
clear thr; clear sorh; clear keepapp;

% 1. Señal sEMG_FFC Normalizada adquirida desde la ESP32: Descomponer la señal y umbralización
[thr,sorh,keepapp] = ddencmp('den', 'wv', capturaDatos.sEMG_nom_FFC_ESP32);
%[thr,sorh,keepapp] = ddencmp(in1,in2,x) returns default values for denoising or compression, using wavelets or wavelet packets, 
% of the input data x. x is a real-valued vector or 2-D matrix. thr is the threshold, and sorh indicates soft or hard thresholding. keepapp can be used as a flag to set whether or not the approximation coefficients are thresholded.
% Set in1 to 'den' for denoising or 'cmp' for compression.
% Set in2 to 'wv' to use wavelets or 'wp' to use wavelet packets.
capturaDatos.sEMG_nom_WD_FFC_ESP32 = wdencmp('gbl', capturaDatos.sEMG_nom_FFC_ESP32, 'db6', 4, thr, sorh, keepapp);


figure(1);
hold on;
plot(capturaDatos.tiempo, capturaDatos.sEMGraw_nom, 'Color', color.PaletaColores.Earth.Marron, 'LineWidth', 3.0);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'Color', color.PaletaColores.Earth.Negro2, 'LineWidth', 2.5);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_ESP32, 'Color', color.PaletaColores.DarkFall.Verde2, 'LineWidth', 2.0);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC_ESP32, 'Color', color.PaletaColores.Earth.Verde, 'LineWidth', 1.2);
title('sEMG (Feed Forward Comb (FFC), Normalizada) y sEMG (FFC, Normalizada y Wavelet Denoising)');
xlabel('Tiempo (s)');
ylabel('Amplitud');
legend('sEMG (normalizada)', ...
    'sEMG (Normalizada y con "Wavelet Denoising" "db6" nivel "4")',...
    'sEMG con Feed Forward Comb (FFC) (Normalizada) (ESP32)',...
    'sEMG con Feed Forward Comb (FFC) (Normalizada y con "Wavelet Denoising" "db6" nivel "4") (ESP32)');
grid on;

% EXTRAER ENVOLVENTE USANDO TRANSFORMADA DE HILBERT
% hilbert_transform = hilbert(capturaDatos.sEMGraw_nom(1:i));
% capturaDatos.sEMG_envelope = abs(hilbert_transform);
fl2 = 30; % Separación de los picos
[capturaDatos.sEMG_nom_waveletDenoising_envelopeHilbert, lo2] = envelope(capturaDatos.sEMG_nom_waveletDenosing, fl2, 'peak');
% [capturaDatos.sEMG_nom_waveletDenoising_envelopeHilbert, lo2] = envelope(capturaDatos.sEMG_nom_waveletDenosing(1:i), fl2, 'analytic');

% Filtro Feed Forward Comb (FFC): Obtención de EMG-LE (envolvente lineal)
% Parámetros del filtro FFC y el cálculo de EMG-LE
win_len = 128; % Longitud de ventana para EMG-LE
% ACC = 0; % Acumulador para EMG-LE
capturaDatos.sEMG_nom_FFC_envelopeLineal = 0; % Inicializar EMG-LE

%% FILTRADO POSTERIOR A LA ADQUISICIÓN

%% FILTRO FEED FORWARD COMB (FFC)
% Parámetros del filtro Feed-Forward Comb (FFC)
frecuenciaLineaPoderInterferencia = 60; % Frecuencia de la línea de poder (60 Hz)
% frecuenciaArtefactosMovimiento = 20; % Frecuencia de artefactos de movimiento (20 Hz)

% Calcular retardos
N_60Hz = round(frecuenciaMuestreo / frecuenciaLineaPoderInterferencia); % Retardo para 60 Hz
% N_20Hz = round(frecuenciaMuestreo / frecuenciaArtefactosMovimiento); % Retardo para 20 Hz

% Parámetro de interferencia destructiva
alpha = -1; % Para interferencia destructiva completa

% Declaración de la señal sEMG a retardar para generación de interferencias
% destructivas mediante el Filtro Feed Forward Comb
sEMGraw_nom = capturaDatos.sEMGraw_nom;
sEMGraw_WD_nom = capturaDatos.sEMG_nom_waveletDenosing;

% Eliminar interferencia de 60 Hz (Línea de poder)
% Para señal sEMG normalizada
sEMG_retrasada_60Hz = [zeros(N_60Hz, 1); sEMGraw_nom(1:end-N_60Hz)']; % Retardar la señal cruda para 60 Hz
sEMG_FFC_60Hz = sEMGraw_nom' + alpha * sEMG_retrasada_60Hz; % Aplicar interferencia destructiva para 60 Hz

% Para señal sEMG normalizada y con Wavelet Denoising
sEMG_WD_retrasada_60Hz = [zeros(N_60Hz, 1); sEMGraw_WD_nom(1:end-N_60Hz)']; % Retardar la señal cruda para 60 Hz
sEMG_WD_FFC_60Hz = sEMGraw_WD_nom' + alpha * sEMG_WD_retrasada_60Hz; % Aplicar interferencia destructiva para 60 Hz

% Eliminar frecuencias por debajo de 20 Hz (artefactos de movimiento)
% Para señal sEMG normalizada
% sEMG_retrasada_20Hz = [zeros(N_20Hz, 1); sEMG_FFC_60Hz(1:end-N_20Hz)]; % Retardar la señal ya filtrada para 20 Hz
% sEMG_FFC_total = sEMG_FFC_60Hz + alpha * sEMG_retrasada_20Hz; % Aplicar interferencia destructiva para 20 Hz
sEMG_FFC_total = sEMG_FFC_60Hz;


% Para señal sEMG normalizada y con Wavelet Denoising
% sEMG_WD_retrasada_20Hz = [zeros(N_20Hz, 1); sEMG_WD_FFC_60Hz(1:end-N_20Hz)]; % Retardar la señal ya filtrada para 20 Hz
% sEMG_WD_FFC_total = sEMG_WD_FFC_60Hz + alpha * sEMG_WD_retrasada_20Hz; % Aplicar interferencia destructiva para 20 Hz
sEMG_WD_FFC_total = sEMG_WD_FFC_60Hz;


% Guardar el resultado en la estructura
capturaDatos.sEMG_nom_FFC = sEMG_FFC_total';
capturaDatos.sEMG_nom_WD_FFC = sEMG_WD_FFC_total';

%% FILTRO DIGITAL: IIR (Infinite Impulse Response)
% Parámetros del filtro pasaaltas (para eliminar artefactos de movimiento por debajo de 20 Hz)
highpass_cutoff = 20; % Frecuencia de corte del filtro pasaaltas (20 Hz)
d_hp = designfilt('highpassiir', 'FilterOrder', 4, ...
                  'HalfPowerFrequency', highpass_cutoff, ...
                  'SampleRate', frecuenciaMuestreo);

% Parámetros del filtro Notch (para eliminar la interferencia de 60 Hz)
d_notch = designfilt('bandstopiir', 'FilterOrder', 2, ...
                     'HalfPowerFrequency1', 59, 'HalfPowerFrequency2', 61, ...
                     'SampleRate', frecuenciaMuestreo);

% d = designfilt('bandstopiir', 'FilterOrder', 2, ...
%                'HalfPowerFrequency1', 59, 'HalfPowerFrequency2', 61, ...
%                'SampleRate', frecuenciaMuestreo); % Filtro para eliminar 60 Hz

% Aplicar el filtro Feed-Forward Comb a toda la señal adquirida normalizada
% y con 'Wavelet Denoising' tipo 'db6' nivel IV.

% Aplicar el filtro pasaaltas para eliminar artefactos de movimiento
data_highpassed_sEMGraw_nom_WD = filtfilt(d_hp, capturaDatos.sEMGraw_nom);
data_highpassed_sEMG_nom_WD = filtfilt(d_hp, capturaDatos.sEMG_nom_waveletDenosing);

% Aplicar el filtro Notch para eliminar la interferencia de 60 Hz
capturaDatos.sEMG_nom_IIR = filtfilt(d_notch, data_highpassed_sEMG_nom_WD);
capturaDatos.sEMG_nom_WD_IIR = filtfilt(d_notch, data_highpassed_sEMGraw_nom_WD);

% capturaDatos.sEMG_nom_WD_FFC = filtfilt(d, capturaDatos.sEMG_nom_waveletDenosing(1:i));
% capturaDatos.sEMG_nom_FFC = filtfilt(d, capturaDatos.sEMGraw_nom(1:i));

% CÁLCULO DEL EMG-LE (envolvente)
win_len = 32; % Longitud de ventana para EMG-LE
% Vector de tiempo para EMG-LE (un valor de EMG-LE por cada ventana)
num_windows = floor(length(capturaDatos.sEMG_nom_WD_FFC) / win_len); % Número de ventanas
% Vectores de almacenamiento para señal sEMG_LE (FFC)
datos_sEMG_WD_FFC_LE = zeros(1, num_windows); % Vector para almacenar el nivel EMG-LE
datos_sEMG_FFC_LE = zeros(1, num_windows); % Vector para almacenar el nivel EMG-LE
% Vectores de almacenamiento para señal sEMG_LE (IIR)
datos_sEMG_WD_IIR_LE = zeros(1, num_windows); % Vector para almacenar el nivel EMG-LE
datos_sEMG_IIR_LE = zeros(1, num_windows); % Vector para almacenar el nivel EMG-LE
% Vector de almacenamiento de tiempo para la señal sEMG_LE (FFC e IIR)
tiempo_sEMG_LE = ((0:num_windows-1) * win_len) / frecuenciaMuestreo; % Tiempo para cada ventana

for k = 1:num_windows
    % Extraer una ventana de datos filtrados
    % Para Feed Forward Comb (FFC)
    window_data_sEMG_WD_FFC = capturaDatos.sEMG_nom_WD_FFC((k-1)*win_len + 1:k*win_len);
    window_data_sEMG_FFC = capturaDatos.sEMG_nom_FFC((k-1)*win_len + 1:k*win_len);
    % Para Filtro Infinite Impulse Response (IIR)
    window_data_sEMG_WD_IIR = capturaDatos.sEMG_nom_WD_IIR((k-1)*win_len + 1:k*win_len);
    window_data_sEMG_IIR = capturaDatos.sEMG_nom_IIR((k-1)*win_len + 1:k*win_len);

    % Calcular el valor absoluto y luego el promedio (EMG-LE)
    % Para Feed Forward Comb (FFC)
    datos_sEMG_WD_FFC_LE(k) = mean(abs(window_data_sEMG_WD_FFC));
    datos_sEMG_FFC_LE(k) = mean(abs(window_data_sEMG_FFC));
    % Para Filtro Infinite Impulse Response (IIR)
    datos_sEMG_WD_IIR_LE(k) = mean(abs(window_data_sEMG_WD_IIR));
    datos_sEMG_IIR_LE(k) = mean(abs(window_data_sEMG_IIR));
end

% Interpolar la señal EMG-LE al tamaño del vector crudo
capturaDatos.sEMG_nom_WD_FFC_envelopeLineal = interp1(tiempo_sEMG_LE, datos_sEMG_WD_FFC_LE, capturaDatos.tiempo, 'linear', 'extrap');
capturaDatos.sEMG_nom_FFC_envelopeLineal = interp1(tiempo_sEMG_LE, datos_sEMG_FFC_LE, capturaDatos.tiempo, 'linear', 'extrap');
capturaDatos.sEMG_nom_WD_IIR_envelopeLineal = interp1(tiempo_sEMG_LE, datos_sEMG_WD_IIR_LE, capturaDatos.tiempo, 'linear', 'extrap');
capturaDatos.sEMG_nom_IIR_envelopeLineal = interp1(tiempo_sEMG_LE, datos_sEMG_IIR_LE, capturaDatos.tiempo, 'linear', 'extrap');

% GRAFICAR ENVOLVENTES
figure(2);
hold on;
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'Color', color.PaletaColores.Earth.Negro1, 'LineWidth', 0.5);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenoising_envelopeHilbert, 'Color', color.PaletaColores.FreshSummer.Naranja, 'LineWidth', 2.5);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal, 'Color', color.PaletaColores.Tropical.Verde1, 'LineWidth', 1.2);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32, 'color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 1.4);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC_envelopeLineal, 'Color', color.PaletaColores.Spring.Azul1, 'LineWidth', 1.6);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_IIR_envelopeLineal, 'Color', color.PaletaColores.Spring.Azul2, 'LineWidth', 1.4);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_IIR_envelopeLineal, 'Color', color.PaletaColores.Tropical.Rosa, 'LineWidth', 1.6);
title('Señal sEMG (Normalizada y con Wavelet Denoising) y envolvente de Hilbert y Lineal');
xlabel('Tiempo (s)');
ylabel('Amplitude');
legend('Señal sEMG (Normalizada y con "Wavelet Denoising" "db6" nivel "4")', 'sEMG (Hilbert Envelope)', ...
    'sEMG-LE con Feed Forward Comb (FFC) (Linear Envelope)', 'sEMG-LE con Feed Forward Comb (FFC) (Linear Envelope) (ESP32)', ...
    'sEMG-LE con Feed Forward Comb (FFC) y Wavelet Denoising (Linear Envelope)', ...
    'sEMG-LE con Infinite Impulse Response (IIR) (Linear Envelope)', ...
    'sEMG-LE con Infinite Impulse Response (IIR) y Wavelet Denoising (Linear Envelope)');
grid on;
% figure(6);
% plot(capturaDatos.tiempo(1:i), capturaDatos.sEMG_nom_waveletDenosing(1:i), 'b', 'LineWidth', 0.5);
% hold on;
% plot(capturaDatos.tiempo(1:i), capturaDatos.sEMG_nom_WD_FFC_envelopeLineal(1:i), 'Color', [0.9 0.11 0.25], 'LineWidth', 1.5);
% title('Señal sEMG (Normalizada y con Wavelet Denoising) y envolvente de Hilbert y Lineal');
% xlabel('Tiempo (s)');
% ylabel('Amplitude');
% legend('Señal sEMG (Normalizada y con "Wavelet Denoising" "db6" nivel "4")', 'sEMG (Hilbert Envelope)', 'sEMG (Linear Envelope)');
% grid on;

figure(3);
hold on;
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'Color', color.PaletaColores.Earth.Negro1, 'LineWidth', 0.5);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal, 'Color', color.PaletaColores.Tropical.Verde1, 'LineWidth', 1.2);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32, 'color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 1.6);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC_envelopeLineal, 'Color', color.PaletaColores.Spring.Azul1, 'LineWidth', 1.4);
title('Señal sEMG (Normalizada y con Wavelet Denoising) y envolvente de tipo Lineal');
xlabel('Tiempo (s)');
ylabel('Amplitud');
legend('Señales sEMG-LE (Normalizada, "Wavelet Denoising" "db6" nivel "4" y Filtro Feed Forward Comb (FFC))', ...
    'sEMG-LE con Feed Forward Comb (FFC) (Linear Envelope)', 'sEMG-LE con Feed Forward Comb (FFC) (Linear Envelope) (ESP32)', ...
    'sEMG-LE con Feed Forward Comb (FFC) y Wavelet Denoising (Linear Envelope)')
grid on;

figure(4);
hold on;
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'Color', color.PaletaColores.Earth.Negro1, 'LineWidth', 0.5);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_IIR_envelopeLineal, 'Color', color.PaletaColores.Spring.Azul2, 'LineWidth', 1.8);
plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_IIR_envelopeLineal, 'Color', color.PaletaColores.Tropical.Rosa, 'LineWidth', 1.6);
xlabel('Tiempo (s)');
ylabel('Amplitud');
title('Señal sEMG (Normalizada, "Wavelet Denoising" "db6" nivel "4", Filtro Infinite Impulse Response (IIR))');
legend('Señal sEMG (Normalizada, "Wavelet Denoising" "db6" nivel "4", Filtro Infinite Impulse Response (IIR))', ...
    'sEMG-LE con Infinite Impulse Response (IIR) (Linear Envelope)', ...
    'sEMG-LE con Infinite Impulse Response (IIR) y Wavelet Denoising (Linear Envelope)');
grid on;


% GUARDAR DATOS EN UN ARCHIVO MAT
save(nombre_sEMG_datos, 'capturaDatos', 'variablesMuestreo');
