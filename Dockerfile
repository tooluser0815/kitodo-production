# Multi-stage build für Kitodo Production
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build
COPY . .
RUN mvn clean package -DskipTests -Dmaven.test.skip=true

# Runtime Image - Tomcat mit Java
FROM tomcat:9.0-jre17-temurin-jammy

# Kopiere gebaute WAR-Datei
COPY --from=builder /build/Kitodo/target/kitodo*.war /usr/local/tomcat/webapps/ROOT.war

# Erstelle Kitodo-Datenverzeichnis
RUN mkdir -p /opt/kitodo

# Exponiere Port
EXPOSE 8080

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Starte Tomcat (Standard-Entrypoint)
CMD ["catalina.sh", "run"]
