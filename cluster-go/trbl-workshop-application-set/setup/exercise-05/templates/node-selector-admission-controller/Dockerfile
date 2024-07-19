FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY . .
RUN go build -o node-selector-admission-controller main.go

FROM alpine:latest

COPY --from=builder /app/node-selector-admission-controller /opt/

RUN chgrp -R root /opt/ && \
    chmod -R 770 /opt/

COPY main.go /main.go

USER 10001


#CMD ["sleep", "9990"]
CMD ["/opt/node-selector-admission-controller"]
