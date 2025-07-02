
% ------------------------------------------------------------
% Nombre del archivo  :   step01_Visualizar_DatosProcesados_y_AnalisisFourier.m
% Descripción         :   Graficar cada uno de los procesamientos
%                         realizados como espectros de frecuencias positivas (resultados del 
%                         Análisis de Fourier) de las señales sEMG adquiridas
%                         con Filtro Feed Forward Comb (FFC) con Envolvente
%                         Lineal de dos canales analógicos (Extensor Común de los Dedos y 
%                         Flexor Superficial de los Dedos) mediante comunicación serial
%                         procesadas con filtro FFC desde
%                         el microcontrolador ESP32 
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Octubre/2024
% Última modificación :   Junio/2025
% Versión             :   1.1
% ------------------------------------------------------------



%% VISUALIZACIÓN DE DATOS PROCESADOS Y ANÁLISIS DE FOURIER DE LAS SEÑALES sEMG ADQUIRIDAS

clear; % Limpiar las variables almacenadas en el espacio de trabajo
clc; % Limpiar la ventana de comandos
close all; % Cerrar todas las ventanas gráficas

% Directorio donde se encuentran los archivos .mat
directorioEntrada = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef';
% Directorio donde se guardarán los gráficos
directorioSalida = '../Plots_sEMGsignals/graficos';

% Crear la carpeta principal de gráficos si no existe
if ~exist(directorioSalida, 'dir')
    mkdir(directorioSalida);
end

% Listar todos los archivos .mat en el directorio
archivosMat = dir(fullfile(directorioEntrada, '*.mat'));

