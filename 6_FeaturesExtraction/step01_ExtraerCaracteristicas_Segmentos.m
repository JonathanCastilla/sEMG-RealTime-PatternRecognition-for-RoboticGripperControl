
% ------------------------------------------------------------
% Nombre del archivo  :   step01_ExtraerCaracteristicas_Segmentos.m
% Descripción         :   Este código permite extraer las características de los segmentos de las
%                         señales sEMG acorde a los protocolos de adquisición (M3sec y M5sec)
%                         mediante un enfoque de recorrido de ventanas y porcentajes de
%                         solapamientolas de las muestras etiquetadas señales sEMG adquiridas
%                         con Filtro Feed Forward Comb (FFC) con Envolvente
%                         Lineal de dos canales analógicos (Extensor Común de los Dedos y 
%                         Flexor Superficial de los Dedos) mediante comunicación serial
%                         procesadas con filtro FFC desde
%                         el microcontrolador ESP32.
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Diciembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.5
% ------------------------------------------------------------


%% PROCESO DE EXTRACCIÓN DE CARACTERÍSTICAS DE LOS SEGMENTOS DE LAS SEÑALES sEMG MEDIANTE ENFOQUE DE VENTANAS DE RECORRIDO

% Este código permite extraer las características de los segmentos de las
% señales sEMG acorde a los protocolos de adquisición (M3sec y M5sec)
% mediante un enfoque de recorrido de ventanas y porcentajes de
% solapamiento

clear all;
clc;
close all;

% Directorio donde se encuentran las carpetas con los segmentos de señales
inputDirectory = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef';

% Carpeta donde se guardarán los archivos con las características calculadas
outputDirectory = '../FeaturesExtracted_sEMGsignals/featuresLimpiasDef';

% Crear la carpeta de salida si no existe
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end

% Parámetros de segmentación
fs = 1200; % Frecuencia de muestreo (Hz)

% Tamaños de ventana y desplazamiento finales 
window_size = 360; % 300 ms -> 360 muestras
step_size = 90; %  75 ms -> 90 muestras (75%)

%window_size = 300; % 250 ms -> 300 muestras
% step_size = 210; %  175 ms -> 210 muestras (30%)
% step_size = 150; %  125 ms -> 150 muestras (50%)
%step_size = 75; %  62.5 ms -> 150 muestras (75%)

% window_size = 240; % 200 ms -> 240 muestras
% step_size = 60; % 50 ms -> 60 muestras
% step_size = 120; % 100 ms -> 120 muestras
% step_size = 180; % 150 ms -> 180 muestras


% Listar todas las subcarpetas dentro de la carpeta 'segmentos'
signalTypeSubfolders = dir(fullfile(inputDirectory, '**', 'segmentos', '*'));
signalTypeSubfolders = signalTypeSubfolders([signalTypeSubfolders.isdir]); % Filtrar solo directorios

% Inicializar estructura para almacenar las características de todas las señales
allFeatures = struct();
processedFolders = {}; % Lista de carpetas ya procesadas para evitar repeticiones

