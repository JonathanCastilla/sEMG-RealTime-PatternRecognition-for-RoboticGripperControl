% ------------------------------------------------------------
% Nombre del archivo  :   step01_ExportarCaracteristicas_ArchivosCSV.m
% Descripción         :   Este código permite unificar y exportar las características seleccionadas en
%                         archivos CSV de manera ordenada y especializada por cada protocolo de
%                         adquisición y por comando (gesto de muñeca) etiquetado de todas las
%                         grabaciones de los sujetos mediante la generación previa tanto de los
%                         segmentos como de los recorridos de ventana secuenciados en algoritmos
%                         anteriores.
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Febrero/2025
% Última modificación :   Junio/2025
% Versión             :   1.7
% ------------------------------------------------------------

%% EXPORTACIÓN DE VECTORES DE CARACTERÍSTICAS SELECCIONADAS EN ARCHIVOS CSV
% Este código permite unificar y exportar las características seleccionadas en
% archivos CSV de manera ordenada y especializada por cada protocolo de
% adquisición y por comando (gesto de muñeca) etiquetado de todas las
% grabaciones de los sujetos mediante la generación previa tanto de los
% segmentos como de los recorridos de ventana secuenciados en algoritmos
% anteriores.

clc;
clear all;
close all;

% Directorio donde se encuentran los archivos .mat
directorioEntrada = '../FeaturesExtracted_sEMGsignals/featuresLimpiasDef';
%directorioSalida = 'dataSet_allFeatures_sEMG_nomMaxMin_FFC_ESP32_LE';
% directorioSalida = 'dataSet_allFeatures_sEMG_nomMaxMinForSubject_FFC_ESP32_LE';
% directorioSalida = 'dataSetResults_sEMG_nomMinMaxForSubject_FFC_ESP32_LE_MatrixCorr';
% directorioSalida = 'dataSetResults_sEMG_nomMinMax_FFC_ESP32_LE_MatrixCorr';
% directorioSalida = 'dataSetResults_sEMG_nomMinMax_FFC_ESP32_LE_MatrixCorr+PCA';


% directorioSalida = '../FeaturesExtracted_sEMGsignals/dataSetResults_sEMG_nomMinMaxForSubject_FFC_ESP32_LE_AllFeatures';
directorioSalida = '../FeaturesExtracted_sEMGsignals/dataSetResults_sEMG_nomMinMaxForSubject_FFC_ESP32_LE_MatrixCorr';
% directorioSalida = '../FeaturesExtracted_sEMGsignals/dataSetResults_sEMG_nomMinMaxForSubject_FFC_ESP32_LE_MatrixCorr+PCA';


% Crear el nuevo directorio para almacenar CSVs
directorioSalida = fullfile(fileparts(directorioEntrada), directorioSalida);
if ~exist(directorioSalida, 'dir')
    mkdir(directorioSalida);
end

% Listar todos los archivos .mat en el directorio
archivosMat = dir(fullfile(directorioEntrada, '*.mat'));

% Obtener todos los nombres de campos únicos de TODOS los archivos
allFieldNames = obtenerTodosLosNombresDeCampos(directorioEntrada, archivosMat);

% Mostrar las señales disponibles (nombres únicos y ordenados)
disp('Señales sEMG disponibles:');
for i = 1:length(allFieldNames)
    fprintf('%d: %s\n', i, allFieldNames{i});
end

% Selección de la señal mediante un índice
index_feature = input('\nSeleccionar la señal sEMG para el proceso de Selección de Características con un índice: ');
if index_feature < 1 || index_feature > length(allFieldNames)
    error('Índice seleccionado fuera de rango');
end
selectedFieldName = allFieldNames{index_feature};

% FEATURE SELECTION
% features_selected = {'MAV', 'WL', 'MWL', 'SCC', 'ZC', 'IEMG', 'SSI', 'Mean', ...
%                   'Variance', 'SD', 'RMS', 'WAMP', 'AAC', 'Skewness', 'Kurtosis', ...
%                    'DASDV', 'MMAV1', 'MMAV2', 'MAX', 'RSSL'};

% Características resultado de la matriz de correlación (thr = 0.97)
% para sEMG_nomMinMax_FFC_LE_ESP32
% features_selected = {'WL', 'IEMG', 'SSI', 'Mean', 'Variance', 'Skewness', 'Kurtosis', 'MMAV2', 'MAX'};
% features_selected = {'MAX', 'IEMG', 'Mean'}; % MatCorr + PCA (reduced1)
% (85% precision)
% features_selected = {'MAX', 'IEMG', 'Mean', 'Skewness'}; % MatCorr + PCA (reduced2)
% (85% precision)
% features_selected = {'MAX', 'IEMG', 'Mean', 'WL', 'MMAV2', 'Skewness'}; % MatCorr + PCA (99.7% precision)

