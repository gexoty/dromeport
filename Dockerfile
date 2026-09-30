# Build Vite frontend
FROM node:20-alpine AS frontend-build

WORKDIR /app/dromeport

COPY dromeport/package.json dromeport/package-lock.json* ./
RUN npm ci

COPY dromeport/ ./
RUN npm run build


# Python backend
FROM python:3.12-slim

# ffmpeg - transcoding (Opus / MP3)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip -o /tmp/deno.zip \
    && unzip /tmp/deno.zip -d /usr/local/bin \
    && rm /tmp/deno.zip \
    && deno --version

WORKDIR /app

COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./

COPY --from=frontend-build /app/dromeport/dist ./static

RUN useradd -m -u 1000 dromeport \
    && chown -R dromeport:dromeport /app
USER dromeport

# Ensure user-local pip-installed scripts (e.g. updated yt-dlp) are on PATH
ENV PATH="/home/dromeport/.local/bin:${PATH}"

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]