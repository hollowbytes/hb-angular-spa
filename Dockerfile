# Multi-stage build to cut down on image sizes
FROM node:24-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build --prod

FROM nginx:alpine

# Fix nonroot user vulnerability
RUN mkdir -p /var/cache/nginx/client_temp && \
        mkdir -p /var/cache/nginx/proxy_temp && \
        mkdir -p /var/cache/nginx/fastcgi_temp && \
        mkdir -p /var/cache/nginx/uwsgi_temp && \
        mkdir -p /var/cache/nginx/scgi_temp && \
        chown -R nginx:nginx /var/cache/nginx && \
        chown -R nginx:nginx /etc/nginx/ && \
        chmod -R 755 /etc/nginx/ && \
        chown -R nginx:nginx /var/log/nginx

RUN mkdir -p /etc/nginx/ssl/ && \
    chown -R nginx:nginx /etc/nginx/ssl/ && \
    chmod -R 755 /etc/nginx/ssl/

RUN touch /var/run/nginx.pid && \
        chown -R nginx:nginx /var/run/nginx.pid /run/nginx.pid

# Swap to root user
USER nginx

COPY --from=build /app/dist/hb-angular-spa/browser /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