% Recorrer cada subcarpeta (representa un tipo de señal)
for i = 1:length(signalTypeSubfolders)
    
    % Obtener el nombre de la carpeta principal (contiene "segmentos")
    [~, mainFolderName] = fileparts(fileparts(signalTypeSubfolders(i).folder));
    
    folderName = signalTypeSubfolders(i).name; % Nombre de la carpeta actual
    folderPath = fullfile(signalTypeSubfolders(i).folder, folderName); % Ruta completa de la carpeta

    % Verificar si esta carpeta ya fue procesada
    if any(strcmp(processedFolders, folderPath))
        continue;
    end
    
    % Marcar esta carpeta como procesada
    processedFolders{end+1} = folderPath;

    % Obtener los archivos .mat de los segmentos
    segmentFiles = dir(fullfile(folderPath, '*.mat'));

    % Verificar que haya al menos 8 segmentos en la carpeta
    if length(segmentFiles) < 8
        % Saltar la carpeta si no hay suficientes segmentos
        continue;
    end

    % Inicializar estructura para almacenar las características de este tipo de señal
    signalType = struct();

    % Procesar cada uno de los segmentos contenidos en las carpetas del tipo de señal
    for segIndex = 1:length(segmentFiles)
        % Cargar el archivo .mat con los datos del segmento
        fileName = segmentFiles(segIndex).name;
        filePath = fullfile(segmentFiles(segIndex).folder, fileName);
        
        % Determinar si el archivo es de gesto o reposo
        if contains(fileName, '_REP')
            data = load(filePath, 'segmentoReposo', 'time_vector_reposo');
            emg_signal = data.segmentoReposo;
            segmentName = sprintf('segmento_REP_%02d', segIndex);
        else
            data = load(filePath, 'segmentoGesto', 'time_vector_gesto');
            emg_signal = data.segmentoGesto;
            segmentName = sprintf('segmento_%02d', segIndex);
        end
        
        num_samples = length(emg_signal);
        num_windows = floor((num_samples - window_size) / step_size) + 1;
        
        % Inicializar la estructura de características para todas las ventanas
        features = struct(...
            'MAV', zeros(1, num_windows), ...
            'WL', zeros(1, num_windows), ...
            'MWL', zeros(1, num_windows), ...
            'SCC', zeros(1, num_windows), ...
            'ZC', zeros(1, num_windows), ...
            'IEMG', zeros(1, num_windows), ...
            'SSI', zeros(1, num_windows), ...
            'Mean', zeros(1, num_windows), ...
            'Variance', zeros(1, num_windows), ...
            'SD', zeros(1, num_windows), ...
            'RMS', zeros(1, num_windows), ...
            'WAMP', zeros(1, num_windows), ...
            'AAC', zeros(1, num_windows), ...
            'Skewness', zeros(1, num_windows), ...
            'Kurtosis', zeros(1, num_windows), ...
            'DASDV', zeros(1, num_windows), ...
            'MMAV1', zeros(1, num_windows), ...
            'MMAV2', zeros(1, num_windows), ...
            'MAX', zeros(1, num_windows), ...
            'RSSL', zeros(1, num_windows) ...
       );
        
        % Extraer características por ventana
        for win = 1:num_windows
            start_idx = (win - 1) * step_size + 1;
            end_idx = start_idx + window_size - 1;
            window_data = emg_signal(start_idx:end_idx);
            
            % Calcular características específicas del segmento
            features.MAV(win) = computeMAV(window_data); 
            features.WL(win) = computeWL(window_data); 
            features.MWL(win) = computeMWL(window_data); 
            features.SCC(win) = computeSCC(window_data, 4); 
            features.ZC(win) = computeZC(window_data); 
            features.IEMG(win) = computeIEMG(window_data); 
            features.SSI(win) = computeSSI(window_data); 
            features.Mean(win) = computeMean(window_data); 
            features.Variance(win) = computeVariance(window_data); 
            features.SD(win) = computeSD(window_data); 
            features.RMS(win) = computeRMS(window_data); 
            features.WAMP(win) = computeWAMP(window_data, 4); 
            features.AAC(win) = computeAAC(window_data); 
            features.Skewness(win) = computeSkewness(window_data); 
            features.Kurtosis(win) = computeKurtosis(window_data); 
            features.DASDV(win) = computeDASDV(window_data); 
            features.MMAV1(win) = computeMMAV1(window_data); 
            features.MMAV2(win) = computeMMAV2(window_data);
            features.MAX(win) = double(computeMAX(window_data));
            features.RSSL(win) = computeRSSL(window_data);
        end
        
        % Almacenar en estructura
        signalType.(segmentName).features = features;
    end

    % Almacenar en la estructura principal
    signalTypeName = strrep(folderName, ' ', '_');
    allFeatures.(signalTypeName) = signalType;

    % Guardar las características en un archivo .mat
    outputFileName = fullfile(outputDirectory, sprintf('features_%s.mat', mainFolderName));
    save(outputFileName, 'allFeatures');
    
    disp(['Características almacenadas en: ', outputFileName]);
end


% Funciones para el cálculo de características (idénticas al código original)
function mav = computeMAV(segmento)
    mav = mean(abs(segmento));
end

function wl = computeWL(segmento)
    wl = sum(abs(diff(segmento)));
end

function mwl = computeMWL(segmento)
    mwl = sum(abs(diff(diff(segmento)))); 
end

function scc = computeSCC(segmento, umbral)
    scc = sum(((segmento(2:end-1) - segmento(1:end-2)) .* (segmento(2:end-1) - segmento(3:end))) >= umbral);
end

function zc = computeZC(segmento)
    zc = sum(diff(sign(segmento)) ~= 0);
end

function iemg = computeIEMG(segmento)
    iemg = sum(abs(segmento));
end

function ssi = computeSSI(segmento)
    ssi = sum(segmento.^2);
end

function mean_val = computeMean(segmento)
    mean_val = mean(segmento);
end

function variance = computeVariance(segmento)
    variance = var(segmento);
end

function std_dev = computeSD(segmento)
    std_dev = std(segmento);
end

function rms = computeRMS(segmento)
    rms = sqrt(mean(segmento.^2));
end

function wamp = computeWAMP(segmento, umbral)
    wamp = sum(abs(diff(segmento)) >= umbral);
end

function aac = computeAAC(segmento)
    aac = mean(abs(diff(segmento)));
end

function skewness_val = computeSkewness(segmento)
    skewness_val = skewness(segmento);
end

function kurtosis_val = computeKurtosis(segmento)
    kurtosis_val = kurtosis(segmento);
end

function dasdv = computeDASDV(segmento)
    dasdv = sqrt(mean(diff(segmento).^2));
end

function mmav1 = computeMMAV1(segmento)
    n = length(segmento);
    w = ones(size(segmento)) * 0.5;
    w(round(0.25*n):round(0.75*n)) = 1;
    mmav1 = mean(w .* abs(segmento));
end

function mmav2 = computeMMAV2(segmento)
    n = length(segmento);
    w = zeros(size(segmento));
    for i = 1:n
        if i < 0.25*n
            w(i) = (4*i)/n;
        elseif i > 0.75*n
            w(i) = (4*(i-n))/i;
        else
            w(i) = 1;
        end
    end
    mmav2 = mean(w .* abs(segmento));
end

function maxValue = computeMAX(segmento)
    maxValue = max(segmento);
end

function rssl = computeRSSL(segmento)
    % computeRSSL - Calcula la característica Root Sum of Square Level (RSSL)
    %
    % Sintaxis:
    %   rssl = computeRSSL(signal)
    %
    % Entrada:
    %   signal - Vector que contiene el segmento de la señal sEMG
    %
    % Salida:
    %   rssl - Valor de la característica RSSL del segmento
    
    % Cálculo de Root Sum of Square Level (RSSL)
    rssl = sqrt(sum(segmento.^2));
end
