import numpy as np
import skfuzzy as fuzz  # Asegúrate de tener `scikit-fuzzy` instalado

# ---------- 1. FUNCIONES DE MEMBRESÍA ---------------------------------
# • veryLow  ⟶  hombro izquierdo  (z-shaped): vale 1 muy cerca de 0 y desciende a 0
# • low, medium ⟶ gaussianas      (campanas suaves)
# • high     ⟶  hombro derecho    (s-shaped): vale 0 al inicio y sube hasta 1


# Funciones de membresía gaussianas

def fuzzify(value: float) -> dict:
    value = float(value)  # asegúrate de que sea escalar

    return {
        'veryLow': float(fuzz.zmf(np.array([value]), 0.0, 0.03)[0]),
        'low':     float(fuzz.gaussmf(value, 0.05, 0.035)),
        'medium':  float(fuzz.gaussmf(value, 0.075,  0.025)),
        'high':    float(fuzz.smf(np.array([value]), 0.09, 1.0)[0])
    }


# Reglas: devuelve la clase con mayor activación
def infer_class(fds_val: float, edc_val: float) -> dict:
    fds_fuzzy = fuzzify(fds_val)
    edc_fuzzy = fuzzify(edc_val)

    rule_strengths = {

        # Condiciomes lógicas difusas
        'WF': max(
            min(fds_fuzzy['high'], edc_fuzzy['veryLow']),
            min(fds_fuzzy['high'], edc_fuzzy['low']),
            min(fds_fuzzy['medium'], edc_fuzzy['veryLow']),
            min(fds_fuzzy['medium'], edc_fuzzy['low'])),
        'WE': max(
            min(fds_fuzzy['veryLow'], edc_fuzzy['high']),
            min(fds_fuzzy['low'], edc_fuzzy['high'])),
            # min(fds_fuzzy['veryLow'], edc_fuzzy['medium'])),
        'HC': max(
            min(fds_fuzzy['medium'], edc_fuzzy['medium']), 
            min(fds_fuzzy['high'], edc_fuzzy['high']),
            min(fds_fuzzy['low'], edc_fuzzy['medium'])),
            # min(fds_fuzzy['medium'], edc_fuzzy['low'])),
            # min(fds_fuzzy['low'], edc_fuzzy['medium'])
            # min(fds_fuzzy['high'], edc_fuzzy['high']),

        'REP': min(fds_fuzzy['veryLow'], edc_fuzzy['veryLow'])
        #'REP': max(
        #    min(fds_fuzzy['veryLow'], edc_fuzzy['veryLow']),
        #    min(fds_fuzzy['low'], edc_fuzzy['low']))

    }
    # Devolver la clase con mayor activación
    return rule_strengths

#labels = ["WF", "WE", "HC", "REP"]
#fuzzy_scores = infer_class(0.04, 0.04)
#print(fuzzy_scores)

# fuzzy_vec = np.array([fuzzy_scores[l] for l in labels])
#result = np.argmax(fuzzy_vec)
#print(infer_class(0.3, 0.4))
#print(fuzzy_vec)
#print(result)