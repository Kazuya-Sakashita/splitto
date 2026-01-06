# frontend/Dockerfile
FROM node:24-bookworm

ENV TZ=UTC \
    NODE_ENV=development \
    NEXT_TELEMETRY_DISABLED=1

WORKDIR /app

# 依存関係を先に入れてキャッシュを効かせる
COPY package*.json ./
RUN npm ci

# アプリ本体
COPY . .

EXPOSE 3000

# ※実際の起動は docker-compose.yml の command で行う想定
CMD ["bash"]
