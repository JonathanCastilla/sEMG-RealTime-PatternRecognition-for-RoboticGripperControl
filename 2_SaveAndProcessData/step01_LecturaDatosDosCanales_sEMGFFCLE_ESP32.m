
% ------------------------------------------------------------
% Nombre del archivo  :   step01_LecturaDatosDosCanales_sEMGFFCLE_ESP32.m
% Descripción         :   Adquisición y almacenamiento de señales sEMG
%                         de dos canales analógicos (Extensor Común de los Dedos y 
%                         Flexor Superficial de los Dedos) mediante comunicación serial
%                         procesadas con filtro FFC desde
%                         el microcontrolador ESP32
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Septiembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.9
% ------------------------------------------------------------


% ADQUISICIÓN DE SEÑALES sEMG DEL ANTEBRAZO MEDIANTE COMUNICACIÓN SERIAL POR MICROCONTROLADOR ESP32:
% Filtros Digitales: Feed Forward Comb (FFC) y Envolvente Lineal procesado en línea en microcontrolador ESP32


% LIMPIEZA DEL ESPACIO DE TRABAJO, VENTANA DE COMANDOS Y CIERRE DE VENTANAS GRÁFICAS
clear all; % Limpiar las variables almacenadas en el espacio de trabajo
clc; % Limpiar la ventana de comandos
close all; % Cerrar todas las ventanas gráficas

% ADC1: EDC, ADC2: FDS
nombre_sEMG_datos_ADC1_EDC = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef/datos_sEMG_MAD_EDC_TFF_P22_M3sec.mat';
nombre_sEMG_datos_ADC2_FDS = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef/datos_sEMG_MAD_FDS_TFF_P22_M3sec.mat';

% CONFIGURAR LA CONEXIÓN SERIAL
puerto = 'COM3';  % Asignación del puerto de lectura 'COM4' para la lectura del microcontrolador ESP32
tasaBaudios = 115200;  % Definición de la tasa de Baudios (Velocidad de transmisión de datos)
s = serialport(puerto, tasaBaudios); % Asignación del puerto serial con la velocidad de transmisión de datos

% DEFINICIÓN DEL TAMAÑO DE ENTRADA DEL BUFFER
s.InputBufferSize = 4096;  % Tamaño del buffer ajustado

% LIMPIEZA DEL BUFFER DE ENTRADA PREVIO A LA CONEXIÓN DEL PUERTO SERIAL ASIGNADO
flush(s);

% DESCARTAR PRIMERAS LECTURAS AL INICIALIZAR LA LECTURA DEL PUERTO SERIAL ASIGNADO
lecturas_descartadas = 3000;  % Número de lecturas (muestras) descartadas
for i = 1:lecturas_descartadas
    while s.NumBytesAvailable == 0
        pause(0.001);  % Esperar a que haya datos disponibles
    end
    readline(s);  % Leer y descartar las primeras lecturas
end

% CONFIGURACIÓN INICIAL DE LA VENTANA GRÁFICA DE LA LECTURA DE LOS PINS "ADC" DEL ESP32
figure(1);
%subplot(2,1,1);
hold on;
title('Lectura de señal sEMG(t) a través del Pin ADC1 de la ESP32');
xlabel('Tiempo (s)');
ylabel('Amplitud (mV)');
grid on;

% subplot(2,1,2);
% hold on;
% title('Lectura de señal sEMG(t) a través del Pin ADC2 de la ESP32');
% xlabel('Tiempo (s)');
% ylabel('Amplitud (mV)');
% grid on;

% DECLARACIÓN DE VARIABLES ASOCIADAS A LA CAPTURA DE LOS DATOS DEL PIN "ADC" DEL MICROCONTROLADOR ESP32
ADCpin1.variablesMuestreo.frecuenciaMuestreo = 1200;
ADCpin1.variablesMuestreo.tiempoTotal = 53;
ADCpin1.variablesMuestreo.tiempoMuestreo = (1/ADCpin1.variablesMuestreo.frecuenciaMuestreo);  % Retardo en segundos
ADCpin1.variablesMuestreo.numeroMuestras = round(ADCpin1.variablesMuestreo.tiempoTotal / ADCpin1.variablesMuestreo.tiempoMuestreo);
ADCpin1.variablesMuestreo.ventana_grafico = 120;  % Muestras que se graficarán en pantalla
ADCpin1.variablesMuestreo.tiempoVentanaMuestrasTotales = 10;
ADCpin1.variablesMuestreo.ventana_muestras_totales = ADCpin1.variablesMuestreo.frecuenciaMuestreo * ADCpin1.variablesMuestreo.tiempoVentanaMuestrasTotales; % No. de muestras totales que se graficarán en pantalla (Cada 25 segundos)
ADCpin1.variablesMuestreo.periodoActualizacionVentana = ADCpin1.variablesMuestreo.ventana_muestras_totales * ADCpin1.variablesMuestreo.tiempoMuestreo;

