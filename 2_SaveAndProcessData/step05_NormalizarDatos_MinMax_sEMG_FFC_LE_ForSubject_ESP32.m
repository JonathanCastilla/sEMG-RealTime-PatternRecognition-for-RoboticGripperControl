
% ------------------------------------------------------------
% Nombre del archivo  :   step05_NormalizarDatos_MinMax_sEMG_FFC_LE_ForSubject_ESP32.m
% Descripción         :   Normalización personalizada para cada sujeto de grabación
%                         de tipo MinMaxScaler a la señal sEMG 
%                         con Filtro Feed Forward Comb (FFC) con Envolvente
%                         Lineal de dos canales analógicos (Extensor Común de los Dedos y 
%                         Flexor Superficial de los Dedos) mediante comunicación serial
%                         procesadas con filtro FFC desde
%                         el microcontrolador ESP32 
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Septiembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.5
% ------------------------------------------------------------


%% NORMALIZACIÓN MinMaxScaler PERSONALIZADA POR SUJETO DEL PROCESAMIENTO DE LA SEÑAL sEMG DE INTERÉS:
% sEMG-FFC-LE-ESP32
clear all; clc; close all;

% Directorio donde se encuentran los archivos .mat
directorioEntrada = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef';
archivosMat = dir(fullfile(directorioEntrada, '*.mat'));
nameField = 'sEMG_FFC_envelopeLineal_ESP32';  % Campo de la señal a normalizar

% 1. OBTENER MÍNIMOS Y MÁXIMOS GLOBALES POR SUJETO (P#)
% ====================================================
sujetos = struct();  % Estructura para almacenar min/max por sujeto
patron = '_P(\d+)$';  % Expresión regular para extraer P# (ej: P4)

disp('=== Calculando mínimos/máximos globales por sujeto ===');

for k = 1:length(archivosMat)
    nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name);
    [~, nombreArchivo, ~] = fileparts(nombreCompletoArchivo);
    
    % Extraer número de sujeto (P#)
    tokens = regexp(nombreArchivo, patron, 'tokens');
    if isempty(tokens)
        warning('Archivo %s no sigue el formato esperado (_P#). Se omite.', nombreArchivo);
        continue;
    end
    numSujeto = str2double(tokens{1}{1});
    sujetoID = ['P' num2str(numSujeto)];  % Ej: 'P4'
    
    % Cargar datos y obtener min/max de esta muestra
    load(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo');
    currentMin = min(capturaDatos.(nameField));
    currentMax = max(capturaDatos.(nameField));
    
    % Si es la primera muestra del sujeto, inicializar min/max
    if ~isfield(sujetos, sujetoID)
        sujetos.(sujetoID).minGlobal = currentMin;
        sujetos.(sujetoID).maxGlobal = currentMax;
    else
        % Actualizar min/max global del sujeto (si hay un nuevo extremo)
        sujetos.(sujetoID).minGlobal = 0;
        % sujetos.(sujetoID).minGlobal = min(sujetos.(sujetoID).minGlobal, currentMin);
        sujetos.(sujetoID).maxGlobal = max(sujetos.(sujetoID).maxGlobal, currentMax);
    end
    
    fprintf('Muestra: %s → Sujeto: %s | Min: %.4f | Max: %.4f\n', ...
        nombreArchivo, sujetoID, currentMin, currentMax);
end

% Mostrar resumen de min/max por sujeto
disp('=== Resumen de mínimos/máximos globales por sujeto ===');
nombresSujetos = fieldnames(sujetos);
for i = 1:length(nombresSujetos)
    sujetoID = nombresSujetos{i};
    fprintf('Sujeto %s → minGlobal: %.4f | maxGlobal: %.4f\n', ...
        sujetoID, sujetos.(sujetoID).minGlobal, sujetos.(sujetoID).maxGlobal);
end

% 2. NORMALIZAR CADA ARCHIVO SEGÚN SU SUJETO (USANDO SUS minGlobal/maxGlobal)
% ===========================================================================
disp('=== Iniciando normalización MinMax por sujeto ===');

for k = 1:length(archivosMat)
    nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name);
    [~, nombreArchivo, ~] = fileparts(nombreCompletoArchivo);
    disp(['Procesando: ' nombreArchivo]);
    
    % Extraer número de sujeto (P#)
    tokens = regexp(nombreArchivo, patron, 'tokens');
    if isempty(tokens)
        continue;  % Saltar si no coincide
    end
    numSujeto = str2double(tokens{1}{1});
    sujetoID = ['P' num2str(numSujeto)];
    
    % Cargar datos
    load(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo');
    
    % Obtener minGlobal y maxGlobal del sujeto
    minSujeto = 0;
    % minSujeto = sujetos.(sujetoID).minGlobal;
    maxSujeto = sujetos.(sujetoID).maxGlobal;
    
    % Normalizar la señal con los valores del sujeto
    capturaDatos.sEMG_nomMinMaxForSubject_FFC_LE_ESP32 = normalizeSignalsEMG_minMax(...
        capturaDatos.(nameField), minSujeto, maxSujeto);
    
    % Guardar los datos actualizados (sobreescribe el archivo original)
    save(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo');
    
    fprintf('Normalizado: %s → [Sujeto %s] min=%.4f, max=%.4f\n', ...
        nombreArchivo, sujetoID, minSujeto, maxSujeto);
end

disp('=== ¡Proceso completado! ===');

%% FUNCIÓN DE NORMALIZACIÓN MIN-MAX [0, 1]
function normalizedSignalsEMG = normalizeSignalsEMG_minMax(sEMGsignal, Xmin, Xmax)
    % Normaliza la señal en el rango [0, 1] usando Min-Max Scaling
    % Evita división por cero (si Xmax == Xmin, devuelve 0)
    if (Xmax - Xmin) == 0
        normalizedSignalsEMG = zeros(size(sEMGsignal));
    else
        normalizedSignalsEMG = (sEMGsignal - Xmin) / (Xmax - Xmin);
    end
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



