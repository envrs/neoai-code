FROM python:3.7-alpine3.11
COPY go/cmd/server /usr/local/bin/neoai-server
RUN apk add build-base && pip install python-language-server
RUN chmod 755 /usr/local/bin/neoai-server
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/neoai-server", "-libBaseDir=/usr/local/lib", "-port=8080"]
