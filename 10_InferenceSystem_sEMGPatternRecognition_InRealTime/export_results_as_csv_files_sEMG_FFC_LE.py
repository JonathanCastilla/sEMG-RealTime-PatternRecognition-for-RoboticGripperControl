# Importación de bibliotecas necesarias
import os
import csv
import pandas as pd


# ======== FUNCIONES DE EXPORTACIÓN DE ETIQUETAS A ARCHIVO CSV =======

# Crear carpeta de resultados
def create_results_folders(nombre_carpeta="resultados"):
    os.makedirs(nombre_carpeta, exist_ok=True)
    return nombre_carpeta  # Devuelve el path

def to_export_labels_csv(lista_etiquetas, carpeta='resultados', nombre_archivo='etiquetas_S1.csv'):
    """
    Exporta una lista de etiquetas a un archivo CSV con cada etiqueta en una fila,
    guardándolo dentro de una carpeta específica.

    Parámetros:
        lista_etiquetas (list): Lista de etiquetas a exportar.
        carpeta (str): Carpeta donde se guardará el archivo.
        nombre_archivo (str): Nombre del archivo CSV de salida.
    """
    # Crear carpeta si no existe
    os.makedirs(carpeta, exist_ok=True)

    # Ruta completa del archivo
    ruta_completa = os.path.join(carpeta, nombre_archivo)

    # Escribir CSV
    with open(ruta_completa, 'w', newline='') as f:
        writer = csv.writer(f)
        for etiqueta in lista_etiquetas:
            writer.writerow([etiqueta])  # Cada etiqueta en una fila

    print(f"Etiquetas exportadas en: {ruta_completa}")

    
def to_export_data_from_plot_csv(x_data, y_data, carpeta='resultados', nombre_archivo='resultados.xlsx'):
    """
    Exporta listas de índices y etiquetas numéricas a un archivo Excel.

    Parámetros:
        x_data (list): Lista de índices o tiempos.
        y_data (list): Lista de etiquetas numéricas correspondientes.
        carpeta (str): Nombre del directorio dónde se almacenarán los resultados
        nombre_archivo (str): Nombre del archivo de salida Excel. Por defecto: 'resultados.xlsx'.
    """

    # Verificar que existe la carpeta de almacenamiento
    os.makedirs(carpeta, exist_ok=True)

    df = pd.DataFrame({
        'Índice': x_data,
        'Etiqueta': y_data
    })
    
    ruta_completa = os.path.join(carpeta, nombre_archivo)
    df.to_excel(ruta_completa, index=False)
    print(f"Historial exportado a: {ruta_completa}")
 

def to_export_history_to_excel(historial_contadores, carpeta='resultados', nombre_archivo='historial_por_segundo.xlsx'):
    """
    Exporta el historial de conteos por segundo a un archivo Excel.

    Parámetros:
        historial_contadores (list of dict): Lista donde cada elemento es un dict con clases y su conteo por segundo.
        nombre_archivo (str): Nombre del archivo de salida.
    """
    # Verificar que existe la carpeta de almacenamiento
    os.makedirs(carpeta, exist_ok=True)

    # Crear un DataFrame con cada fila como un segundo
    df = pd.DataFrame(historial_contadores).fillna(0).astype(int)
    df.index.name = "Segundo"

    ruta_completa = os.path.join(carpeta, nombre_archivo)
    df.to_excel(ruta_completa)
    print(f"Historial exportado a: {ruta_completa}")


def to_export_calibration_data_for_inference(valores_dict, carpeta='resultados', nombre_archivo='valores_unicos.csv'):
    """
    Exporta un diccionario de variables únicas a un archivo CSV.
    Cada clave será una columna, y sus valores estarán en una sola fila.
    """
    os.makedirs(carpeta, exist_ok=True)
    ruta_completa = os.path.join(carpeta, nombre_archivo)

    with open(ruta_completa, mode='w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=valores_dict.keys())
        writer.writeheader()
        writer.writerow(valores_dict)

    print(f"Valores únicos exportados correctamente a: {ruta_completa}")

    

def to_export_data_from_robotic_gripper_csv(datos, labels, carpeta='resultados', nombre_archivo='datos_gripper_S1.csv'):
    """
    Exporta los datos acumulados a un archivo CSV en la carpeta especificada.
    """
    os.makedirs(carpeta, exist_ok=True)
    ruta_completa = os.path.join(carpeta, nombre_archivo)

    with open(ruta_completa, mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=labels)
        writer.writeheader()
        writer.writerows(datos)

    print(f"Datos exportados correctamente a: {ruta_completa}")