% Copiar variables de ADCpin1 a ADCpin2
ADCpin2.variablesMuestreo = ADCpin1.variablesMuestreo;

% EXTRACCIÓN DE VARIABLES DE MUESTREO
muestras = ADCpin1.variablesMuestreo.numeroMuestras;
ventana_grafico = ADCpin1.variablesMuestreo.ventana_grafico;
ventana_muestras_totales = ADCpin1.variablesMuestreo.ventana_muestras_totales;
tiempo = linspace(0, muestras * ADCpin1.variablesMuestreo.tiempoMuestreo, muestras);  % Escala de tiempo ajustada según el retardo

% Impresión de las varibles asociadas a la captura de datos
fprintf('----Adquisición de señal sEMG(t) del antebrazo mediante el PIN ADC de la ESP32--- \n')
fprintf('Tiempo de total de captura: %.3f segundos\n', ADCpin1.variablesMuestreo.tiempoTotal);
fprintf('Tiempo de actualización de ventana: %.3f segundos\n', ADCpin1.variablesMuestreo.periodoActualizacionVentana);
fprintf('Frecuencia de muestreo: %.3f [KHz] \n', ADCpin1.variablesMuestreo.frecuenciaMuestreo / 1000);
fprintf('Tiempo de muestreo: %.3e segundos \n', ADCpin1.variablesMuestreo.tiempoMuestreo);
fprintf('Número de muestras adquiridas: %8i \n', ADCpin1.variablesMuestreo.numeroMuestras);


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



% DECLARACIÓN DE ESTRUCTURAS PARA GUARDAR LOS DATOS ADQUIRIDOS DE LA SEÑAL sEMG
ADCpin1.capturaDatos.tiempo = tiempo;
ADCpin2.capturaDatos.tiempo = tiempo;
ADCpin1.capturaDatos.sEMGraw = zeros(1, muestras);
ADCpin2.capturaDatos.sEMGraw = zeros(1, muestras);
% ADCpin1.capturaDatos.sEMGraw_rectificada = zeros(1, muestras);
% ADCpin2.capturaDatos.sEMGraw_rectificada = zeros(1, muestras);
ADCpin1.capturaDatos.sEMGraw_nom = zeros(1, muestras);
ADCpin2.capturaDatos.sEMGraw_nom = zeros(1, muestras);
ADCpin1.capturaDatos.sEMG_nom_FFC = zeros(1, muestras);
ADCpin2.capturaDatos.sEMG_nom_FFC = zeros(1, muestras);
ADCpin1.capturaDatos.sEMG_FFC_ESP32 = zeros(1, muestras);
ADCpin2.capturaDatos.sEMG_FFC_ESP32 = zeros(1, muestras);
ADCpin1.capturaDatos.sEMG_FFC_envelopeLineal_ESP32 = zeros(1, muestras); % Vector para almacenar el nivel EMG-LE
ADCpin2.capturaDatos.sEMG_FFC_envelopeLineal_ESP32 = zeros(1, muestras);
ADCpin1.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = zeros(1, muestras); % Vector para almacenar el nivel EMG-LE
ADCpin2.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = zeros(1, muestras);

ADCpin1.capturaDatos.sEMG_nom_waveletDenosing = zeros(1, muestras);
ADCpin2.capturaDatos.sEMG_nom_waveletDenosing = zeros(1, muestras);
ADCpin1.capturaDatos.sEMG_nom_waveletDenosing_envelopeHilbert = zeros(1, muestras);
ADCpin2.capturaDatos.sEMG_nom_waveletDenosing_envelopeHilbert = zeros(1, muestras);

ADCpin1.capturaDatos.sEMG_nom_WD_FFC = zeros(1, muestras);
ADCpin2.capturaDatos.sEMG_nom_WD_FFC = zeros(1, muestras);

ADCpin1.capturaDatos.sEMG_nom_WD_FFC_ESP32 = zeros(1, muestras);
ADCpin2.capturaDatos.sEMG_nom_WD_FFC_ESP32 = zeros(1, muestras);

