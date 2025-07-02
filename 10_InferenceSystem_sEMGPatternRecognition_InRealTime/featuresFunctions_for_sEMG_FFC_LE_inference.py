import numpy as np

def compute_dasdv(segment):
    """
    Calcula el Valor Absoluto Promedio de la Diferencia Cuadrática (DASDV, por sus siglas en inglés).
    
    DASDV es una métrica utilizada en el análisis de señales electromiográficas (sEMG) para cuantificar la variabilidad de la señal.
    Se obtiene calculando la raíz cuadrada del valor medio de las diferencias cuadráticas entre muestras consecutivas.
    
    Parámetros:
        segment (numpy.ndarray): Segmento de señal en forma de arreglo de valores.
    
    Retorna:
        float: Valor de DASDV del segmento de señal.
    """
    return np.sqrt(np.mean(np.diff(segment) ** 2))

def compute_iemg(segment):
    """
    Calcula la Integral de la señal EMG (IEMG), definida como la suma de los valores absolutos del segmento.
    
    Parámetros:
    segment (array-like): Conjunto de datos que representa un segmento de la señal EMG.
    
    Retorna:
    float: Valor de la integral de la señal EMG.
    """
    return np.sum(np.abs(segment))

def compute_variance(segmento):
    """
    Calcula la varianza de un segmento de señal.
    
    Parámetros:
    segmento : array_like
        Array unidimensional que contiene los valores del segmento de señal a analizar
        
    Retorna:
    float
        Varianza del segmento calculada como la media de las diferencias cuadradas
        respecto a la media (varianza muestral)
        
    Nota:
    - Esta función es equivalente a var() en MATLAB, que calcula la varianza muestral
    - En numpy, ddof=0 corresponde al divisor N (como en MATLAB), ddof=1 usa N-1
    """
    return np.var(segmento, ddof=0)

def compute_wl(segmento):
    """
    Calcula la longitud de onda (Waveform Length) de un segmento de señal.
    
    Parámetros:
    segmento : array_like
        Array unidimensional que contiene los valores del segmento de señal a analizar
        
    Retorna:
    float
        Suma acumulada de las diferencias absolutas entre puntos consecutivos
        de la señal. Esta medida cuantifica la variabilidad total de la amplitud
        de la señal a lo largo del segmento.
        
    Nota:
    - La longitud de onda es un descriptor común en el análisis de señales EMG
    - Proporciona información sobre la complejidad de la forma de onda
    """
    return np.sum(np.abs(np.diff(segmento)))

def compute_mwl(segmento):
    """
    Calcula la longitud de onda modificada (Modified Waveform Length) de un segmento.
    
    Parámetros:
    segmento : array_like
        Array unidimensional que contiene los valores del segmento de señal a analizar
        
    Retorna:
    float
        Suma acumulada de las diferencias absolutas de las segundas diferencias
        (derivada discreta de segundo orden). Esta medida es más sensible a cambios
        bruscos en la señal que la longitud de onda tradicional.
        
    Nota:
    - La MWL es útil para detectar transiciones rápidas en la señal
    - Proporciona información sobre la suavidad/asperidad de la forma de onda
    """
    return np.sum(np.abs(np.diff(np.diff(segmento))))
