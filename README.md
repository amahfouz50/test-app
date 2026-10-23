# SHMS Test App

Spring Boot test application with Docker and Docker Compose support.

## Endpoints

- `GET /api/test` - Health check & app information
- `GET /api/hello` - Greeting endpoint
- `GET /api/info` - App info JSON
- `GET /actuator/health` - Actuator health endpoint

## Running Locally

```bash
mvn clean spring-boot:run
```

## Running with Docker Compose

```bash
docker compose up -d --build
```
