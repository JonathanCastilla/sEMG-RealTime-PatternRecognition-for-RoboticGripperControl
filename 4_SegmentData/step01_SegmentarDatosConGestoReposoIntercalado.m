
% ------------------------------------------------------------
% Nombre del archivo  :   step01_SegmentarDatosConGestoReposoIntercalado.m
% Descripción         :   Segmentar las señales sEMG adquiridas
%                         con Filtro Feed Forward Comb (FFC) con Envolvente
%                         Lineal de dos canales analógicos (Extensor Común de los Dedos y 
%                         Flexor Superficial de los Dedos) mediante comunicación serial
%                         procesadas con filtro FFC desde
%                         el microcontrolador ESP32 acorde al protocolo de
%                         adquisición propuesto (M3sec y M5sec)
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Noviembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.2
% ------------------------------------------------------------

%% SEGMENTAR GRABACIONES sEMG ACORDE A LOS PROTOCOLOS DE ADQUISICIÓN PROPUESTOS

% Directorio donde se encuentran los archivos .mat
directorioEntrada = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef';

% Listar todos los archivos .mat en el directorio
archivosMat = dir(fullfile(directorioEntrada, '*.mat'));

% Definir los intervalos de gestos y reposo para M5sec
desfaseReposo_M5sec = -2;
desfaseReposo_M3sec = [-0.25 -0.25];
desfaseGesto_M5sec = [-0.5 0.5];
desfaseGesto_M3sec = [-0.25 0.25];

intervalosM5sec = [10 15; 25 30; 40 45; 55 60; 70 75; 85 90; 100 105; 115 120; 130 135; 145 150] + desfaseGesto_M5sec;
reposoM5sec = [5 10; 20 25; 35 40; 50 55; 65 70; 75 85; 90 100; 105 115; 120 130; 135 145] + desfaseReposo_M5sec;

% Definir los intervalos de gestos y reposo para M3sec
intervalosM3sec = [3 5; 8 10; 13 15; 18 20; 23 25; 28 30; 33 35; 38 40; 43 45; 48 50] + desfaseGesto_M3sec;
reposoM3sec = [1 3; 6 8; 11 13; 16 18; 21 23; 26 28; 31 33; 36 38; 41 43; 46 48] + desfaseReposo_M3sec;

