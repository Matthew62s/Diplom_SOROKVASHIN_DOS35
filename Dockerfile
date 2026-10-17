FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .


FROM alpine:3.22
WORKDIR /app
RUN addgroup -S -g 10001 app \
    && adduser -S -D -H -u 10001 -G app app
COPY --from=builder /app/main ./main
USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1
CMD ["./main"]