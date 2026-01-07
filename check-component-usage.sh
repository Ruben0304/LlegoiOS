#!/bin/bash

# Script para verificar el uso de componentes en screens, sheets y theme
# Uso: ./check-component-usage.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Verificador de Uso de Componentes${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Rutas base
COMPONENTS_DIR="LlegoiOS/ui/components"
SCREENS_DIR="LlegoiOS/ui/screens"
SHEETS_DIR="LlegoiOS/ui/sheets"
THEME_DIR="LlegoiOS/ui/theme"

# Contadores
TOTAL=0
USED=0
UNUSED=0

# Arrays para almacenar resultados
declare -a UNUSED_COMPONENTS
declare -a USED_COMPONENTS

# Función para extraer el nombre del componente principal de un archivo
extract_component_name() {
    local file="$1"
    # Buscar struct o class que no sea private y extraer el nombre
    # Ignora líneas comentadas
    grep -E "^(public |internal )?struct [A-Z]|^(public |internal )?class [A-Z]" "$file" | \
        grep -v "private" | \
        head -n 1 | \
        sed -E 's/.*(struct|class) ([A-Za-z0-9_]+).*/\2/'
}

# Función para verificar si un componente está en uso
check_component_usage() {
    local component_name="$1"
    local count=0

    # Buscar en screens
    if [ -d "$SCREENS_DIR" ]; then
        count=$((count + $(find "$SCREENS_DIR" -name "*.swift" -type f -exec grep -l "\b$component_name\b" {} \; 2>/dev/null | wc -l)))
    fi

    # Buscar en sheets
    if [ -d "$SHEETS_DIR" ]; then
        count=$((count + $(find "$SHEETS_DIR" -name "*.swift" -type f -exec grep -l "\b$component_name\b" {} \; 2>/dev/null | wc -l)))
    fi

    # Buscar en theme
    if [ -d "$THEME_DIR" ]; then
        count=$((count + $(find "$THEME_DIR" -name "*.swift" -type f -exec grep -l "\b$component_name\b" {} \; 2>/dev/null | wc -l)))
    fi

    echo $count
}

# Verificar que el directorio de componentes existe
if [ ! -d "$COMPONENTS_DIR" ]; then
    echo -e "${RED}❌ Error: No se encontró el directorio $COMPONENTS_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}📁 Escaneando componentes en: $COMPONENTS_DIR${NC}\n"

# Iterar sobre todos los archivos .swift en components y subcarpetas
while IFS= read -r component_file; do
    TOTAL=$((TOTAL + 1))

    # Extraer nombre del componente
    component_name=$(extract_component_name "$component_file")

    if [ -z "$component_name" ]; then
        echo -e "${YELLOW}⚠️  No se pudo extraer nombre de: $(basename "$component_file")${NC}"
        continue
    fi

    # Obtener ruta relativa para mejor visualización
    relative_path="${component_file#LlegoiOS/ui/}"

    # Verificar uso
    usage_count=$(check_component_usage "$component_name")

    if [ "$usage_count" -gt 0 ]; then
        USED=$((USED + 1))
        USED_COMPONENTS+=("$component_name|$relative_path|$usage_count")
        echo -e "${GREEN}✅ $component_name${NC} - Usado en $usage_count archivo(s) - ${BLUE}$relative_path${NC}"
    else
        UNUSED=$((UNUSED + 1))
        UNUSED_COMPONENTS+=("$component_name|$relative_path")
        echo -e "${RED}❌ $component_name${NC} - SIN USO - ${BLUE}$relative_path${NC}"
    fi

done < <(find "$COMPONENTS_DIR" -name "*.swift" -type f)

# Reporte final
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}           REPORTE FINAL${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}📊 Estadísticas:${NC}"
echo -e "   Total de componentes: ${BLUE}$TOTAL${NC}"
USED_PERCENT=$(echo "scale=1; ($USED * 100) / $TOTAL" | bc)
UNUSED_PERCENT=$(echo "scale=1; ($UNUSED * 100) / $TOTAL" | bc)
echo -e "   Componentes en uso: ${GREEN}$USED${NC} ($USED_PERCENT%)"
echo -e "   Componentes sin uso: ${RED}$UNUSED${NC} ($UNUSED_PERCENT%)"

if [ ${#UNUSED_COMPONENTS[@]} -gt 0 ]; then
    echo -e "\n${RED}⚠️  COMPONENTES SIN USO (Candidatos para eliminar):${NC}\n"
    for item in "${UNUSED_COMPONENTS[@]}"; do
        IFS='|' read -r name path <<< "$item"
        echo -e "   ${RED}•${NC} $name"
        echo -e "     ${BLUE}└─ $path${NC}"
    done

    echo -e "\n${YELLOW}💡 Para eliminar estos componentes, ejecuta:${NC}"
    for item in "${UNUSED_COMPONENTS[@]}"; do
        IFS='|' read -r name path <<< "$item"
        echo -e "   rm \"LlegoiOS/ui/$path\""
    done
else
    echo -e "\n${GREEN}🎉 ¡Todos los componentes están en uso!${NC}"
fi

echo -e "\n${BLUE}========================================${NC}"

# Código de salida basado en si hay componentes sin uso
if [ "$UNUSED" -gt 0 ]; then
    exit 1
else
    exit 0
fi
