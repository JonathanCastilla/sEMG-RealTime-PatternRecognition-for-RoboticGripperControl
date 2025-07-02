
% ------------------------------------------------------------
% Nombre del archivo  :   step04_AnalisisFourier_RecorridoDatos_sEMG.m
% Descripción         :   Análisis de Fourier (Espectro de frecuencias positivas)
%                         general de todas las muestras sEMG adquiridas
%                         de dos canales analógicos (Extensor Común de los Dedos y 
%                         Flexor Superficial de los Dedos) mediante comunicación serial
%                         procesadas con filtro FFC desde
%                         el microcontrolador ESP32.
% Autor               :   Jonathan Eduardo Castilla Zamora
% Github              :   https://github.com/JonathanCastilla/sEMG-RealTime-PatternRecognition-for-GripperControl
% Institución         :   Instituto Politécnico Nacional (IPN)
% Fecha de creación   :   Septiembre/2024
% Última modificación :   Junio/2025
% Versión             :   1.6
% ------------------------------------------------------------


%% ANÁLISIS DE FOURIER

clear; % Limpiar las variables almacenadas en el espacio de trabajo
clc; % Limpiar la ventana de comandos
close all; % Cerrar todas las ventanas gráficas

% Directorio donde se encuentran los archivos .mat
directorioEntrada = '../Data_sEMGsignals/sEMGmuestrasLimpiasDef';
% Listar todos los archivos .mat en el directorio
archivosMat = dir(fullfile(directorioEntrada, '*.mat'));