% Recorrer cada archivo .mat
for k = 1:length(archivosMat)
    nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name); % Obtener la ruta completa del archivo
    load(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo'); % Cargar los datos del archivo
    [~, nombreArchivo, ~] = fileparts(nombreCompletoArchivo); % Extraer el nombre del archivo sin extensión
    partes = strsplit(nombreArchivo, '_'); % Dividir el nombre del archivo en partes
    
    % Buscar la posición del primer elemento que comienza con 'M' seguido de un número
    indiceM = find(~cellfun('isempty', regexp(partes, '^M\d+')), 1);
    
    % Crear la ruta completa de carpetas hasta el elemento que comienza con 'M'
    ruta_carpetas = fullfile(directorioEntrada, partes{1:indiceM});
    
    % Crear las carpetas correspondientes si no existen
    if ~exist(ruta_carpetas, 'dir')
        mkdir(ruta_carpetas);
    end
    
    % Crear la carpeta con el nombre del archivo .mat (sin extensión)
    carpetaArchivo = fullfile(ruta_carpetas, nombreArchivo);
    if ~exist(carpetaArchivo, 'dir')
        mkdir(carpetaArchivo);
    end
    
    % Crear la carpeta "segmentos" dentro de esta carpeta
    carpetaSegmentos = fullfile(carpetaArchivo, 'segmentos');
    if ~exist(carpetaSegmentos, 'dir')
        mkdir(carpetaSegmentos);
    end
    
    % Determinar los intervalos de gesto y reposo según el tipo de protocolo
    if contains(nombreArchivo, 'M5sec')
        intervalosGesto = intervalosM5sec;
        intervalosReposo = reposoM5sec;
    elseif contains(nombreArchivo, 'M3sec')
        intervalosGesto = intervalosM3sec;
        intervalosReposo = reposoM3sec;
    else
        error('Formato de archivo desconocido.'); % Mostrar error si el formato es desconocido
    end
    
    fs = variablesMuestreo.frecuenciaMuestreo; % Obtener la frecuencia de muestreo
    
    % Llamar a la función que segmenta y guarda los datos
    segmentarEstructurasConGuardado(capturaDatos, fs, intervalosGesto, intervalosReposo, carpetaSegmentos);
    disp(['Segmentos guardados en: ', carpetaSegmentos]); % Mensaje de confirmación
end

% Función para segmentar y guardar los datos
function segmentarEstructurasConGuardado(capturaDatos, fs, intervalosGesto, intervalosReposo, carpetaSegmentos)
    campos = fieldnames(capturaDatos); % Obtener los nombres de los campos en capturaDatos
    if ~exist(carpetaSegmentos, 'dir'), mkdir(carpetaSegmentos); end % Crear la carpeta si no existe
    
    % Iterar sobre cada campo en capturaDatos
    for i = 1:length(campos)
        campoActual = campos{i}; % Obtener el nombre del campo actual
        if isnumeric(capturaDatos.(campoActual)) % Verificar si el campo contiene datos numéricos
            subcarpetaCampo = fullfile(carpetaSegmentos, campoActual); % Definir la subcarpeta para el campo
            if ~exist(subcarpetaCampo, 'dir'), mkdir(subcarpetaCampo); end % Crear la subcarpeta si no existe
            
            % Iterar sobre cada intervalo de gesto y reposo
            for j = 1:size(intervalosGesto, 1)
                [segmentoGesto, time_vector_gesto] = extraerSegmento(capturaDatos.(campoActual), fs, intervalosGesto(j, :));
                [segmentoReposo, time_vector_reposo] = extraerSegmento(capturaDatos.(campoActual), fs, intervalosReposo(j, :));
                
                % Normalización de gestos
                % segmentoGesto = normalizeSignalsEMG_minmax(segmentoGesto);
                % segmentoReposo = normalizeSignalsEMG_minmax(segmentoReposo);
                
                % Definir nombres de archivos para gesto y reposo
                nombreGesto = sprintf('%s_segmento_%02d.mat', campoActual, j);
                nombreReposo = sprintf('%s_segmento_%02d_REP.mat', campoActual, j);
                
                % Guardar los segmentos en archivos .mat con sus respectivos vectores de tiempo
                save(fullfile(subcarpetaCampo, nombreGesto), 'segmentoGesto', 'time_vector_gesto');
                save(fullfile(subcarpetaCampo, nombreReposo), 'segmentoReposo', 'time_vector_reposo');
            end
        end
    end
end

%% FUNCIONES AUXILIARES
% SEGMENTAR SEÑALES sEMG
% Función para extraer un segmento de la señal
function [segmento, time_vector] = extraerSegmento(sEMGmuestra, fs, intervalo)
    startIdx = round(intervalo(1) * fs) + 1; % Calcular el índice de inicio del segmento
    endIdx = round(intervalo(2) * fs); % Calcular el índice de fin del segmento
    segmento = sEMGmuestra(startIdx:endIdx); % Extraer los datos del segmento
    time_vector = (startIdx:endIdx) / fs; % Crear el vector de tiempo
end

%% NORMALIZAR SEÑALES sEMG
% NORMALIZAR SEÑALES sEMG CON STANDARD SCALER
function [normalizedSignalsEMG] = normalizeSignalsEMG(sEMGsignal)
    meanValue = mean(sEMGsignal);  % Calcular la media
    stdValue = std(sEMGsignal);    % Calcular la desviación estándar
    
    % Aplicar normalización StandardScaler
    normalizedSignalsEMG = (sEMGsignal - meanValue) / stdValue;
end

%% NORMALIZAR SEÑALES sEMG CON MIN-MAX [-1,1]
function [normalizedSignalsEMG] = normalizeSignalsEMG_minmax(sEMGsignal)
    % Normaliza la señal sEMG en el rango [-1,1] usando Min-Max Scaling
    %
    % Parámetros:
    %   sEMGsignal: Vector o matriz con la señal EMG a normalizar
    %
    % Retorna:
    %   normalizedSignalsEMG: Señal normalizada en el rango [-1,1]
    
    minValue = min(sEMGsignal(:)); % Obtener el valor mínimo
    maxValue = max(sEMGsignal(:)); % Obtener el valor máximo
    
    % Aplicar normalización Min-Max en el rango [-1,1]
    normalizedSignalsEMG = 2 * (sEMGsignal - minValue) / (maxValue - minValue) - 1;
end