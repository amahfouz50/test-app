# =============================================================================
# Dockerfile — SHMS Test App (Production Runtime)
# Base   : eclipse-temurin:21-jre-alpine (lightweight production JRE)
# Pattern: Build artifact in CI pipeline, package minimal runtime container
# =============================================================================

FROM eclipse-temurin:21-jre-alpine AS runtime

LABEL maintainer="SHMS DevOps Team" \
      description="SHMS Test App — Spring Boot 4.1.2 / Java 21" \
      version="1.0.0"

# Create unprivileged user for security
RUN addgroup -S shms && adduser -S shms -G shms

WORKDIR /app

# Copy the pre-built, tested JAR produced by CI pipeline
COPY target/test-app-1.0.0.jar app.jar

# Set ownership to unprivileged user
RUN chown shms:shms app.jar

USER shms

# Application port
EXPOSE 7012

# Container-level health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget -qO- http://localhost:7012/actuator/health || exit 1

# Launch application
ENTRYPOINT ["java", "-jar", "-Djava.security.egd=file:/dev/./urandom", "app.jar"]
