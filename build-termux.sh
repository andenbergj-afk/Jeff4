#!/bin/bash
# =============================================================================
# Script de Build do APK Focus no Termux
# =============================================================================
# Requisitos: Termux com acesso à internet
# Uso: bash build-termux.sh
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

print_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# =============================================================================
# PASSO 1: Verificar e instalar dependências do Termux
# =============================================================================
print_step "Verificando dependências do Termux..."

pkg update -y && pkg upgrade -y

PACKAGES_NEEDED=()

if ! command -v node &>/dev/null; then
    PACKAGES_NEEDED+=("nodejs")
fi
if ! command -v java &>/dev/null; then
    PACKAGES_NEEDED+=("openjdk-17")
fi
if ! command -v wget &>/dev/null; then
    PACKAGES_NEEDED+=("wget")
fi
if ! command -v unzip &>/dev/null; then
    PACKAGES_NEEDED+=("unzip")
fi
if ! command -v git &>/dev/null; then
    PACKAGES_NEEDED+=("git")
fi

if [ ${#PACKAGES_NEEDED[@]} -gt 0 ]; then
    print_step "Instalando pacotes: ${PACKAGES_NEEDED[*]}"
    pkg install -y "${PACKAGES_NEEDED[@]}"
else
    print_ok "Todos os pacotes já estão instalados"
fi

# =============================================================================
# PASSO 2: Configurar JAVA_HOME
# =============================================================================
print_step "Configurando JAVA_HOME..."

if [ -z "$JAVA_HOME" ]; then
    # Detectar onde o Java está instalado no Termux
    JAVA_PATH=$(which java)
    JAVA_REALPATH=$(readlink -f "$JAVA_PATH")
    export JAVA_HOME=$(dirname $(dirname "$JAVA_REALPATH"))
    print_ok "JAVA_HOME configurado: $JAVA_HOME"
else
    print_ok "JAVA_HOME já configurado: $JAVA_HOME"
fi

java -version 2>&1 | head -1

# =============================================================================
# PASSO 3: Configurar Android SDK
# =============================================================================
ANDROID_SDK_ROOT="$HOME/android-sdk"
CMDLINE_TOOLS_DIR="$ANDROID_SDK_ROOT/cmdline-tools/latest"

print_step "Verificando Android SDK em $ANDROID_SDK_ROOT..."

if [ ! -f "$CMDLINE_TOOLS_DIR/bin/sdkmanager" ]; then
    print_step "Baixando Android Command-Line Tools..."
    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
    
    # Versão mais recente das command-line tools (linux)
    CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
    CMDTOOLS_ZIP="/tmp/cmdline-tools.zip"
    
    wget -q --show-progress "$CMDTOOLS_URL" -O "$CMDTOOLS_ZIP"
    
    print_step "Extraindo Command-Line Tools..."
    unzip -q "$CMDTOOLS_ZIP" -d "$ANDROID_SDK_ROOT/cmdline-tools/"
    mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$CMDLINE_TOOLS_DIR"
    rm -f "$CMDTOOLS_ZIP"
    
    print_ok "Android Command-Line Tools instalado"
else
    print_ok "Android Command-Line Tools já instalado"
fi

# Configurar variáveis do Android SDK
export ANDROID_SDK_ROOT="$HOME/android-sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$PATH:$CMDLINE_TOOLS_DIR/bin:$ANDROID_SDK_ROOT/platform-tools"

# =============================================================================
# PASSO 4: Instalar componentes do Android SDK
# =============================================================================
print_step "Instalando componentes do Android SDK..."

# Aceitar licenças
yes | sdkmanager --licenses 2>/dev/null || true

# Instalar plataforma e build-tools necessários
sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools" 2>&1 | grep -v "^\[=" || true

print_ok "Componentes do Android SDK instalados"

# =============================================================================
# PASSO 5: Configurar local.properties
# =============================================================================
print_step "Configurando local.properties..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$SCRIPT_DIR/android"

cat > "$ANDROID_DIR/local.properties" << EOF
# Gerado automaticamente por build-termux.sh
# Não comitar este arquivo
sdk.dir=$ANDROID_SDK_ROOT
EOF

print_ok "local.properties configurado"

# =============================================================================
# PASSO 6: Instalar dependências Node.js
# =============================================================================
print_step "Instalando dependências Node.js..."

cd "$SCRIPT_DIR"
npm install

print_ok "Dependências Node.js instaladas"

# =============================================================================
# PASSO 7: Build do projeto web (Vite)
# =============================================================================
print_step "Fazendo build do projeto web..."

npm run build

print_ok "Build web concluído"

# =============================================================================
# PASSO 8: Sincronizar com Capacitor
# =============================================================================
print_step "Sincronizando com Capacitor..."

npx cap sync android

print_ok "Capacitor sincronizado"

# =============================================================================
# PASSO 9: Build do APK com Gradle
# =============================================================================
print_step "Fazendo build do APK (isso pode demorar alguns minutos)..."

cd "$ANDROID_DIR"
chmod +x gradlew

# Aumentar memória para o Gradle (importante no Termux)
export GRADLE_OPTS="-Xmx1024m -Dorg.gradle.daemon=false"

# Build do APK de debug
./gradlew assembleDebug --no-daemon --warning-mode=none 2>&1

# =============================================================================
# RESULTADO FINAL
# =============================================================================
APK_PATH="$ANDROID_DIR/app/build/outputs/apk/debug/app-debug.apk"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -sh "$APK_PATH" | cut -f1)
    print_ok "APK gerado com sucesso!"
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  APK GERADO COM SUCESSO!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "  Localização: ${YELLOW}$APK_PATH${NC}"
    echo -e "  Tamanho: ${YELLOW}$APK_SIZE${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Para instalar no dispositivo:"
    echo "  adb install $APK_PATH"
    echo ""
    echo "Ou copie o arquivo APK para instalar manualmente."
else
    print_error "APK não foi gerado. Verifique os logs acima."
    exit 1
fi
