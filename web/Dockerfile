FROM node:22-alpine AS build
WORKDIR /app
ARG VITE_PUBLIC_BASE=/
ENV VITE_PUBLIC_BASE=$VITE_PUBLIC_BASE

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build:vercel

FROM nginx:1.29-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
