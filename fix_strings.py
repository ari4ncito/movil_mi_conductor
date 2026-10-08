import os
import re

replacements = {
    r'\bcontraseñas?\b': 'contraseña',
    r'\bContraseñas?\b': 'Contraseña',
    r'\bterminos?\b': 'término',
    r'\bTerminos?\b': 'Términos', # Términos usually plural
    r'\bpoliticas?\b': 'política',
    r'\bPoliticas?\b': 'Política',
    r'\btelefono\b': 'teléfono',
    r'\bTelefono\b': 'Teléfono',
    r'\bdireccion\b': 'dirección',
    r'\bDireccion\b': 'Dirección',
    r'\bdirecciones\b': 'direcciones', # wait direcciones has no tilde
    r'\bDirecciones\b': 'Direcciones',
    r'\bvehiculo\b': 'vehículo',
    r'\bVehiculo\b': 'Vehículo',
    r'\bvehiculos\b': 'vehículos',
    r'\bVehiculos\b': 'Vehículos',
    r'\bnumero\b': 'número',
    r'\bNumero\b': 'Número',
    r'\bnumeros\b': 'números',
    r'\bNumeros\b': 'Números',
    r'\bsesion\b': 'sesión',
    r'\bSesion\b': 'Sesión',
    r'\bcedula\b': 'cédula',
    r'\bCedula\b': 'Cédula',
    r'\bcodigo\b': 'código',
    r'\bCodigo\b': 'Código',
    r'\binformacion\b': 'información',
    r'\bInformacion\b': 'Información',
    r'\bconfiguracion\b': 'configuración',
    r'\bConfiguracion\b': 'Configuración',
    r'\bubicacion\b': 'ubicación',
    r'\bUbicacion\b': 'Ubicación',
    r'\bboton\b': 'botón',
    r'\bBoton\b': 'Botón',
    r'\baccion\b': 'acción',
    r'\bAccion\b': 'Acción',
    r'\bacciones\b': 'acciones',
    r'\bautenticacion\b': 'autenticación',
    r'\bAutenticacion\b': 'Autenticación',
    r'\baqui\b': 'aquí',
    r'\bAqui\b': 'Aquí',
    r'\bmenu\b': 'menú',
    r'\bMenu\b': 'Menú',
    r'\bmovil\b': 'móvil',
    r'\bMovil\b': 'Móvil',
    r'\btambien\b': 'también',
    r'\bTambien\b': 'También',
    r'\btitulo\b': 'título',
    r'\bTitulo\b': 'Título',
    r'\bexito\b': 'éxito',
    r'\bExito\b': 'Éxito',
    r'\bdia\b': 'día',
    r'\bDia\b': 'Día',
    r'\bdias\b': 'días',
    r'\bDias\b': 'Días',
    r'\bedicion\b': 'edición',
    r'\bEdicion\b': 'Edición',
    r'\bcancelacion\b': 'cancelación',
    r'\bCancelacion\b': 'Cancelación',
    r'\bconfirmacion\b': 'confirmación',
    r'\bConfirmacion\b': 'Confirmación',
    r'\bopcion\b': 'opción',
    r'\bOpcion\b': 'Opción',
    r'\bversion\b': 'versión',
    r'\bVersion\b': 'Versión',
    r'\bcamara\b': 'cámara',
    r'\bCamara\b': 'Cámara',
    r'\bgaleria\b': 'galería',
    r'\bGaleria\b': 'Galería',
    r'\bpagina\b': 'página',
    r'\bPagina\b': 'Página',
    r'\bregistrate\b': 'regístrate',
    r'\bRegistrate\b': 'Regístrate',
    r'\bmas\b': 'más',
    r'\bMas\b': 'Más',
    r'\besta\b': 'está', # we will manually check if we can
    r'\bEsta\b': 'Está',
    r'\bpais\b': 'país',
    r'\bPais\b': 'País',
    r'\bbusqueda\b': 'búsqueda',
    r'\bBusqueda\b': 'Búsqueda',
    r'\bano\b': 'año',
    r'\bAno\b': 'Año',
    r'\banos\b': 'años',
    r'\bAnos\b': 'Años',
    r'\banadir\b': 'añadir',
    r'\bAnadir\b': 'Añadir',
    r'\btamano\b': 'tamaño',
    r'\bTamano\b': 'Tamaño',
    r'\bdiseno\b': 'diseño',
    r'\bDiseno\b': 'Diseño'
}

def fix_strings(text):
    def replacer(match):
        s = match.group(0)
        
        # Don't modify simple lowercase strings without spaces as they are likely map keys or json properties
        if re.match(r'^[\'\"][a-z][a-zA-Z0-9_]*[\'\"]$', s):
            return s
            
        for pattern, replacement in replacements.items():
            s = re.sub(pattern, replacement, s)
            
        # Fix the word 'esta' contextually? 
        # Too hard, skip 'esta' to avoid changing 'esta app' -> 'está app'
        s = re.sub(r'\bestá (app|vez|semana|persona|cuenta|opción)\b', lambda m: 'esta ' + m.group(1), s)
        s = re.sub(r'\bEstá (app|vez|semana|persona|cuenta|opción)\b', lambda m: 'Esta ' + m.group(1), s)
        
        return s

    # Regex matches single or double quoted strings
    return re.sub(r'\'[^\']*\'|\"[^\"]*\"', replacer, text)

directory = r'c:\Users\herma\Documents\SENA\proyecto\movil_mi_conductor\lib'
changed_files = 0
for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = fix_strings(content)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Fixed: {filepath}')
                changed_files += 1

print(f'Total files fixed: {changed_files}')
