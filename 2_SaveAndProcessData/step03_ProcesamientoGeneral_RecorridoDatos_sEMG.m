
% ------------------------------------------------------------
% Nombre del archivo  :   step03_ProcesamientoGeneral_RecorridoDatos_sEMG.m
% Descripción         :   Procesamiento general de todas las muestras sEMG adquiridas
%                         de dos canales analógicos (Extensor Común de los Dedos y 
%                         Flexor Superficial de los Dedos) mediante comunicación serial
%                         procesadas con filtro FFC desde
%                         el microcontrolador ESP32. Este código permite
%                         procesar todas las muestras almacenadas en el
%                         directorio indicado.
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Septiembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.2
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

% Directorio donde se encuentran los archivos .mat
directorioEntrada = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef';
% Listar todos los archivos .mat en el directorio
archivosMat = dir(fullfile(directorioEntrada, '*.mat'));

% Cargar archivo .mat para acceder a los valores Xmin y Xmax para la normalización MinMax de
% señales sEMG_FFC_LE_ESP32
minGlobal = 0;
maxGlobal = 1024;
% load('valoresNormalizacionMinMax_sEMG_FFC_LE_ESP32.mat');

% Recorrer cada archivo .mat
for k = 1:length(archivosMat)
    % Nombre completo del archivo
    nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name);
    disp(nombreCompletoArchivo);
    % Cargar datos
    % nombre_sEMG_datos = 'datos_sEMG_MAI_A01_B02_P1';
    % nombre_sEMG_datos = 'datosProtoboard_sEMG_MAD_EDC_CF_P1_M5sec.mat';
    load(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo');
    
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
    
    % Impresión de los valores mínimos y máximos globales de las muestras para
    % la normalización tipo MinMax Scaler
    fprintf('Valores para la normalización tipo MinMax Scaler para sEMG_FFC_LE \n')
    fprintf('minGlobal: %4i \n', minGlobal);
    fprintf('maxGlobal: %4i \n', maxGlobal);
    %% NORMALIZACIÓN DE LAS SEÑALES sEMG
    capturaDatos.sEMGraw_nom = normalizeSignalsEMG(capturaDatos.sEMGraw);
    % capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = normalizeSignalsEMG(capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32);
    capturaDatos.sEMG_nom_FFC_ESP32 = normalizeSignalsEMG(capturaDatos.sEMG_FFC_ESP32);
    
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
    
    capturaDatos.sEMG_nom_waveletDenosing = waveletDenoisingDB6Level4(capturaDatos.sEMGraw_nom);
    capturaDatos.sEMG_nom_WD_FFC_ESP32 = waveletDenoisingDB6Level4(capturaDatos.sEMG_nom_FFC_ESP32);
    
    % EXTRAER ENVOLVENTE USANDO TRANSFORMADA DE HILBERT
    % hilbert_transform = hilbert(capturaDatos.sEMGraw_nom(1:i));
    % capturaDatos.sEMG_envelope = abs(hilbert_transform);
    filterLengthHilbert = 30; % Separación de los picos
    capturaDatos.sEMG_nom_waveletDenoising_envelopeHilbert = envelopeHilbert(capturaDatos.sEMG_nom_waveletDenosing, filterLengthHilbert);
    
    %% FILTRADO POSTERIOR A LA ADQUISICIÓN
    %% FILTRO FEED FORWARD COMB (FFC)
    
    % Guardar el resultado en la estructura
    capturaDatos.sEMG_nom_FFC = filterFeedForwardComb(frecuenciaMuestreo, capturaDatos.sEMGraw_nom);
    capturaDatos.sEMG_nom_WD_FFC = filterFeedForwardComb(frecuenciaMuestreo, capturaDatos.sEMG_nom_waveletDenosing);
    
    %% FILTRO DIGITAL: IIR (Infinite Impulse Response)
    
    % Aplicar el filtro Notch para eliminar la interferencia de 60 Hz
    capturaDatos.sEMG_nom_IIR = filterInfiniteImpulseResponse(frecuenciaMuestreo, capturaDatos.sEMGraw_nom);
    capturaDatos.sEMG_nom_WD_IIR = filterInfiniteImpulseResponse(frecuenciaMuestreo, capturaDatos.sEMG_nom_waveletDenosing);
    
    %% CÁLCULO DEL sEMG-LE (envolvente lineal)
    
    % Obtención de sEMG-LE (envolvente lineal)
    capturaDatos.sEMG_nom_WD_FFC_envelopeLineal = linealEnvelope(frecuenciaMuestreo, capturaDatos.sEMG_nom_WD_FFC, capturaDatos.tiempo);
    capturaDatos.sEMG_nom_FFC_envelopeLineal = linealEnvelope(frecuenciaMuestreo, capturaDatos.sEMG_nom_FFC, capturaDatos.tiempo);
    capturaDatos.sEMG_nom_WD_IIR_envelopeLineal = linealEnvelope(frecuenciaMuestreo, capturaDatos.sEMG_nom_WD_IIR, capturaDatos.tiempo);
    capturaDatos.sEMG_nom_IIR_envelopeLineal = linealEnvelope(frecuenciaMuestreo, capturaDatos.sEMG_nom_IIR, capturaDatos.tiempo);
    %capturaDatos.sEMG_FFC_envelopeLineal_ESP32 = linealEnvelope_ESP32integers(frecuenciaMuestreo, capturaDatos.sEMG_FFC_ESP32, capturaDatos.tiempo);    
    capturaDatos.sEMG_nom_FFC_LE_ESP32 = normalizeSignalsEMG(capturaDatos.sEMG_FFC_envelopeLineal_ESP32);
    capturaDatos.sEMG_nomMinMax_FFC_LE_ESP32 = normalizeSignalsEMG_minMax(capturaDatos.sEMG_FFC_envelopeLineal_ESP32, minGlobal, maxGlobal);
    
    % Guardar datos en la carpeta correspondiente
    [~, nombreArchivo, ~] = fileparts(nombreCompletoArchivo);
    partes = strsplit(nombreArchivo, '_');
    indiceM = find(~cellfun('isempty', regexp(partes, '^M\d+')), 1);
    ruta_carpetas = fullfile(directorioEntrada, partes{indiceM});
    rutaArchivoSalida = fullfile(ruta_carpetas, archivosMat(k).name);

    if ~isfolder(ruta_carpetas)
       mkdir(ruta_carpetas);
    end

    % GUARDAR DATOS EN UN ARCHIVO MAT
    % Guardar el archivo actualizado
    % save(rutaArchivoSalida, 'capturaDatos', 'variablesMuestreo');
    save(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo');
end

disp('Procesamiento y guardado de archivos completado.');

%% FUNCIONES AUXILIARES
%% NORMALIZAR SEÑALES sEMG
%% NORMALIZAR SEÑALES sEMG con MIN-MAX [0,1]
function [normalizedSignalsEMG] = normalizeSignalsEMG_minMax(sEMGsignal, Xmin, Xmax)
     % Normaliza la señal sEMG en el rango [0,1] usando Min-Max Scaling
    normalizedSignalsEMG = (sEMGsignal - Xmin)/(Xmax - Xmin);

end

%% NORMALIZAR SEÑALES sEMG CON MIN-MAX [-1,1] Y FILTRO DE OUTLIERS (IQR)
function [normalizedSignalsEMG] = normalizeSignalsEMG_minmax_OutliersFilter(sEMGsignal)
    % Normaliza la señal sEMG en el rango [-1,1] usando Min-Max Scaling
    % con recorte de valores atípicos basado en el rango intercuartílico (IQR).
    %
    % Parámetros:
    %   sEMGsignal: Vector o matriz con la señal EMG a normalizar
    %
    % Retorna:
    %   normalizedSignalsEMG: Señal normalizada en el rango [-1,1]
    
    % Calcular cuartiles e IQR
    Q1 = prctile(sEMGsignal(:), 25); % Primer cuartil
    Q3 = prctile(sEMGsignal(:), 75); % Tercer cuartil
    IQR = Q3 - Q1; % Rango intercuartílico
    
    % Definir límites usando 1.5 * IQR
    lowerBound = Q1 - 1.5 * IQR;
    upperBound = Q3 + 1.5 * IQR;
    
    % Recortar valores fuera del rango IQR
    sEMGsignal = max(min(sEMGsignal, upperBound), lowerBound);
    
    % Obtener nuevo mínimo y máximo después del recorte
    minValue = min(sEMGsignal(:));
    maxValue = max(sEMGsignal(:));
    
    % Aplicar normalización Min-Max en el rango [-1,1]
    normalizedSignalsEMG = 2 * (sEMGsignal - minValue) / (maxValue - minValue) - 1;
end

% NORMALIZAR SEÑALES sEMG CON STANDARD SCALER
function [normalizedSignalsEMG] = normalizeSignalsEMG(sEMGsignal)
    meanValue = mean(sEMGsignal);  % Calcular la media
    stdValue = std(sEMGsignal);    % Calcular la desviación estándar
    
    % Aplicar normalización StandardScaler
    normalizedSignalsEMG = (sEMGsignal - meanValue) / stdValue;
end

%% %% WAVELET DENOISING

function [sEMGsignal_waveletDenoising] = waveletDenoisingDB6Level4(sEMGsignal)
    % 1. Señal sEMGraw Normalizada: Descomponer la señal y umbralización
    [thr,sorh,keepapp] = ddencmp('den', 'wv', sEMGsignal);
    %[thr,sorh,keepapp] = ddencmp(in1,in2,x) returns default values for denoising or compression, using wavelets or wavelet packets, 
    % of the input data x. x is a real-valued vector or 2-D matrix. thr is the threshold, and sorh indicates soft or hard thresholding. keepapp can be used as a flag to set whether or not the approximation coefficients are thresholded.
    % Set in1 to 'den' for denoising or 'cmp' for compression.
    % Set in2 to 'wv' to use wavelets or 'wp' to use wavelet packets.
    sEMGsignal_waveletDenoising = wdencmp('gbl', sEMGsignal, 'db6', 4, thr, sorh, keepapp);
end

%% %% HILBERT ENVELOPE

function [sEMGsignal_envelopeHilbert] = envelopeHilbert(sEMGsignal, filterLengthHilbert)
    [sEMGsignal_upper_EnvelopeHilbert, sEMGsignal_lower_EnvelopeHilbert] = envelope(sEMGsignal, filterLengthHilbert, 'peak');
    sEMGsignal_envelopeHilbert = sEMGsignal_upper_EnvelopeHilbert;
end

%% %%

function [sEMGsignal_FFC] = filterFeedForwardComb(frecuenciaMuestreo, sEMGsignal)
    % Parámetros del filtro Feed-Forward Comb (FFC)
    frecuenciaLineaPoderInterferencia = 60; % Frecuencia de la línea de poder (60 Hz)
    
    % Calcular retardos
    N_60Hz = round(frecuenciaMuestreo / frecuenciaLineaPoderInterferencia); % Retardo para 60 Hz

    % Parámetro de interferencia destructiva
    alpha = -1; % Para interferencia destructiva completa

    % Declaración de la señal sEMG a retardar para generación de interferencias
    % destructivas mediante el Filtro Feed Forward Comb
    sEMGraw_nom = sEMGsignal;

    % Eliminar interferencia de 60 Hz (Línea de poder)
    % Para señal sEMG normalizada
    sEMG_retrasada_60Hz = [zeros(N_60Hz, 1); sEMGraw_nom(1:end-N_60Hz)']; % Retardar la señal cruda para 60 Hz
    sEMG_FFC_60Hz = sEMGraw_nom' + alpha * sEMG_retrasada_60Hz; % Aplicar interferencia destructiva para 60 Hz
    
    sEMG_FFC_total = sEMG_FFC_60Hz;
    
    % Guardar el resultado en la estructura
    sEMGsignal_FFC= sEMG_FFC_total';
end

%% %%

function [sEMGsignal_IIR] = filterInfiniteImpulseResponse(frecuenciaMuestreo, sEMGsignal)

    % Parámetros del filtro pasaaltas (para eliminar artefactos de movimiento por debajo de 20 Hz)
    highpass_cutoff = 20; % Frecuencia de corte del filtro pasaaltas (20 Hz)
    d_hp = designfilt('highpassiir', 'FilterOrder', 4, ...
                      'HalfPowerFrequency', highpass_cutoff, ...
                      'SampleRate', frecuenciaMuestreo);
    
    % Parámetros del filtro Notch (para eliminar la interferencia de 60 Hz)
    d_notch = designfilt('bandstopiir', 'FilterOrder', 2, ...
                         'HalfPowerFrequency1', 59, 'HalfPowerFrequency2', 61, ...
                         'SampleRate', frecuenciaMuestreo);
    
    % Aplicar el filtro pasaaltas para eliminar artefactos de movimiento
    data_highpassed_sEMGsignal = filtfilt(d_hp, sEMGsignal);

    % Aplicar el filtro Notch para eliminar la interferencia de 60 Hz
    sEMGsignal_IIR = filtfilt(d_notch, data_highpassed_sEMGsignal);
end


%% %%

function [sEMGsignal_envelopeLineal] = linealEnvelope(frecuenciaMuestreo, sEMGsignal, sEMGsignal_adquisitionTime)

    % Obtención de sEMG-LE (envolvente lineal)
    % Cálculo de sEMG-LE
    win_len = 64; % Longitud de ventana para sEMG-LE
    % Vector de tiempo para EMG-LE (un valor de sEMG-LE por cada ventana)
    num_windows = floor(length(sEMGsignal) / win_len); % Número de ventanas
    % Vectores de almacenamiento para señal sEMG_LE
    datos_sEMG = zeros(1, num_windows); % Vector para almacenar el nivel EMG-LE
    % Vector de almacenamiento de tiempo para la señal sEMG_LE
    tiempo_sEMG_LE = ((0:num_windows-1) * win_len) / frecuenciaMuestreo; % Tiempo para cada ventana
    
    for k = 1:num_windows
        % Extraer una ventana de datos filtrados
        window_data_sEMG = sEMGsignal((k-1)*win_len + 1:k*win_len);
    
        % Calcular el valor absoluto y luego el promedio (sEMG-LE)
        datos_sEMG(k) = mean(abs(window_data_sEMG));
    
    end
    
    % Interpolar la señal sEMG-LE al tamaño del vector crudo
    sEMGsignal_envelopeLineal = interp1(tiempo_sEMG_LE, datos_sEMG, sEMGsignal_adquisitionTime, 'linear', 'extrap');

end


function [sEMGsignal_envelopeLineal] = linealEnvelope_ESP32integers(frecuenciaMuestreo, sEMGsignal, sEMGsignal_adquisitionTime)

    % Obtención de sEMG-LE (envolvente lineal)
    % Cálculo de sEMG-LE
    win_len = 64; % Longitud de ventana para sEMG-LE
    % Vector de tiempo para EMG-LE (un valor de sEMG-LE por cada ventana)
    num_windows = floor(length(sEMGsignal) / win_len); % Número de ventanas
    % Vectores de almacenamiento para señal sEMG_LE
    datos_sEMG = zeros(1, num_windows); % Vector para almacenar el nivel EMG-LE
    % Vector de almacenamiento de tiempo para la señal sEMG_LE
    tiempo_sEMG_LE = ((0:num_windows-1) * win_len) / frecuenciaMuestreo; % Tiempo para cada ventana
    
    for k = 1:num_windows
        % Extraer una ventana de datos filtrados
        window_data_sEMG = sEMGsignal((k-1)*win_len + 1:k*win_len);
    
        % Calcular el valor absoluto y luego el promedio (sEMG-LE)
        datos_sEMG(k) = mean(abs(window_data_sEMG));
    
    end
    
    % Interpolar la señal sEMG-LE al tamaño del vector crudo
    sEMGsignal_envelopeLineal = interp1(tiempo_sEMG_LE, datos_sEMG, sEMGsignal_adquisitionTime, 'linear', 'extrap');
    
    % Redondear los valores a enteros
    sEMGsignal_envelopeLineal = round(sEMGsignal_envelopeLineal);
end

function [EMG_level] = arduinoLikeEnvelope(sEMGsignal, win_len)
    % Parámetros como en Arduino
    MAv_len = 20;
    MAv = zeros(1, MAv_len);
    S = 0;
    ACC = 0;
    k = 1;
    last_sample = 0;
    
    EMG_level = zeros(1, floor(length(sEMGsignal)/win_len));
    level_index = 1;
    
    for n = 1:length(sEMGsignal)
        sample = sEMGsignal(n);
        ds = sample - last_sample;
        last_sample = sample;
        
        % Actualizar promedio móvil
        S = S - MAv(k);
        MAv(k) = ds;
        S = S + MAv(k);
        
        % Actualizar acumulador
        ACC = ACC + abs(S);
        
        % Actualizar índice del promedio móvil
        k = mod(k, MAv_len) + 1;
        
        % Cada win_len muestras, calcular nivel EMG
        if mod(n, win_len) == 0
            EMG_level(level_index) = bitshift(ACC, -log2(win_len)); % Equivalente a ACC >> 7 para win_len=128
            ACC = 0;
            level_index = level_index + 1;
        end
    end
end