FROM composer as build-couscous

RUN curl -OS http://couscous.io/couscous.phar
RUN chmod +x couscous.phar
RUN mv couscous.phar /usr/local/bin/couscous

COPY . /app
WORKDIR /app
RUN cd 1.5 && couscous generate

FROM python:alpine as build-stage

# Set up workspace and install mkdocs and dependencies.
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt && rm -rf $HOME/.cache/pip

RUN cd leaf-pygment && ./compile.sh
RUN pip install leaf-pygment/dist/leaf-0.1.0-dev.tar.gz
RUN cd 3.0 && mkdocs build
RUN cd 2.0 && mkdocs build

FROM nginx:1.13.12-alpine as production-stage

COPY --from=build-stage /app/3.0/site/ /usr/share/nginx/html/3.0
COPY --from=build-stage /app/2.0/site/ /usr/share/nginx/html/2.0
COPY --from=build-couscous /app/1.5/.couscous/generated /usr/share/nginx/html/1.5

RUN echo "<meta http-equiv=\"refresh\" content=\"0; url=/3.0/\">" > /usr/share/nginx/html/index.html;
RUN chown -R nginx:nginx /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]