% ------------------------------------------------------------
% Nombre del archivo  :   step02_GuardarCaracteristicas_Segmentos.m
% Descripción         :   Este código permite guardar las características de los segmentos de las
%                         señales sEMG acorde a los protocolos de adquisición (M3sec y M5sec)
%                         mediante un enfoque de recorrido de ventanas y porcentajes de
%                         solapamiento de manera automática generando los subdirectorios
%                         correspondientes de cada una las de las muestras etiquetadas señales sEMG adquiridas
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
% Versión             :   1.1
% ------------------------------------------------------------

%% %% PROCESO DE GUARADADO AUTOMÁTICO DEL PROCESO DE EXTRACCIÓN DE CARACTERÍSTICAS DE LOS SEGMENTOS DE LAS SEÑALES sEMG MEDIANTE ENFOQUE DE VENTANAS DE RECORRIDO

% Este código permite guardar las características de los segmentos de las
% señales sEMG acorde a los protocolos de adquisición (M3sec y M5sec)
% resultantes del enfoque de recorrido de ventanas y porcentajes de
% solapamiento, generando los subdirectorios correspondientes de manera
% automática



% Directorio donde se encuentran los archivos .mat
directorioEntrada = '../FeaturesExtracted_sEMGsignals/featuresLimpiasDef'; 
% La variable `directorioEntrada` se define como la ruta del directorio que contiene los archivos `.mat` de entrada.

% Listar todos los archivos .mat en el directorio
archivosMat = dir(fullfile(directorioEntrada, '*.mat')); 
% La función `dir` se utiliza para obtener una lista de todos los archivos con extensión `.mat` en el directorio especificado. `fullfile` garantiza que la ruta sea correctamente formada para el sistema operativo en uso.

listaRutaCarpetas = cell(1, 1);

% Recorrer cada archivo .mat
for k = 1:length(archivosMat) 
% El bucle `for` se utiliza para iterar sobre cada archivo `.mat` encontrado en el directorio. La variable `k` actúa como índice del archivo actual en la lista `archivosMat`.

    % Nombre completo del archivo
    nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name); 
    % `fullfile` se utiliza para construir la ruta completa al archivo actual combinando el directorio y el nombre del archivo almacenado en `archivosMat(k).name`.

    % Cargar datos
    load(nombreCompletoArchivo, 'allFeatures'); 
    % La función `load` carga las variables `capturaDatos` y `variablesMuestreo` del archivo `.mat` especificado en `nombreCompletoArchivo`.

    % Extraer la estructura del nombre del archivo (sin la extensión)
    [~, nombreArchivo, ~] = fileparts(nombreCompletoArchivo); 
    % `fileparts` separa el nombre completo del archivo en tres partes: la ruta, el nombre sin extensión, y la extensión del archivo. Aquí solo se extrae el `nombreArchivo` sin la extensión.

    % Separar el nombre del archivo por guiones bajos
    partes = strsplit(nombreArchivo, '_'); 
    % La función `strsplit` divide el `nombreArchivo` en partes utilizando el guion bajo `_` como delimitador, creando un arreglo `partes` que contiene los componentes del nombre del archivo.

    % Buscar la posición del primer elemento que comienza con 'M' seguido de un número
    indiceM = find(~cellfun('isempty', regexp(partes, '^M\d+')), 1); 
    % La función `regexp` busca en cada elemento de `partes` si comienza con la letra 'M' seguida de uno o más dígitos (`\d+`). `find` devuelve el índice del primer elemento que cumple con esta condición.

    % Crear la ruta completa de carpetas hasta el elemento que comienza con 'M'
    ruta_carpetas = fullfile(directorioEntrada, partes{1:indiceM}); 
    % `fullfile` construye una ruta completa concatenando el directorio de entrada con las primeras partes del nombre del archivo (hasta el índice `indiceM`).

    % Crear las carpetas correspondientes si no existen
    if ~exist(ruta_carpetas, 'dir') 
        mkdir(ruta_carpetas); 
    end
    % La función `exist` verifica si la carpeta `ruta_carpetas` ya existe. Si no, la función `mkdir` crea el directorio.

    % % Crear una subcarpeta con el nombre del archivo (sin extensión)
    % ruta_subcarpeta = fullfile(ruta_carpetas, nombreArchivo); 
    % % Se construye una nueva ruta, `ruta_subcarpeta`, que incluye el nombre del archivo (sin extensión) como subcarpeta dentro de `ruta_carpetas`.
    % 
    % % Crear la subcarpeta si no existe
    % if ~exist(ruta_subcarpeta, 'dir') 
    %     mkdir(ruta_subcarpeta); 
    % end
    % % Similar al paso anterior, si la subcarpeta `ruta_subcarpeta` no existe, se crea usando `mkdir`.

    % Guardar los datos en la subcarpeta correspondiente
    ruta_guardado = fullfile(ruta_carpetas, [nombreArchivo, '.mat']); 
    % `ruta_guardado` es la ruta completa para guardar el archivo `.mat`, combinando `ruta_subcarpeta` con el nombre del archivo original y la extensión `.mat`.

    % Guardar los datos en el archivo .mat
    save(ruta_guardado, 'allFeatures');
    % La función `save` guarda las variables `capturaDatos` y `variablesMuestreo` en un archivo `.mat` en la ruta especificada por `ruta_guardado`.

    % Confirmación
    disp(['Datos guardados en: ', ruta_guardado]); 
    % La función `disp` imprime un mensaje en la consola que indica que los datos se han guardado correctamente en la ubicación especificada.

    % Almacenamiento de la ruta completa de las carpetas hasta el elemento
    % que comienza con "M"
    
    if k > 1
        if ~strcmp(listaRutaCarpetas{end, 1}, ruta_carpetas)
            listaRutaCarpetas{end + 1, 1} = {ruta_carpetas};
        end
    else
        listaRutaCarpetas{1, 1} = {ruta_carpetas};
    end
    
end