ADCpin1.capturaDatos.sEMG_nom_WD_FFC_envelopeLineal = zeros(1, muestras); % Vector para almacenar el nivel EMG-LE
ADCpin2.capturaDatos.sEMG_nom_WD_FFC_envelopeLineal = zeros(1, muestras);

sEMG_FFC_LE_ADC1 = zeros(1, muestras);
sEMG_FFC_LE_ADC2 = zeros(1, muestras);
sEMG_FFC_ESP32_ADC1 = zeros(1, muestras);
sEMG_FFC_ESP32_ADC2 = zeros(1, muestras);

% LECTURA DE DATOS Y GRAFICACIÓN EN TIEMPO REAL
for i = 1:muestras
    % Esperar a que haya datos disponibles
    %while s.NumBytesAvailable == 0
    %    pause(0.001);  % Pausa para esperar los datos
    %end

    % Leer dato del ESP32 (Seis datos)
    datoCrudo = readline(s);

    % Convertir la cadena de seis números en seis valores flotantes
    valor = str2double(strsplit(datoCrudo));
    %  == 7 (todos)
    if numel(valor) == 7 && all(~isnan(valor(1:6)))
        % ADC1
        ADCpin1.capturaDatos.sEMGraw(i) = valor(1);  % Guardar el dato en la estructura
        %ADCpin1.capturaDatos.sEMG_FFC_ESP32(i) = valor(2);  % Guardar el valor del filtro Feed Forward Comb en la estructura
        ADCpin1.capturaDatos.sEMG_FFC_ESP32(i) = valor(2);  % Guardar el valor del filtro Feed Forward Comb en la estructura
        ADCpin1.capturaDatos.sEMG_FFC_envelopeLineal_ESP32(i) = valor(3); % Envelope de la señal EMG-LE para el ADC1

        % ADC2
        ADCpin2.capturaDatos.sEMGraw(i) = valor(4);  % Guardar el dato en la estructura
        %ADCpin2.capturaDatos.sEMG_FFC_ESP32(i) = valor(5);  % Guardar el valor del filtro Feed Forward Comb en la estructura
        ADCpin2.capturaDatos.sEMG_FFC_ESP32(i) = valor(5);  % Guardar el valor del filtro Feed Forward Comb en la estructura
        ADCpin2.capturaDatos.sEMG_FFC_envelopeLineal_ESP32(i) = valor(6); % Envelope de la señal EMG-LE para el ADC2

    else
        %ADCpin1.capturaDatos.sEMGraw(i) = 0;  % Si el valor es inválido, guardar cero
        ADCpin1.capturaDatos.sEMG_FFC_ESP32(i) = 0;  % Si el valor es inválido, guardar cero
        %sEMG_FFC_LE_ADC1(i) = 0;  % Si el valor es inválido, guardar cero

        %ADCpin2.capturaDatos.sEMGraw(i) = 0;  % Si el valor es inválido, guardar cero
        ADCpin2.capturaDatos.sEMG_FFC_ESP32(i) = 0;  % Si el valor es inválido, guardar cero
        %sEMG_FFC_LE_ADC2(i) = 0;  % Si el valor es inválido, guardar cero
    end


    % Solo redibujar cada 'ventana_grafico' muestras para evitar ralentización
    if mod(i, ventana_grafico) == 0 || i == muestras
        if i <= ventana_grafico
            % Graficar todos los datos si hay menos que la ventana de gráfico      
            hold on;
            %subplot(2,1,1);
            %plot(tiempo(1:i), ADCpin1.capturaDatos.sEMGraw(1:i), 'Color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 0.5);
            %plot(tiempo(1:i), sEMG_FFC_LE_ADC1(1:i), 'Color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 0.5);
            plot(tiempo(1:i), ADCpin1.capturaDatos.sEMG_FFC_ESP32(1:i), 'g');
            %plot(tiempo(1:i), sEMG_FFC_LE_ADC1(1:i), 'g');
            %ylim([0 800]);
            %legend('sEMGraw');
            %subplot(2,1,2);
            % plot(tiempo(1:i), ADCpin2.capturaDatos.sEMGraw(1:i), 'Color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 0.5);
            %plot(tiempo(1:i), sEMG_FFC_LE_ADC2(1:i), 'Color', color.PaletaColores.Tropical.Amarillo, 'LineWidth', 0.5);
            %ylim([0 600]);
            plot(tiempo(1:i), ADCpin2.capturaDatos.sEMG_FFC_ESP32(1:i), 'b');
            % plot(tiempo(1:i), sEMG_FFC_LE_ADC1(1:i), 'g');
            legend('sEMGraw');

        else
            % Graficar solo las últimas 'ventana_grafico' muestras
            hold on;
            %subplot(2,1,1);
            % plot(tiempo(i-ventana_grafico+1:i), sEMG_FFC_LE_ADC1(i-ventana_grafico+1:i), 'Color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 0.5);
            plot(tiempo(i-ventana_grafico+1:i), ADCpin1.capturaDatos.sEMG_FFC_ESP32(i-ventana_grafico+1:i), 'Color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 0.5);
            %ylim([0 800]);
            %subplot(2,1,2);
            %plot(tiempo(i-ventana_grafico+1:i), sEMG_FFC_LE_ADC2(i-ventana_grafico+1:i), 'Color', color.PaletaColores.Tropical.Amarillo, 'LineWidth', 0.5);
            plot(tiempo(i-ventana_grafico+1:i), ADCpin2.capturaDatos.sEMG_FFC_ESP32(i-ventana_grafico+1:i), 'Color', color.PaletaColores.Tropical.Amarillo, 'LineWidth', 0.5);
            %ylim([0 800]);
            %plot(tiempo(1:i), ADCpin2.capturaDatos.sEMG_FFC_ESP32(1:i), 'r');
            %plot(tiempo(1:i), sEMG_FFC_LE_ADC2(1:i), 'g');
            legend('sEMGraw');

            if mod(i, ventana_muestras_totales) == 0
                %subplot(2,1,1);
                cla; % Limpiar gráfica antes de actualizar
                %subplot(2,1,2);
                %cla;
            end
        end
        drawnow;  % Refrescar gráfico
    end
end

% CIERRE DE LA CONEXIÓN SERIAL DEL PUERTO ASIGNADO
clear s;

% PROCESAMIENTO Y NORMALIZACIÓN DE LAS SEÑALES sEMG

% ADC1
% 1. Rectificación completa de la señal
ADCpin1.capturaDatos.sEMGraw_rectificada = abs(ADCpin1.capturaDatos.sEMGraw);
%sEMG_FFC_LE_ADC1_rectificada = abs(sEMG_FFC_LE_ADC1);

% 2. Normalización de la señal
% ADCpin1.capturaDatos.sEMGraw_nom = ADCpin1.capturaDatos.sEMGraw_rectificada / max(ADCpin1.capturaDatos.sEMGraw_rectificada);
% ADCpin1.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = sEMG_FFC_LE_ADC1_rectificada / max(sEMG_FFC_LE_ADC1_rectificada);

% 3. NORMALIZACIÓN DE LA SEÑAL MEDIANTE STANDARD SCALER (CENTRALIZADA EN
% CERO)
ADCpin1.capturaDatos.sEMGraw_nom = (ADCpin1.capturaDatos.sEMGraw - mean(ADCpin1.capturaDatos.sEMGraw)) / std(ADCpin1.capturaDatos.sEMGraw);
ADCpin1.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = (ADCpin1.capturaDatos.sEMG_FFC_envelopeLineal_ESP32 - mean(ADCpin1.capturaDatos.sEMG_FFC_envelopeLineal_ESP32)) / std(ADCpin1.capturaDatos.sEMG_FFC_envelopeLineal_ESP32); 
%ADCpin1.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = ADCpin1.capturaDatos.sEMG_FFC_ESP32 - min(ADCpin1.capturaDatos.sEMG_FFC_ESP32);

% ADC2
% 1. Rectificación completa de la señal
ADCpin2.capturaDatos.sEMGraw_rectificada = abs(ADCpin2.capturaDatos.sEMGraw);
% sEMG_FFC_LE_ADC2_rectificada = abs(sEMG_FFC_LE_ADC2);

% 2. Normalización de la señal
%ADCpin2.capturaDatos.sEMGraw_nom = ADCpin2.capturaDatos.sEMGraw_rectificada / max(ADCpin2.capturaDatos.sEMGraw_rectificada);
% ADCpin2.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = sEMG_FFC_LE_ADC2_rectificada / max(sEMG_FFC_LE_ADC2_rectificada);

% 3. Señal centralizada en cero (Eliminación de la componente "DC")
ADCpin2.capturaDatos.sEMGraw_nom = (ADCpin2.capturaDatos.sEMGraw_nom - mean(ADCpin2.capturaDatos.sEMGraw_nom)) / std(ADCpin2.capturaDatos.sEMGraw_nom);
ADCpin2.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = (ADCpin2.capturaDatos.sEMG_FFC_envelopeLineal_ESP32 - mean(ADCpin2.capturaDatos.sEMG_FFC_envelopeLineal_ESP32)) / std(ADCpin2.capturaDatos.sEMG_FFC_envelopeLineal_ESP32); 
% ADCpin2.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 = ADCpin2.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32 - min(ADCpin2.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32);

% NORMALIZACIÓN DE LA SEÑAL sEMG con el Filtro Feed Forward Comb mediante
% STANDARD-SCALER
% ADC1
ADCpin1.capturaDatos.sEMG_nom_FFC_ESP32 = ADCpin1.capturaDatos.sEMG_FFC_ESP32 / max(ADCpin1.capturaDatos.sEMG_FFC_ESP32);
ADCpin1.capturaDatos.sEMG_nom_FFC_ESP32 = (ADCpin1.capturaDatos.sEMG_nom_FFC_ESP32 - mean(ADCpin1.capturaDatos.sEMG_nom_FFC_ESP32)) / std(ADCpin1.capturaDatos.sEMG_nom_FFC_ESP32);

% ADC2
ADCpin2.capturaDatos.sEMG_nom_FFC_ESP32 = ADCpin2.capturaDatos.sEMG_FFC_ESP32 / max(ADCpin2.capturaDatos.sEMG_FFC_ESP32);
ADCpin2.capturaDatos.sEMG_nom_FFC_ESP32 = (ADCpin2.capturaDatos.sEMG_nom_FFC_ESP32 - mean(ADCpin2.capturaDatos.sEMG_nom_FFC_ESP32)) / std(ADCpin2.capturaDatos.sEMG_nom_FFC_ESP32);

% Gráfico de la señal sEMG normalizada para ADC1
figure(2)
subplot(2,1,1);
hold on;
title('Lecturas de señales sEMG_{nom} adquiridas desde la ESP32 (ADC1)');
xlabel('Tiempo (s)');
ylabel('sEMG (Normalizada)');
grid on;
plot(ADCpin1.capturaDatos.tiempo, ADCpin1.capturaDatos.sEMGraw_nom, 'Color', 'g', 'LineWidth', 2.0);
plot(ADCpin1.capturaDatos.tiempo, ADCpin1.capturaDatos.sEMG_nom_FFC_ESP32, 'Color', 'b', 'LineWidth', 1.0)
plot(ADCpin1.capturaDatos.tiempo, ADCpin1.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32, 'Color', 'k', 'LineWidth', 1.5);
legend('sEMG_{NOM} (Normalizada) (ESP32)', ...
    'sEMG_{NOM-FFC} (Feed Forward Comb (FFC)) (ESP32)',...
    'sEMG_{FFC}-LE (Feed Forward Comb (FFC))(ESP32)');

% Gráfico de la señal sEMG normalizada para ADC2
subplot(2,1,2);
hold on;
title('Lecturas de señales sEMG_{nom} adquiridas desde la ESP32 (ADC2)');
xlabel('Tiempo (s)');
ylabel('sEMG (Normalizada)');
grid on;
plot(ADCpin2.capturaDatos.tiempo, ADCpin2.capturaDatos.sEMGraw_nom, 'Color', 'g', 'LineWidth', 2.0);
plot(ADCpin2.capturaDatos.tiempo, ADCpin2.capturaDatos.sEMG_nom_FFC_ESP32, 'Color', 'b', 'LineWidth', 1.0)
plot(ADCpin2.capturaDatos.tiempo, ADCpin2.capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32, 'Color', 'k', 'LineWidth', 1.5);
legend('sEMG_{NOM} (Normalizada) (ESP32)', ...
    'sEMG_{NOM-FFC} (Feed Forward Comb (FFC)) (ESP32)',...
    'sEMG_{FFC}-LE (Feed Forward Comb (FFC))(ESP32)');

% GUARDAR LAS ESTRUCTURAS CON LOS DATOS ADQUIRIDOS EN ARCHIVOS ".MAT"
save(nombre_sEMG_datos_ADC1_EDC, 'ADCpin1');
save(nombre_sEMG_datos_ADC2_FDS, 'ADCpin2');

