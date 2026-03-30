<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# Focus – Estudo & Produtividade

Aplicativo para organizar e otimizar sua rotina de estudos. Funciona 100% offline, com temporizador Pomodoro, repetição espaçada, rastreamento de questões, metas, conquistas e muito mais.

## Executar Localmente (Web)

**Pré-requisitos:** Node.js

1. Instale as dependências:
   ```bash
   npm install
   ```
2. Execute o app:
   ```bash
   npm run dev
   ```

---

## 📱 Gerar APK Android (no Termux)

Você pode gerar o APK diretamente no seu celular usando o [Termux](https://termux.dev/).

### Passo a Passo

**1. Instale o Termux**
Baixe o Termux pelo [F-Droid](https://f-droid.org/en/packages/com.termux/) (recomendado) ou pela Play Store.

**2. Clone o repositório**
```bash
pkg install git nodejs -y
git clone https://github.com/andenbergj-afk/Jeff4.git
cd Jeff4
```

**3. Execute o script de build**
```bash
bash build-termux.sh
```

O script irá automaticamente:
- Instalar o JDK 17 e demais dependências do Termux
- Baixar e configurar o Android SDK (command-line tools)
- Fazer o build do projeto web (Vite)
- Sincronizar os arquivos com o Capacitor
- Gerar o APK com o Gradle

**4. Instale o APK**
Após a conclusão, o APK estará em:
```
android/app/build/outputs/apk/debug/app-debug.apk
```

Copie para um local acessível e instale:
```bash
cp android/app/build/outputs/apk/debug/app-debug.apk ~/storage/downloads/focus.apk
```
> Execute `termux-setup-storage` antes, se necessário, para ter acesso ao armazenamento.

---

## 🖥️ Gerar APK em outros ambientes (Linux/macOS/Windows)

**Pré-requisitos:**
- Node.js 18+
- JDK 17+
- Android SDK (ANDROID_HOME configurado)

```bash
npm install
npm run build:apk
```

O APK de debug será gerado em `android/app/build/outputs/apk/debug/app-debug.apk`.

---

## ✅ Funcionalidades Offline

O aplicativo funciona **100% offline**:
- Todos os dados são armazenados localmente via **IndexedDB**
- O APK inclui todos os assets da web embutidos
- Não requer conexão com internet após instalação

## Recursos

- ⏱️ Temporizador Pomodoro com notificações
- 📚 Repetição espaçada adaptativa
- 📊 Estatísticas e gráficos de estudo
- 🎯 Metas semanais por matéria
- 🏆 Sistema de conquistas e XP
- 📅 Calendário de estudos
- 🌙 Múltiplos temas (Dark, Light, Neon, Elite, Mestre)
- 🌐 4 idiomas: Português, English, Español, Русский