% Recorrer cada archivo .mat
for k = 1:length(archivosMat)
    % Nombre completo del archivo
    nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name);
    disp(nombreCompletoArchivo);
    
    % Crear una carpeta para almacenar los gráficos del archivo actual
    [~, nombreArchivo, ~] = fileparts(archivosMat(k).name);
    carpetaSalida = fullfile(directorioSalida, nombreArchivo);
    if ~exist(carpetaSalida, 'dir')
        mkdir(carpetaSalida);
    end
    
    % Cargar datos
    load(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo');
    
    % EXTRACCIÓN DE VARIABLES DE MUESTREO
    muestras = variablesMuestreo.numeroMuestras;
    ventana_grafico = variablesMuestreo.ventana_grafico;
    ventana_muestras_totales = variablesMuestreo.ventana_muestras_totales;
    tiempo = linspace(0, muestras * variablesMuestreo.tiempoMuestreo, muestras);  % Escala de tiempo ajustada según el retardo
    
    % Impresión de las variables asociadas a la captura de datos
    fprintf('----Adquisición de señal sEMG(t) del antebrazo mediante el PIN ADC de la ESP32--- \n')
    fprintf('Tiempo de total de captura: %.3f segundos\n', variablesMuestreo.tiempoTotal);
    fprintf('Tiempo de actualización de ventana: %.3f segundos\n', variablesMuestreo.periodoActualizacionVentana);
    fprintf('Frecuencia de muestreo: %.3f [KHz] \n', variablesMuestreo.frecuenciaMuestreo / 1000);
    fprintf('Tiempo de muestreo: %.3e segundos \n', variablesMuestreo.tiempoMuestreo);
    fprintf('Número de muestras adquiridas: %8i \n', variablesMuestreo.numeroMuestras);
    
    % Declaración de paletas de colores
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

    % Declaración del tamaño de las dimensiones de las gráficas
    dimensionGrafico = 2;
    width = 600 * dimensionGrafico;
    height = 420 * dimensionGrafico;
    
    % Gráfico de la señal sEMG normalizada
    fig1 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    title('Lecturas del señales sEMG_{nom} adquiridas desde la ESP32 (sEMG Normalizadas)');
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    grid on;
    plot(capturaDatos.tiempo, capturaDatos.sEMGraw_nom, 'Color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 2.0);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_ESP32, 'Color', color.PaletaColores.Tropical.Azul, 'LineWidth', 1.0)
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32, 'Color', color.PaletaColores.Earth.Negro2, 'LineWidth', 1.5);
    legend('sEMG_{NOM} (Normalizada) (ESP32)', ...
        'sEMG_{NOM-FFC} (Feed Forward Comb (FFC)) (ESP32))', ...
        'sEMG_{FFC}-LE (Feed Forward Comb (FFC))(ESP32)');
    % Guardar la figura
    saveas(fig1, fullfile(carpetaSalida, 'Grafico1.png'));

    fig2 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    title('sEMG (Normalizada), sEMG (Normalizada y Wavelet Denoising), sEMG (Feed Forward Comb)');
    plot(capturaDatos.tiempo, capturaDatos.sEMGraw_nom, 'Color', color.PaletaColores.Earth.Verde, 'LineWidth', 5.0);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'color', color.PaletaColores.FreshSummer.Naranja, 'LineWidth', 4.5);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC, 'color', color.PaletaColores.DarkFall.Marron2, 'LineWidth', 2.0);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC_ESP32, 'Color', color.PaletaColores.DarkFall.Verde1, 'LineWidth', 1.8);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_IIR, 'color', color.PaletaColores.Earth.Negro2, 'LineWidth', 1.0);
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    legend('sEMG (normalizada)', 'sEMG_{NOM-WD} (Normalizada y con "Wavelet Denoising" "db6" nivel "4")', ...
        'sEMG_{NOM-WD-FFC} (Normalizada, "Wavelet Denoising" "db6" nivel "4", Filtro Feed Forward Comb (FFC))', ...
        'sEMG_{NOM-WD-FFC} (Normalizada, "Wavelet Denoising" "db6" nivel "4", Filtro Feed Forward Comb (FFC)) (ESP32)', ...
        'sEMG_{NOM-WD-IIR} (Normalizada, "Wavelet Denoising" "db6" nivel "4", Infinite Impulse Response (IIR))');
    grid on;
    % Guardar la figura
    saveas(fig2, fullfile(carpetaSalida, 'Grafico2.png'));

    fig3 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    title('sEMG (Normalizada y Wavelet Denoising): Filtro Feed Forward Comb (FFC)');
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'color', color.PaletaColores.FreshSummer.Naranja, 'LineWidth', 4.5);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC, 'color', color.PaletaColores.DarkFall.Marron2, 'LineWidth', 2.0);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC_ESP32, 'Color', color.PaletaColores.DarkFall.Verde1, 'LineWidth', 1.8);
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    legend('sEMG_{NOM-WD} (Normalizada y con "Wavelet Denoising" "db6" nivel "4")', ...
        'sEMG_{NOM-WD-FFC} (Normalizada, "Wavelet Denoising" "db6" nivel "4", Filtro Feed Forward Comb (FFC))', ...
        'sEMG_{NOM-WD-FFC} (Normalizada, "Wavelet Denoising" "db6" nivel "4", Filtro Feed Forward Comb (FFC)) (ESP32)');
    grid on;
    % Guardar la figura
    saveas(fig3, fullfile(carpetaSalida, 'Grafico3.png'));


    fig4 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    title('sEMG (Normalizada y Wavelet Denoising): Filtro Infinite Impulse Response (IIR)');
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'color', color.PaletaColores.FreshSummer.Naranja, 'LineWidth', 4.5);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_IIR, 'color', color.PaletaColores.Earth.Negro2, 'LineWidth', 1.0);
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    legend('sEMG_{NOM-WD} (Normalizada y con "Wavelet Denoising" "db6" nivel "4")', ...
        'sEMG_{NOM-WD-IIR} (Normalizada, "Wavelet Denoising" "db6" nivel "4", Infinite Impulse Response (IIR))');
    grid on;
    % Guardar la figura
    saveas(fig4, fullfile(carpetaSalida, 'Grafico4.png'));
    
    % GRAFICAR ENVOLVENTES
    fig5 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'Color', color.PaletaColores.Earth.Negro1, 'LineWidth', 0.5);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenoising_envelopeHilbert, 'Color', color.PaletaColores.FreshSummer.Naranja, 'LineWidth', 2.5);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal, 'Color', color.PaletaColores.Tropical.Verde1, 'LineWidth', 1.2);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32, 'color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 1.4);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC_envelopeLineal, 'Color', color.PaletaColores.Spring.Azul1, 'LineWidth', 1.6);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_IIR_envelopeLineal, 'Color', color.PaletaColores.Spring.Azul2, 'LineWidth', 1.4);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_IIR_envelopeLineal, 'Color', color.PaletaColores.Tropical.Rosa, 'LineWidth', 1.6);
    title('Señal sEMG (Normalizada y con Wavelet Denoising) y envolvente de Hilbert y Lineal');
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    legend('sEMG_{NOM-WD} (Normalizada, "Wavelet Denoising" "db6" nivel "4")', 'sEMG-HE (Hilbert Envelope)', ...
        'sEMG_{NOM-WD-FFC}-LE (Feed Forward Comb (FFC) (Linear Envelope))', 'sEMG_{NOM-FFC}-LE con Feed Forward Comb (FFC) (Linear Envelope) (ESP32)', ...
        'sEMG_{NOM-WD-FFC}-LE (Feed Forward Comb (FFC), Wavelet Denoising (Linear Envelope))', ...
        'sEMG_{NOM-IIR}-LE (Infinite Impulse Response (IIR) (Linear Envelope))', ...
        'sEMG_{NOM-WD-IIR}-LE (Infinite Impulse Response (IIR), Wavelet Denoising (Linear Envelope))');
    grid on;
    % Guardar la figura
    saveas(fig5, fullfile(carpetaSalida, 'Grafico5.png'));

    fig6 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'Color', color.PaletaColores.Earth.Negro1, 'LineWidth', 0.5);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal, 'Color', color.PaletaColores.Tropical.Verde1, 'LineWidth', 1.2);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_FFC_envelopeLineal_ESP32, 'color', color.PaletaColores.Tropical.Verde2, 'LineWidth', 1.6);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_FFC_envelopeLineal, 'Color', color.PaletaColores.Spring.Azul1, 'LineWidth', 1.4);
    title('Señal sEMG (Normalizada y con Wavelet Denoising) y envolvente de tipo Lineal');
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    legend('sEMG_{NOM-WD} (Normalizada, "Wavelet Denoising" "db6" nivel "4")', ...
        'sEMG_{NOM-FFC}-LE (Feed Forward Comb (FFC) (Linear Envelope))', 'sEMG_{NOM-FFC}-LE (Feed Forward Comb (FFC) (Linear Envelope)) (ESP32)', ...
        'sEMG_{NOM-WD-FFC}-LE (Feed Forward Comb (FFC), Wavelet Denoising (Linear Envelope))')
    grid on;
    % Guardar la figura
    saveas(fig6, fullfile(carpetaSalida, 'Grafico6.png'));

    fig7 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_waveletDenosing, 'Color', color.PaletaColores.Earth.Negro1, 'LineWidth', 0.5);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_IIR_envelopeLineal, 'Color', color.PaletaColores.Spring.Azul2, 'LineWidth', 1.8);
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nom_WD_IIR_envelopeLineal, 'Color', color.PaletaColores.Tropical.Rosa, 'LineWidth', 1.6);
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    title('Señal sEMG (Normalizada, "Wavelet Denoising" "db6" nivel "4", Filtro Infinite Impulse Response (IIR))');
    legend('sEMG_{NOM-WD} (Normalizada, "Wavelet Denoising" "db6" nivel "4")', ...
        'sEMG_{NOM-IIR}-LE con Infinite Impulse Response (IIR) (Linear Envelope)', ...
        'sEMG_{NOM-WD-IIR}-LE con Infinite Impulse Response (IIR) y Wavelet Denoising (Linear Envelope)');
    grid on;
    % Guardar la figura
    saveas(fig7, fullfile(carpetaSalida, 'Grafico7.png'));

    fig8 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    plot(capturaDatos.analisisFourier.DFT_sEMGraw_nom.f, capturaDatos.analisisFourier.DFT_sEMGraw_nom.DFT, 'color', color.PaletaColores.Earth.Negro2, "LineWidth", 3.5);
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD.DFT, 'color', color.PaletaColores.Spring.Azul1, "LineWidth", 3.0); 
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC.DFT, 'color', color.PaletaColores.Tropical.Verde2, "LineWidth", 2.5); 
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_ESP32.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_ESP32.DFT, 'color', color.PaletaColores.Tropical.Verde1, "LineWidth", 2.0); 
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD_IIR.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD_IIR.DFT, 'color', color.PaletaColores.FreshSummer.Verde2, "LineWidth", 1.5); 
    title("Single-Sided Amplitude Spectrum of sEMG(t)");
    xlabel("f (Hz)");
    ylabel("|P1(f)|");
    legend('FFT sEMGraw normalizada', '(FFT sEMG Normalizada y con "Wavelet Denoising" "db6" nivel "4")',...
        'FFT sEMG normalizada con "Wavelet Denoising" "db6" nivel "4" y Feed Forward Comb (FFC)',...
        'FFT sEMG normalizada con "Wavelet Denoising" "db6" nivel "4" y Feed Forward Comb (FFC) (ESP32)',...
        'FFT sEMG normalizada con "Wavelet Denoising" "db6" nivel "4" e Infinite Impulse Response (IIR)')
    grid on;
    % Guardar la figura
    saveas(fig8, fullfile(carpetaSalida, 'Grafico8.png'));
 
    fig9 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD.DFT, 'color', color.PaletaColores.Spring.Azul1, "LineWidth", 3.0); 
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC.DFT, 'color', color.PaletaColores.Tropical.Verde2, "LineWidth", 2.5); 
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_ESP32.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_ESP32.DFT, 'color', color.PaletaColores.DarkFall.Verde1, "LineWidth", 2.0); 
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD_IIR.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD_IIR.DFT, 'color', color.PaletaColores.FreshSummer.Verde2, "LineWidth", 1.5); 
    title("Single-Sided Amplitude Spectrum of sEMG(t)");
    xlabel("f (Hz)");
    ylabel("|P1(f)|");
    legend('FFT sEMG Normalizada y con "Wavelet Denoising" "db6" nivel "4")',...
        'FFT sEMG normalizada con "Wavelet Denoising" "db6" nivel "4" y Feed Forward Comb (FFC)',...
        'FFT sEMG normalizada con "Wavelet Denoising" "db6" nivel "4" y Feed Forward Comb (FFC) (ESP32)',...
        'FFT sEMG normalizada con "Wavelet Denoising" "db6" nivel "4" e Infinite Impulse Response (IIR)')
    grid on;
    % Guardar la figura
    saveas(fig9, fullfile(carpetaSalida, 'Grafico9.png'));
    
    fig10 = figure('Visible', 'off', 'Position', [0, 0, width, height]);    
    hold on;
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD.DFT, 'color', color.PaletaColores.Spring.Azul1, "LineWidth", 3.0); 
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC.DFT, 'color', color.PaletaColores.Tropical.Verde2, "LineWidth", 2.5); 
    plot(capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_ESP32.f, capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_ESP32.DFT, 'color', color.PaletaColores.DarkFall.Verde1, "LineWidth", 2.0); 
    title("Single-Sided Amplitude Spectrum of sEMG(t)");
    xlabel("f (Hz)");
    ylabel("|P1(f)|");
    legend('(FFT sEMG Normalizada y con "Wavelet Denoising" "db6" nivel "4")',...
        'FFT sEMG normalizada con "Wavelet Denoising" "db6" nivel "4" y Feed Forward Comb (FFC)',...
        'FFT sEMG normalizada con "Wavelet Denoising" "db6" nivel "4" y Feed Forward Comb (FFC) (ESP32)');
    grid on;
    % Guardar la figura
    saveas(fig10, fullfile(carpetaSalida, 'Grafico10.png'));


    % Gráfico de la señal sEMG normalizada
    fig11 = figure('Visible', 'off', 'Position', [0, 0, width, height]);
    hold on;
    title('Lecturas de la señal sEMG-FFC-LE_{NOM-MINMAX-FOR-SUBJECT} adquiridas desde la ESP32 (sEMG Normalizadas)');
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    grid on;
    plot(capturaDatos.tiempo, capturaDatos.sEMG_nomMinMaxForSubject_FFC_LE_ESP32, 'Color', color.PaletaColores.Earth.Negro2, 'LineWidth', 2.0)
    legend('sEMG_{NOM-MINMAX-FOR-SUBJECT} (Normalización MinMax por valor_{max} del sujeto) (ESP32)')
    % Guardar la figura
    saveas(fig11, fullfile(carpetaSalida, 'Grafico11.png'));
    % Cerrar todas las figuras abiertas
    close all;

end