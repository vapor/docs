FROM swift:5.10

RUN apt-get update && apt-get install -y python3-pip

COPY requirements.txt .

RUN pip3 install -r requirements.txt

WORKDIR /docs

COPY . .

RUN mkdocs build
RUN swift fixSearchIndex.swift
RUN cp googlefc012e5d94cfa05f.html site/googlefc012e5d94cfa05f.html;
RUN swift setUpRedirects.swift

EXPOSE 8000

CMD [ "mkdocs","serve","-a","0.0.0.0:8000"]

