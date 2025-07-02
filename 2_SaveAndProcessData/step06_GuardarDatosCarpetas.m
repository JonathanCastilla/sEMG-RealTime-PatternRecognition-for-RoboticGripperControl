
% ------------------------------------------------------------
% Nombre del archivo  :   step06_GuardarDatosCarpetas.m
% Descripción         :   Guardar los archivos .mat de las sesiones de
%                         grabación ya correctamente nombrados
%                         (etiquetados) mediante la creación de directorios
%                         automáticos generados mediante los nombres de los
%                         archivos generando las subcarpetas necesarias.
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Septiembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.0
% ------------------------------------------------------------

%% GUARDAR DATOS DE SESIONES DE GRABACIÓN DE MANERA AUTOMÁTICA
% GUARDAR LAS SESIONES DE GRABACIÓN PREVIAMENTE ETIQUETADAS DE FORMA AUTOMÁTICA EN DIRECTORIOS AUTOMATIZADOS ACORDE
% AL NOMBRE DEL ARCHIVO (ETIQUETA)

% Directorio donde se encuentran los archivos .mat
directorioEntrada = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef'; 
% La variable `directorioEntrada` se define como la ruta del directorio que contiene los archivos `.mat` de entrada.

% Listar todos los archivos .mat en el directorio
archivosMat = dir(fullfile(directorioEntrada, '*.mat')); 
% La función `dir` se utiliza para obtener una lista de todos los archivos con extensión `.mat` en el directorio especificado. `fullfile` garantiza que la ruta sea correctamente formada para el sistema operativo en uso.

% Recorrer cada archivo .mat
for k = 1:length(archivosMat) 
% El bucle `for` se utiliza para iterar sobre cada archivo `.mat` encontrado en el directorio. La variable `k` actúa como índice del archivo actual en la lista `archivosMat`.

    % Nombre completo del archivo
    nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name); 
    % `fullfile` se utiliza para construir la ruta completa al archivo actual combinando el directorio y el nombre del archivo almacenado en `archivosMat(k).name`.
    

    % Cargar datos
    load(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo'); 

    % DECLARACIÓN DE VARIABLES ASOCIADAS A LA CAPTURA DE LOS DATOS DEL PIN "ADC" DEL MICROCONTROLADOR ESP32
    % variablesMuestreo.frecuenciaMuestreo = 1200;
    % variablesMuestreo.tiempoTotal = 160;
    % %variablesMuestreo.tiempoTotal = 53;
    % variablesMuestreo.tiempoMuestreo = (1/variablesMuestreo.frecuenciaMuestreo);  % Retardo en segundos
    % % muestras = 40000;  % Cantidad de muestras a capturar
    % variablesMuestreo.numeroMuestras = round(variablesMuestreo.tiempoTotal / variablesMuestreo.tiempoMuestreo);
    % variablesMuestreo.ventana_grafico = 80;  % Muestras que se graficarán en pantalla
    % variablesMuestreo.ventana_muestras_totales = 30000; % No. de muestras totales que se graficarán en pantalla (Cada 25 segundos)
    % %variablesMuestreo.ventana_muestras_totales = 30000 / 5; % No. de muestras totales que se graficarán en pantalla (Cada 5 segundos)
    % variablesMuestreo.periodoActualizacionVentana = variablesMuestreo.ventana_muestras_totales * variablesMuestreo.tiempoMuestreo;

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

    % Crear una subcarpeta con el nombre del archivo (sin extensión)
    ruta_subcarpeta = fullfile(ruta_carpetas, nombreArchivo); 
    % Se construye una nueva ruta, `ruta_subcarpeta`, que incluye el nombre del archivo (sin extensión) como subcarpeta dentro de `ruta_carpetas`.

    % Crear la subcarpeta si no existe
    if ~exist(ruta_subcarpeta, 'dir') 
        mkdir(ruta_subcarpeta); 
    end
    % Similar al paso anterior, si la subcarpeta `ruta_subcarpeta` no existe, se crea usando `mkdir`.

    % Guardar los datos en la subcarpeta correspondiente
    ruta_guardado = fullfile(ruta_subcarpeta, [nombreArchivo, '.mat']); 
    % `ruta_guardado` es la ruta completa para guardar el archivo `.mat`, combinando `ruta_subcarpeta` con el nombre del archivo original y la extensión `.mat`.

    % Guardar los datos en el archivo .mat
    save(ruta_guardado, 'capturaDatos', 'variablesMuestreo'); 
    % La función `save` guarda las variables `capturaDatos` y `variablesMuestreo` en un archivo `.mat` en la ruta especificada por `ruta_guardado`.

    % Confirmación
    disp(['Datos guardados en: ', ruta_guardado]); 
    % La función `disp` imprime un mensaje en la consola que indica que los datos se han guardado correctamente en la ubicación especificada.

end