% Características normalizadas MinMax pero con Min = 0 y cambio de desfase
% para REP (Correccion de normalize_columns)
% features_selected = {'IEMG', 'MAX', 'MMAV2', 'WL', 'SD', 'Skewness'}; % MatCorr + PCA
% features_selected = {'IEMG', 'MAX', 'MMAV2', 'Skewness'}; % MatCorr + PCA (reduced1)
% features_selected = {'IEMG', 'MAX', 'MMAV2', 'WL', 'Skewness'}; % MatCorr + PCA (reduced2)

% features_selected = {'WL', 'MWL', 'IEMG', 'Variance', 'Skewness', 'Kurtosis'}; %MatCorr
% features_selected = {'MWL', 'IEMG', 'WL', 'Variance', 'Kurtosis'}; % MatCorr + PCA (78%)
% features_selected = {'MWL', 'IEMG', 'WL', 'Variance'}; % MatCorr + PCA (reduced1) (79.5%)

% Características resultado de la matriz de correlación (thr = 0.8)
% para sEMG_nomMinMaxForSubject_FFC_LE_ESP32 (Correccion de
% normalize_columns) y muestrasLimpiasDef
% features_selected = {'WL', 'MWL', 'IEMG', 'Variance', 'Skewness', 'Kurtosis', 'DASDV'};

features_selected = {'IEMG', 'WL', 'MWL', 'Variance', 'DASDV'}; % MatCorr
% + PCA (89.9%)
% features_selected = {'IEMG', 'MWL', 'WL'}; % MatCorr + PCA (reduced1) (75%)

% Obtener lista de carpetas con datos
listaRutaCarpetas = obtenerRutasCarpetas(directorioEntrada, archivosMat);

% Matrices para acumular segmentos de reposo según la etiqueta
unifiedReposoEDC = [];
unifiedReposoFDS = [];

for n = 1:length(listaRutaCarpetas)
    folderpath = listaRutaCarpetas{n}; 
    [dataMatrix, dataMatrixRep] = featuresExtractionMejorada(string(folderpath), features_selected, selectedFieldName);
    
    % Generar nombres de archivos de salida
    [outputFileNameGesto, outputFileNameGestoCSV] = generarNombresArchivos(...
        folderpath, directorioSalida, selectedFieldName, features_selected);
    
    % Guardar datos de gestos
    if ~isempty(dataMatrix)
        guardarDatosCSV(outputFileNameGesto, features_selected, dataMatrix);
        guardarDatosCSV(outputFileNameGestoCSV, features_selected, dataMatrix);
        disp(['Archivo de gestos generado: ', outputFileNameGesto]);
    else
        disp('No se encontraron segmentos de gesto para guardar.');
    end
    
    % Acumular datos de reposo según etiqueta
    if contains(folderpath, 'EDC')
        unifiedReposoEDC = acumularReposo(unifiedReposoEDC, dataMatrixRep);
    elseif contains(folderpath, 'FDS')
        unifiedReposoFDS = acumularReposo(unifiedReposoFDS, dataMatrixRep);
    else
        disp(['Carpeta sin etiqueta EDC o FDS: ', folderpath]);
    end
end

% Guardar matrices unificadas de reposo
guardarReposoUnificado(directorioSalida, 'EDC', unifiedReposoEDC, features_selected);
guardarReposoUnificado(directorioSalida, 'FDS', unifiedReposoFDS, features_selected);

%% FUNCIONES AUXILIARES ACTUALIZADAS

function allFieldNames = obtenerTodosLosNombresDeCampos(directorio, archivos)
    allFields = {};
    for k = 1:length(archivos)
        data = load(fullfile(directorio, archivos(k).name));
        if isfield(data, 'allFeatures')
            currentFields = fieldnames(data.allFeatures);
            allFields = union(allFields, currentFields);
        end
    end
    allFieldNames = sort(allFields); % Ordenamos alfabéticamente para consistencia
end

function listaRutaCarpetas = obtenerRutasCarpetas(directorioEntrada, archivosMat)
    listaRutaCarpetas = {};
    for k = 1:length(archivosMat)
        nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name);
        [~, nombreArchivo, ~] = fileparts(nombreCompletoArchivo);
        partes = strsplit(nombreArchivo, '_');
        indiceM = find(~cellfun('isempty', regexp(partes, '^M\d+')), 1);
        
        if ~isempty(indiceM)
            ruta_carpetas = fullfile(directorioEntrada, partes{1:indiceM});
            if isempty(listaRutaCarpetas) || ~any(strcmp(listaRutaCarpetas, ruta_carpetas))
                listaRutaCarpetas{end + 1} = ruta_carpetas;
            end
        end
    end
end

