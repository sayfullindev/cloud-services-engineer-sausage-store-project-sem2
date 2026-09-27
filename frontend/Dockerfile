FROM node:16-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build -- --prod

FROM nginx:1.27-alpine

COPY --from=builder /usr/src/app/dist/frontend/ /usr/share/nginx/html

EXPOSE 80 