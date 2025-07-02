

% ------------------------------------------------------------
% Nombre del archivo  :   step01_GraficarDatosSegmentados.m
% Descripción         :   Este código permite graficar cada uno de los datos segmentados de manera
%                         por sesión de grabación realizada de todas las sesiones almacenadas de manera automática, 
%                         guardando los graficos generados sus subdirectorios correspondientes
%                         dónde se encuentran las muestras etiquetadas señales sEMG adquiridas
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
% Versión             :   1.3
% ------------------------------------------------------------

%% GRAFICAR DATOS SEGMENTADOS DE MANERA AUTOMÁTICA
% Este código permite graficar cada uno de los datos segmentados de manera
% por sesión de grabación realizada de todas las sesiones almacenadas de manera automática, 
% guardando los graficos generados sus subdirectorios correspondientes
% dónde se encuentran las muestras etiquetadas
clear all;
clc; 
close all;

% Directorio donde se encuentran las carpetas con los segmentos
directorioEntrada = 'sEMGmuestrasLimpiasDef';

% Listar todas las subcarpetas dentro de la carpeta 'segmentos'
subcarpetasTipoSenal = dir(fullfile(directorioEntrada, '**', 'segmentos', '*'));

% Filtrar las subcarpetas que realmente son directorios (tipos de señal)
subcarpetasTipoSenal = subcarpetasTipoSenal([subcarpetasTipoSenal.isdir]);

% Lista para guardar las carpetas ya procesadas
carpetasProcesadas = {};

% Recorrer cada subcarpeta (cada tipo de señal)
for i = 1:length(subcarpetasTipoSenal)
    % Obtener la ruta de la subcarpeta del tipo de señal (por ejemplo, 'signal1', 'signal2', ...)
    subcarpetaSenal = subcarpetasTipoSenal(i).folder;
    
    % Verificar si la subcarpeta ya ha sido procesada
    if ismember(subcarpetaSenal, carpetasProcesadas)
        continue;  % Saltar si ya ha sido procesada
    end
    
    % Mostrar el directorio que se está procesando
    disp(['Accediendo a la carpeta: ', subcarpetaSenal]);

    % Obtener las subcarpetas dentro de 'segmentos' para cada tipo de señal
    subcarpetasDeSegmentos = dir(fullfile(subcarpetaSenal, '*'));
    subcarpetasDeSegmentos = subcarpetasDeSegmentos([subcarpetasDeSegmentos.isdir]);
    
    % Filtrar solo las carpetas que contienen los archivos .mat de los segmentos
    subcarpetasDeSegmentos = subcarpetasDeSegmentos(~ismember({subcarpetasDeSegmentos.name}, {'.', '..'}));

    % Recorrer las subcarpetas que contienen los segmentos de cada tipo de señal
    for j = 1:length(subcarpetasDeSegmentos)
        subcarpetaDeSegmento = fullfile(subcarpetaSenal, subcarpetasDeSegmentos(j).name);
        
        if contains(subcarpetaDeSegmento, 'tiempo')
            disp('Carpeta "tiempo" encontrada. Terminando el proceso de esta carpeta.');
            break;
        end
    
        archivosSegmentosSenal = dir(fullfile(subcarpetaDeSegmento, '*.mat'));
    
        if length(archivosSegmentosSenal) < 8
            warning('No se encontraron suficientes archivos de segmentos en %s.', subcarpetaDeSegmento);
            continue;
        end
    
        % === Clasificar archivos REP y GESTO ===
        archivosREP = archivosSegmentosSenal(contains({archivosSegmentosSenal.name}, '_REP'));
        archivosGESTO = archivosSegmentosSenal(~contains({archivosSegmentosSenal.name}, '_REP'));
    
        % Ordenar alfabéticamente de forma natural
        archivosREP = sort_nat({archivosREP.name});
        archivosGESTO = sort_nat({archivosGESTO.name});
    
        % Número de parejas REP-GESTO
        numParejas = min(length(archivosREP), length(archivosGESTO));
        
        % Preparar datos
        segmentos = cell(numParejas * 2, 1);
        tiempos = cell(numParejas * 2, 1);
        titulos = cell(numParejas * 2, 1);
        maxGlobal = 0;
    
        for k = 1:numParejas
            % === REP ===
            archivoREP = fullfile(subcarpetaDeSegmento, archivosREP{k});
            datosREP = load(archivoREP, 'segmentoReposo', 'time_vector_reposo');
            segmentos{(k-1)*2 + 1} = datosREP.segmentoReposo;
            tiempos{(k-1)*2 + 1} = datosREP.time_vector_reposo;
            titulos{(k-1)*2 + 1} = sprintf('REP\\_%02d', k);
            maxGlobal = max(maxGlobal, max(abs(datosREP.segmentoReposo)));
    
            % === GESTO ===
            archivoGESTO = fullfile(subcarpetaDeSegmento, archivosGESTO{k});
            datosG = load(archivoGESTO, 'segmentoGesto', 'time_vector_gesto');
            segmentos{(k-1)*2 + 2} = datosG.segmentoGesto;
            tiempos{(k-1)*2 + 2} = datosG.time_vector_gesto;
            titulos{(k-1)*2 + 2} = sprintf('GESTO\\_%02d', k);
            maxGlobal = max(maxGlobal, max(abs(datosG.segmentoGesto)));
        end
    
        % === CREAR FIGURA ===
        dimensionGrafico = 2;
        width = 700 * dimensionGrafico;
        height = 220 * dimensionGrafico;
    
        figure('Visible', 'off', 'Position', [100, 100, width, height]);
        [~, nombreSubcarpeta, ~] = fileparts(subcarpetaDeSegmento);
        nombreSubcarpetaLatex = strrep(nombreSubcarpeta, '_', '\_');
    
        for k = 1:length(segmentos)
            subplot(2, ceil(length(segmentos)/2), k);
            if contains(titulos{k}, 'GESTO')
                plot(tiempos{k}, segmentos{k}, 'color', '#3b8132'); % GESTO en rojo
            else
                plot(tiempos{k}, segmentos{k}, 'k'); % REP en negro
            end
            ylim([0, maxGlobal]);
            title(titulos{k}, 'Interpreter', 'latex');
            xlabel('Tiempo (s)');
            ylabel('Amplitud');
        end
    
        [rutaBase, ~] = fileparts(subcarpetasTipoSenal(i).folder);
        [~, nombreUltimaCarpeta] = fileparts(rutaBase);
    
        sgtitle(['Segmentos de Señales - ', nombreUltimaCarpeta, ' / ', nombreSubcarpetaLatex], 'Interpreter', 'latex');
        saveas(gcf, fullfile(subcarpetaDeSegmento, [nombreSubcarpeta, '_segmentos.png']));
        disp(['Figura guardada en: ', fullfile(subcarpetaDeSegmento, [nombreSubcarpeta, '_segmentos.png'])]);
        close all;
    end

     % Marcar como carpeta procesada
    carpetasProcesadas{end+1} = subcarpetaSenal;

end

function [sortedCell, ndx] = sort_nat(cellArray)
    % sort_nat: ordenamiento natural para nombres de archivos como REP_1, REP_2, REP_10
    expr = '\d+';
    numTokens = regexp(cellArray, expr, 'match');
    numbers = zeros(size(cellArray));
    
    for i = 1:length(cellArray)
        if ~isempty(numTokens{i})
            numbers(i) = str2double(numTokens{i}{1});
        else
            numbers(i) = Inf; % Al final si no hay número
        end
    end
    
    [~, ndx] = sort(numbers);
    sortedCell = cellArray(ndx);
end
