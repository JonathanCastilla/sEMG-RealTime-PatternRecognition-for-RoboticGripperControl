clc;
clear all;
close all;

% Cargar archivo .MAT
directoryPath = 'sEMGmuestrasLimpiasDef\sEMG_datosSensor_MAD_EDC_WF_M3sec_P6';
load(directoryPath);

nameField = 'sEMG_FFC_envelopeLineal_ESP32';
data = capturaDatos.(nameField);
tiempo = capturaDatos.tiempo;

% Calcular el segundo valor mínimo (excluyendo el mínimo absoluto)
sorted_data = unique(sort(data)); % Ordenar valores únicos de menor a mayor
if length(sorted_data) >= 2
    second_min_val = sorted_data(3); % Segundo valor más pequeño
else
    second_min_val = sorted_data(1); % Si solo hay un valor único
end

% Graficar señal original
figure('Name','Selección manual de outliers','NumberTitle','off');
hPlot = plot(tiempo, data, '-', 'LineWidth', 1.0);
title({'Selecciona los límites de los rangos con outliers',...
       'Haz clic izquierdo para seleccionar inicio y fin de cada rango',...
       'Haz clic derecho para terminar'});
xlabel('Tiempo (s)');
ylabel('Amplitud');
grid on;
hold on;

% Inicialización de variables
idx_total = false(size(data));
selected_ranges = []; % Para almacenar los rangos seleccionados

% Selección interactiva de múltiples rangos
disp('Selecciona los rangos con outliers (clic izquierdo para cada rango, clic derecho para terminar)');

while true
    % Seleccionar primer punto del rango
    [x1, ~, button] = ginput(1);
    
    % Terminar si es clic derecho
    if button == 3
        break;
    end
    
    % Seleccionar segundo punto del rango
    [x2, ~] = ginput(1);
    
    % Determinar los límites del rango
    t_start = min([x1, x2]);
    t_end = max([x1, x2]);
    
    % Guardar el rango seleccionado
    selected_ranges = [selected_ranges; t_start, t_end];
    
    % Marcar los puntos en el rango
    idx_rango = tiempo >= t_start & tiempo <= t_end;
    idx_total = idx_total | idx_rango;
    
    % Visualización del rango seleccionado
    plot(tiempo(idx_rango), data(idx_rango), 'r.', 'MarkerSize', 10);
    plot([t_start t_end], [second_min_val second_min_val], 'gx', 'MarkerSize', 12, 'LineWidth', 2);
end

% Aplicar el filtrado
data_filtrada = data;
data_filtrada(idx_total) = second_min_val;

% Graficar resultados comparativos
figure('Name','Comparación de señales','NumberTitle','off');
subplot(2,1,1);
plot(tiempo, data, '-', 'LineWidth', 1.0);
title('Datos originales');
grid on;
hold on;

% Resaltar todos los rangos seleccionados
for i = 1:size(selected_ranges, 1)
    idx = tiempo >= selected_ranges(i,1) & tiempo <= selected_ranges(i,2);
    plot(tiempo(idx), data(idx), 'r.', 'MarkerSize', 10);
end

subplot(2,1,2);
plot(tiempo, data_filtrada, '-', 'LineWidth', 1.0, 'Color', [0.8 0 0]);
title(['Datos filtrados (outliers reemplazados por el segundo mínimo: ', num2str(second_min_val), ')']);
grid on;

% Mostrar información en consola
disp('=== Resumen del procesamiento ===');
disp(['Segundo valor mínimo asignado: ', num2str(second_min_val)]);
disp(['Valor mínimo absoluto: ', num2str(min(data))]);
disp('Rangos seleccionados:');
for i = 1:size(selected_ranges, 1)
    disp(['Rango ', num2str(i), ': ', num2str(selected_ranges(i,1)), ' s a ', ...
          num2str(selected_ranges(i,2)), ' s (', ...
          num2str(sum(tiempo >= selected_ranges(i,1) & tiempo <= selected_ranges(i,2))), ' puntos)']);
end
disp(['Total de puntos modificados: ', num2str(sum(idx_total)), ...
      ' (', num2str(100*sum(idx_total)/length(data)), '%)']);

% Guardar resultados
capturaDatos.(nameField) = data_filtrada;

% GUARDAR DATOS EN UN ARCHIVO MAT
save(directoryPath, 'capturaDatos', 'variablesMuestreo');
