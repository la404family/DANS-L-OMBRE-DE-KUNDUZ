import re
import os

# ==========================================
# CONFIGURATION
# ==========================================
# Remplacez le chemin ci-dessous par le chemin absolu ou relatif de votre fichier
TARGET_FILE = r"functions\fn_task05.sqf"

# ==========================================
# CODE
# ==========================================

def remove_comments(text):
    """
    Supprime les commentaires de style C (// et /* ... */)
    tout en préservant les chaînes de caractères.
    """
    def replacer(match):
        s = match.group(0)
        if s.startswith('/'):
            return " " # Remplacer les commentaires par un espace
        else:
            return s # Garder les chaînes de caractères intactes

    # Regex pour capturer :
    # 1. Les chaînes entre guillemets doubles (")
    # 2. Les chaînes entre guillemets simples (')
    # 3. Les commentaires blocs (/* ... */)
    # 4. Les commentaires ligne (// ...)
    pattern = re.compile(
        r'("[^"\\]*(?:\\.[^"\\]*)*"|' +  # Chaînes doubles
        r"'[^'\\]*(?:\\.[^'\\]*)*'|" +   # Chaînes simples
        r'/\*[^*]*\*+(?:[^/*][^*]*\*+)*/|' + # Commentaires blocs
        r'//[^\r\n]*)',                   # Commentaires ligne
        re.DOTALL | re.MULTILINE
    )
    
    return re.sub(pattern, replacer, text)

def main():
    if not os.path.exists(TARGET_FILE):
        print(f"Erreur : Le fichier '{TARGET_FILE}' est introuvable.")
        return

    try:
        # Lecture du fichier
        with open(TARGET_FILE, 'r', encoding='utf-8') as f:
            content = f.read()

        # Suppression des commentaires
        clean_content = remove_comments(content)

        # Nettoyage des lignes vides excédentaires (optionnel)
        # clean_content = re.sub(r'\n\s*\n', '\n', clean_content)

        # Écriture du résultat (écrasement du fichier original)
        with open(TARGET_FILE, 'w', encoding='utf-8') as f:
            f.write(clean_content)

        print(f"Succès ! Les commentaires ont été supprimés de :")
        print(f"{TARGET_FILE}")

    except Exception as e:
        print(f"Une erreur est survenue : {e}")

if __name__ == "__main__":
    main()
