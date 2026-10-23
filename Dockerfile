# =============================================================================
# Dockerfile — SHMS Test App
# Build  : maven:3.9-eclipse-temurin-21-alpine (Maven build stage)
# Runtime: eclipse-temurin:21-jre-alpine (slim production image)
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: BUILD — uses official Maven image (no mvnw needed)
# ---------------------------------------------------------------------------
FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /build

# Copy pom first for layer caching — only re-downloads deps on pom change
COPY pom.xml ./

# Download dependencies (cached layer unless pom.xml changes)
RUN mvn dependency:go-offline -B --no-transfer-progress

# Copy source code
COPY src ./src

# Build the JAR (skip tests — tests run in CI pipeline)
RUN mvn clean package -DskipTests -B --no-transfer-progress

# ---------------------------------------------------------------------------
# Stage 2: RUNTIME (slim image)
# ---------------------------------------------------------------------------
FROM eclipse-temurin:21-jre-alpine AS runtime

LABEL maintainer="SHMS DevOps Team" \
      description="SHMS Test App — Spring Boot 4.1.2 / Java 21" \
      version="1.0.0"

# Create non-root user for security
RUN addgroup -S shms && adduser -S shms -G shms

WORKDIR /app

# Copy only the built JAR from builder stage
COPY --from=builder /build/target/test-app-1.0.0.jar app.jar

# Change ownership to non-root user
RUN chown shms:shms app.jar

USER shms

# Application port
EXPOSE 7012

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget -qO- http://localhost:7012/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "-Djava.security.egd=file:/dev/./urandom", "app.jar"]
