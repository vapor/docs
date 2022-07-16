FROM alpine:3.14

RUN apk update && apk add py3-pip

COPY requirements.txt .

RUN pip install -r requirements.txt

WORKDIR /docs

EXPOSE 8000

CMD [ "mkdocs","serve","-a","0.0.0.0:8000"]

