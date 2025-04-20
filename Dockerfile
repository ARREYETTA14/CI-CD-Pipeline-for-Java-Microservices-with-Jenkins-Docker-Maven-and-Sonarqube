# Use a base image with OpenJDK
FROM openjdk:11-jre-slim

# Set working directory inside container
WORKDIR /app

# Copy the built JAR file from Maven's target folder
COPY target/hello-world-1.0-SNAPSHOT.jar /app/hello-world.jar

# Set the command to run your Java application
ENTRYPOINT ["java", "-jar", "hello-world.jar"]