% Recorrer cada archivo .mat
for k = 1:length(archivosMat)
    % Nombre completo del archivo
    nombreCompletoArchivo = fullfile(directorioEntrada, archivosMat(k).name);
    disp(nombreCompletoArchivo);
    % Cargar datos
    % nombre_sEMG_datos = 'datos_sEMG_MAI_A01_B02_P1';
    % nombre_sEMG_datos = 'datosProtoboard_sEMG_MAD_EDC_CF_P1_M5sec.mat';
    load(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo');
    
    % EXTRACCIÓN DE VARIABLES DE MUESTREO
    frecuenciaMuestreo = variablesMuestreo.frecuenciaMuestreo;
    muestras = variablesMuestreo.numeroMuestras;
    ventana_grafico = variablesMuestreo.ventana_grafico;
    ventana_muestras_totales = variablesMuestreo.ventana_muestras_totales;
    tiempo = linspace(0, muestras * variablesMuestreo.tiempoMuestreo, muestras);  % Escala de tiempo ajustada según el retardo
    
    % Impresión de las varibles asociadas a la captura de datos
    fprintf('----Adquisición de señal sEMG(t) del antebrazo mediante el PIN ADC de la ESP32--- \n')
    fprintf('Tiempo de total de captura: %.3f segundos\n', variablesMuestreo.tiempoTotal);
    fprintf('Tiempo de actualización de ventana: %.3f segundos\n', variablesMuestreo.periodoActualizacionVentana);
    fprintf('Frecuencia de muestreo: %.3f [KHz] \n', variablesMuestreo.frecuenciaMuestreo / 1000);
    fprintf('Tiempo de muestreo: %.3e segundos \n', variablesMuestreo.tiempoMuestreo);
    fprintf('Número de muestras adquiridas: %8i \n', variablesMuestreo.numeroMuestras);

    % Datos para análisis de Fourier
    Fs = variablesMuestreo.frecuenciaMuestreo; % Frecuencia de muestreo
    tiempoTotal = variablesMuestreo.tiempoTotal; % Tiempo total de muestreo
    T = (1/Fs);  % Periodo de muestreo
    % Longitud de la señal adquirida
    L = round(tiempoTotal / T); % No. de muestras

    %% ANÁLISIS DE FOURIER

    [f_DFT_sEMGraw_nom, DFT_sEMGraw_nom] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMGraw_nom);
    [f_DFT_sEMG_nom_WD, DFT_sEMG_nom_WD] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMG_nom_waveletDenosing);
    
    [f_DFT_sEMG_nom_WD_FFC, DFT_sEMG_nom_WD_FFC] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMG_nom_WD_FFC);
    [f_DFT_sEMG_nom_WD_FFC_ESP32, DFT_sEMG_nom_WD_FFC_ESP32] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMG_nom_WD_FFC_ESP32);
    [f_DFT_sEMG_nom_FFC, DFT_sEMG_nom_FFC] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMG_nom_FFC);
    
    [f_DFT_sEMG_nom_WD_IIR, DFT_sEMG_nom_WD_IIR] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMG_nom_WD_IIR);
    [f_DFT_sEMG_nom_IIR, DFT_sEMG_nom_IIR] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMG_nom_IIR);
    
    [f_DFT_sEMG_nom_WD_HE, DFT_sEMG_nom_WD_HE] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMG_nom_waveletDenoising_envelopeHilbert);
    [f_DFT_sEMG_nom_WD_FFC_LE, DFT_sEMG_nom_WD_FFC_LE] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, capturaDatos.sEMG_nom_WD_FFC_envelopeLineal);
    
    % ALMACENAMIENTO DE DATOS DEL ANÁLISIS DE FOURIER
    
    capturaDatos.analisisFourier.DFT_sEMGraw_nom.f = f_DFT_sEMGraw_nom;
    capturaDatos.analisisFourier.DFT_sEMGraw_nom.DFT = DFT_sEMGraw_nom;

    capturaDatos.analisisFourier.DFT_sEMG_nom_WD.f = f_DFT_sEMG_nom_WD;
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD.DFT = DFT_sEMG_nom_WD;
    
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC.f = f_DFT_sEMG_nom_WD_FFC;
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC.DFT = DFT_sEMG_nom_WD_FFC;
    
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_ESP32.f = f_DFT_sEMG_nom_WD_FFC_ESP32;
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_ESP32.DFT = DFT_sEMG_nom_WD_FFC_ESP32;
    
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_IIR.f = f_DFT_sEMG_nom_WD_IIR;
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_IIR.DFT = DFT_sEMG_nom_WD_IIR;
    
    capturaDatos.analisisFourier.DFT_sEMG_nom_IIR.f = f_DFT_sEMG_nom_IIR;
    capturaDatos.analisisFourier.DFT_sEMG_nom_IIR.DFT = DFT_sEMG_nom_IIR;
    
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_HE.f = f_DFT_sEMG_nom_WD_HE;
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_HE.DFT = DFT_sEMG_nom_WD_HE;
    
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_LE.f = f_DFT_sEMG_nom_WD_FFC_LE;
    capturaDatos.analisisFourier.DFT_sEMG_nom_WD_FFC_LE.DFT = DFT_sEMG_nom_WD_FFC_LE;
    
    %field = 'DFT_sEMG_raw_nom';
    % Definir las estructuras para el ejemplo
    % A.B.C.campoObjetivo = 42;

    % Verificar si las estructuras anidadas y el campo existen
    % if isfield(capturaDatos, 'analisisFourier') && isfield(capturaDatos.analisisFourier, 'DFT_sEMG_raw_nom')
    %     capturaDatos.analisisFourier = rmfield(capturaDatos.analisisFourier, field);
    % end

    % Verificar si el campo 'sEMG_nom_waveletDenosing_envelopeHilbert' existe en la estructura 'capturaDatos'
    if isfield(capturaDatos, 'sEMG_nom_waveletDenosing_envelopeHilbert')
        capturaDatos = rmfield(capturaDatos, 'sEMG_nom_waveletDenosing_envelopeHilbert');
    end

    save(nombreCompletoArchivo, 'capturaDatos', 'variablesMuestreo');
end

% Función para obtener el espectro de amplitud de un lado mediante
% Transformada Discreta de Fourier
function [f, espectroFrecuenciasPostivas1] = SingleSidedAmplitudSpectrumFFT(Fs, T, L, X)
    Y = fft(X);
    espectroFrecuenciasPostivas2 = abs(Y/L);
    espectroFrecuenciasPostivas1 = espectroFrecuenciasPostivas2(1:L/2+1);
    % Dominio de la frecuencia f para el espectro de un lado
    f = Fs/L*(0:(L/2));

    espectroFrecuenciasPostivas1(2:end-1) = 2*espectroFrecuenciasPostivas1(2:end-1);
end