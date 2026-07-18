# ---- build (Flutter Web) ----
# Imagem da comunidade com o SDK do Flutter já instalado.
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# API na mesma origem (o nginx faz proxy de /api). Origem relativa evita CORS.
RUN flutter build web --release --dart-define=API_URL=/api

# ---- runtime (nginx) ----
FROM nginx:alpine AS final
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
