
% ------------------------------------------------------------
% Nombre del archivo  :   step07_Opcional_RenombrarEtiquetasComandos_DatosCarpetas.m
% Descripción         :   Este código opcional permite renombrar las
%                         etiquetas asociadas a los nombres de los comandos de muñeca
%                         propuestos en caso de presentarse cambios,
%                         permitiendo renombrar cada una las sesiones de 
%                         grabación de forma automática (archivos .mat)
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Septiembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.2
% ------------------------------------------------------------

%% RENOMBRAMIENTO DE ETIQUETAS ASOCIADAS A LOS NOMBRES DE LOS COMANDOS (MOVIMIENTOS DE MUÑECA) 
% En caso de presentarse cambios en los nombres de las etiquetas asociadas
% a los comandos de muñeca elegidos este código permite renombrar tales etiquetas en
% particular.

clc;
clear;

% Especificar el directorio con los archivos .mat
folderPath = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef'; % Cambia esta ruta según corresponda

% Verificar si el directorio existe
if ~isfolder(folderPath)
    error('El directorio especificado no existe. Verifica la ruta.');
end

% Obtener lista de archivos .mat en el directorio
fileList = dir(fullfile(folderPath, '*.mat'));

if isempty(fileList)
    disp('No se encontraron archivos .mat en el directorio especificado.');
    return;
end

% Definir las etiquetas a buscar y sus reemplazos
searchTags = ["TFF", "TFE", "CF"];
replaceTags = ["WF", "WE", "HC"];

% Recorrer los archivos y renombrar
for i = 1:length(fileList)
    oldName = fileList(i).name; % Nombre actual del archivo
    newName = oldName;          % Inicializar nuevo nombre
    
    % Reemplazar etiquetas en el nombre del archivo
    for j = 1:length(searchTags)
        newName = strrep(newName, searchTags(j), replaceTags(j));
    end
    
    % Verificar si el nombre cambió y renombrar el archivo
    if ~strcmp(oldName, newName)
        oldPath = fullfile(folderPath, oldName);
        newPath = fullfile(folderPath, newName);
        
        % Renombrar archivo
        try
            movefile(oldPath, newPath);
            fprintf('Archivo renombrado: %s -> %s\n', oldName, newName);
        catch ME
            warning('No se pudo renombrar %s: %s', oldName, ME.message);
        end
    end
end

disp('Renombrado de archivos completado.');
