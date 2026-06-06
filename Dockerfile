# Build the static site with Kiln, then serve it with nginx.
FROM swift:6.3 AS build
WORKDIR /docs
COPY . .
# Generates ./site (and copies the Google verification file into it).
RUN swift run VaporDocs

FROM nginx:1.27-alpine
COPY --from=build /docs/site /usr/share/nginx/html
EXPOSE 80