function [outputFileNameGesto, outputFileNameGestoCSV] = generarNombresArchivos(...
    folderpath, directorioSalida, subfieldName, features_selected)
    
    pathParts = split(folderpath, filesep);
    possibleStartNames = {'datosProtoboard', 'datosSensor'};
    startIndex = find(ismember(pathParts, possibleStartNames), 1);
    relevantParts = pathParts(startIndex:end);
    fileName = strjoin(relevantParts, '_');
    selectedFeaturesStr = strjoin(features_selected, '-');
    
    % Nombre corto si hay muchas características
    if length(features_selected) > 10
        featureStr = 'allFeatures';
    else
        featureStr = selectedFeaturesStr;
    end
    
    outputFileNameGesto = fullfile(folderpath, [fileName '_' subfieldName '_' featureStr '_gestos_dataSet.csv']);
    outputFileNameGestoCSV = fullfile(directorioSalida, [fileName '_' subfieldName '_' featureStr '_gestos_dataSet.csv']);
end

function [dataMatrix, dataMatrixRep] = featuresExtractionMejorada(folderPath, features_selected, fieldName)
    files = dir(fullfile(folderPath, '*.mat')); 
    dataMatrix = [];
    dataMatrixRep = [];

    for i = 1:length(files)
        filePath = fullfile(folderPath, files(i).name);
        try
            data = load(filePath);
            
            % Verificación robusta de la estructura del archivo
            if ~isfield(data, 'allFeatures')
                disp(['Archivo ', files(i).name, ' no contiene la estructura allFeatures. Saltando...']);
                continue;
            end
            
            % Verificar que el campo deseado existe
            if ~isfield(data.allFeatures, fieldName)
                disp(['Advertencia: Archivo ', files(i).name, ' no contiene el campo ', fieldName]);
                continue;
            end
            
            % Mensaje informativo
            disp(['Procesando archivo: ', files(i).name]);
            disp(['Accediendo campo: ', fieldName]);
            
            % Acceder al subcampo usando el nombre EXACTO
            signalSubfield = data.allFeatures.(fieldName);
            
            % Procesamiento de segmentos
            for j = 1:20
                % Segmentos de gesto
                segmentNameGesto = sprintf('segmento_%02d', j);
                if isfield(signalSubfield, segmentNameGesto)
                    currentSegment = signalSubfield.(segmentNameGesto);
                    if isfield(currentSegment, 'features')
                        valores = extraerCaracteristicas(currentSegment.features, features_selected, j);
                        dataMatrix = [dataMatrix; valores];
                    end
                end
                
                % Segmentos de reposo
                segmentNameReposo = sprintf('segmento_REP_%02d', j);
                if isfield(signalSubfield, segmentNameReposo)
                    currentSegment = signalSubfield.(segmentNameReposo);
                    if isfield(currentSegment, 'features')
                        valores = extraerCaracteristicas(currentSegment.features, features_selected, j);
                        dataMatrixRep = [dataMatrixRep; valores];
                    end
                end
            end
            
        catch ME
            disp(['Error procesando archivo: ', files(i).name]);
            disp(['Mensaje de error: ', ME.message]);
            disp('Continuando con el siguiente archivo...');
        end
    end
end

function valores = extraerCaracteristicas(features, features_selected, segmentNum)
    valores = [];
    for k = 1:length(features_selected)
        featureName = features_selected{k};
        if isfield(features, featureName)
            % Asegurarse de que los valores sean vector columna
            featureValues = features.(featureName)(:);
            valores = [valores, featureValues];
        else
            % Si la característica no existe, usar NaN del tamaño correcto
            if ~isempty(valores)
                valores = [valores, NaN(size(valores, 1), 1)];
            else
                % Si es la primera característica, necesitamos determinar el tamaño
                % Buscar la primera característica existente para determinar el tamaño
                for m = 1:length(features_selected)
                    if isfield(features, features_selected{m})
                        refSize = numel(features.(features_selected{m}));
                        valores = [NaN(refSize, 1)];
                        break;
                    end
                end
                if isempty(valores)
                    valores = [NaN(1, 1)]; % Tamaño por defecto si no hay referencias
                end
                valores = [valores, NaN(size(valores, 1), 1)];
            end
        end
    end
    etiqueta_segmento = repmat(segmentNum, size(valores, 1), 1);
    valores = [etiqueta_segmento, valores];
end

function guardarDatosCSV(filename, features_selected, data)
    headers = ['No. segment', features_selected];
    writecell(headers, filename);
    writematrix(data, filename, 'WriteMode', 'append');
end

function unifiedReposo = acumularReposo(unifiedReposo, newData)
    if ~isempty(newData)
        unifiedReposo = [unifiedReposo; newData];
    end
end

function guardarReposoUnificado(directorioSalida, tipo, data, features_selected)
    if ~isempty(data)
        outputFileName = fullfile(directorioSalida, ['reposo_' tipo '_unificado_dataSet.csv']);
        guardarDatosCSV(outputFileName, features_selected, data);
        disp(['Archivo unificado de reposo ' tipo ' generado: ', outputFileName]);
    else
        disp(['No se encontraron segmentos de reposo ' tipo ' para unificar.']);
    end
end