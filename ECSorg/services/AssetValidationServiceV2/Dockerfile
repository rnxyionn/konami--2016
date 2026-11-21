FROM golang:1.18-alpine AS build

WORKDIR /src
COPY AssetValidationServiceV2/go.mod AssetValidationServiceV2/go.sum ./
RUN go mod download
COPY AssetValidationServiceV2/ ./
RUN CGO_ENABLED=0 go build -trimpath -o /out/asset-validator .

FROM alpine:3.20
COPY --from=build /out/asset-validator /usr/local/bin/asset-validator
EXPOSE 4300
ENTRYPOINT ["/usr/local/bin/asset-validator"]