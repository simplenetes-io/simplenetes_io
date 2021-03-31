FROM nginx:1.16.1-alpine

COPY build /nginx_content

CMD ["nginx", "-c", "/nginx_content/nginx.conf", "-g", "daemon off;"]
