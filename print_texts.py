import os
import re

directory = r'c:\Users\herma\Documents\SENA\proyecto\movil_mi_conductor\lib'
for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Print out Text('...') literals
            texts = re.findall(r'Text\(\s*[\'\"](.*?)[\'\"]', content)
            if texts:
                for t in texts:
                    if re.search(r'[a-zA-Z]{5,}', t):  # At least one 5-letter word
                        print(f'{os.path.basename(file)}: {t}')
