# Funciones de membresía triangulares
def triangular(x, a, b, c):
    return max(min((x - a) / (b - a), (c - x) / (c - b)), 0)

def fuzzify(value):
    return {
        'veryLow': triangular(value, 0.0, 0.0, 0.10),
        'low': triangular(value, 0.05, 0.15, 0.25),
        'medium': triangular(value, 0.20, 0.30, 0.40),
        'high': triangular(value, 0.30, 1.0, 1.0)
    }

# Reglas: devuelve la clase con mayor activación
def infer_class(fds_val, edc_val):
    fds_fuzzy = fuzzify(fds_val)
    edc_fuzzy = fuzzify(edc_val)

    rule_strengths = {

        # Condiciomes lógicas difusas
        'REP': max(
            min(fds_fuzzy['veryLow'], edc_fuzzy['veryLow']), 
            min(fds_fuzzy['low'], edc_fuzzy['low'])),
        'WF': min(fds_fuzzy['high'], edc_fuzzy['low']),
        'WE': min(fds_fuzzy['low'], edc_fuzzy['high']),
        'HC': max(
            min(fds_fuzzy['medium'], edc_fuzzy['medium']), 
            min(fds_fuzzy['high'], edc_fuzzy['high']),
            min(fds_fuzzy['medium'], edc_fuzzy['low']),
            min(fds_fuzzy['low'], edc_fuzzy['medium']))

    }
    # Devolver la clase con mayor activación
    return max(rule_strengths.items(), key=lambda item: item[1])[0]
