FROM python:3.12-slim

# Установка системных зависимостей (требуется root)
RUN apt-get update && apt-get install -y \
    git curl wget build-essential \
    && rm -rf /var/lib/apt/lists/*

# Установка Node.js и Claude Code CLI (требуется root)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs
RUN npm install -g @anthropic-ai/claude-code

# Создаём непривилегированного пользователя
RUN useradd -m -u 1000 appuser

# Устанавливаем рабочую директорию и права на неё
WORKDIR /app
RUN chown -R appuser:appuser /app

# Копируем файлы проекта (от root, но потом передадим права)
COPY . .

# Устанавливаем uv через pip (от root, так как устанавливается в систему)
RUN pip install uv

# Устанавливаем зависимости проекта (от root, но внутри виртуального окружения)
RUN uv sync --frozen

# Создаём папку vault и задаём права для appuser
RUN mkdir -p /app/vault && chown -R appuser:appuser /app/vault

# Папка для конфигурации Claude CLI
RUN mkdir -p /root/.config/claude && chown -R appuser:appuser /root/.config/claude

# Переключаемся на непривилегированного пользователя
USER appuser

# Том для заметок (будет монтироваться с хоста)
VOLUME ["/app/vault"]
VOLUME ["/root/.config/claude"]

# Команда запуска (от appuser)
CMD ["uv", "run", "python", "-m", "src.d_brain"]
