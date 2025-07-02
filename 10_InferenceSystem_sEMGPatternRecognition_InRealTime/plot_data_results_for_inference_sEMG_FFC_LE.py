# ------------------------ GRAFICACIÓN AL FINAL ------------------------ #
import os
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

def plot_data_and_save_plot(x_data, y_data, heights, colors, label_names, carpeta='resultados', nombre_archivo='grafica_etiquetas.png'):
    """
    Grafica los datos de etiquetas y guarda la gráfica como imagen en una carpeta.

    Parámetros:
        x_data (list): Eje X (tiempo o muestras).
        y_data (list): Etiquetas correspondientes.
        heights (dict): Altura de cada etiqueta.
        colors (dict): Colores asociados a cada etiqueta.
        label_names (dict): Nombres descriptivos de las etiquetas.
        carpeta (str): Carpeta donde se guardará la gráfica.
        nombre_archivo (str): Nombre del archivo de imagen (formato PNG recomendado).
    """
    os.makedirs(carpeta, exist_ok=True)
    ruta_completa = os.path.join(carpeta, nombre_archivo)

    # Crear la figura
    plt.figure(figsize=(10, 5))
    for x, y in zip(x_data, y_data):
        etiqueta = str(y)
        height = heights.get(etiqueta, 1)
        color = colors.get(etiqueta, 'black')
        plt.plot([x, x], [0, height], color=color, linewidth=2)

    # Crear leyenda
    legend_elements = [
        mpatches.Patch(color=colors[etiqueta], label=label_names[etiqueta])
        for etiqueta in colors
    ]
    plt.legend(handles=legend_elements, title='Etiquetas')

    plt.title('Evolución de etiquetas (al finalizar)')
    plt.xlabel('Muestras')
    plt.ylabel('Relevancia / Etiqueta')
    plt.grid(True)
    plt.tight_layout()

    # Guardar la figura sin mostrarla
    plt.savefig(ruta_completa)
    plt.close()

    print(f"Gráfica guardada en: {ruta_completa}")
