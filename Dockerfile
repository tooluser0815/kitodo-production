# Multi-stage build für Kitodo Production
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build
# Kopiere ALLE Dateien (nicht nur pom.xml)
COPY . .
RUN mvn clean package -DskipTests -Dmaven.test.skip=true

# Runtime Image
FROM eclipse-temurin:17-jre-jammy

# Installiere alle benötigten Systempakete
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    dos2unix \
    imagemagick \
    ghostscript \
    samba \
    samba-common-bin \
    apache2 \
    apache2-utils \
    libapache2-mod-jk \
    tomcat9 \
    tomcat9-admin \
    tomcat9-common \
    tomcat9-user \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Konfiguriere Apache Module
RUN a2enmod proxy && a2enmod proxy_http && a2enmod rewrite && a2enmod ssl && a2enmod jk

# Setze Tomcat-Umgebung
ENV CATALINA_HOME=/opt/tomcat \
    CATALINA_BASE=/opt/tomcat \
    JAVA_OPTS="-Xmx2g -Xms512m -Dfile.encoding=UTF-8"

# Installiere Tomcat 9
RUN mkdir -p /opt/tomcat && \
    curl -fsSL https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.87/bin/apache-tomcat-9.0.87.tar.gz | \
    tar xz --strip-components=1 -C /opt/tomcat && \
    rm -rf /opt/tomcat/webapps/ROOT /opt/tomcat/webapps/examples /opt/tomcat/webapps/docs

# Kopiere gebaute WAR-Datei
COPY --from=builder /build/Kitodo/target/kitodo*.war /opt/tomcat/webapps/ROOT.war

# Erstelle Kitodo-Datenverzeichnis
RUN mkdir -p /opt/kitodo && chown -R tomcat:tomcat /opt/tomcat /opt/kitodo

# Exponiere Ports
EXPOSE 8080 80 443 445

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/kitodo/ || exit 1

# Starte Tomcat
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
