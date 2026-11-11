---
title: Running a Spring Boot JAR on Docker with Amazon Corretto
categories: docker spring
tags: [spring-boot, docker, java]
---

Some articles suggest using a CentOS base image to run a Spring Boot application in Docker. Since CentOS is deprecated, [Amazon Corretto](https://hub.docker.com/_/amazoncorretto) provides a clean, supported OpenJDK alternative.

Here is a quick reference for packaging and running a Spring Boot JAR with Amazon Corretto 20.

## Dockerfile

```dockerfile
FROM amazoncorretto:20

VOLUME [ "/data" ]
ADD MySpringBootApp-0.0.1-SNAPSHOT.jar MySpringBootApp
RUN sh -c 'touch /ValidatingFormInput.jar'
ENTRYPOINT [ "java", "-jar", "/MySpringBootApp" ]
```

### Line-by-Line Breakdown

- `FROM amazoncorretto:20`: Uses the official Amazon Corretto 20 image as the Java runtime environment.
- `VOLUME [ "/data" ]`: Mounts `/data` as an external volume for application data or logs.
- `ADD MySpringBootApp-0.0.1-SNAPSHOT.jar MySpringBootApp`: Copies the packaged JAR file into the container image.
- `RUN sh -c 'touch /ValidatingFormInput.jar'`: Updates the file modification timestamp for the application artifact.
- `ENTRYPOINT [ "java", "-jar", "/MySpringBootApp" ]`: Specifies the command executed when the container starts.

## Build the Docker Image

Build the container image from the directory containing the `Dockerfile`:

```bash
$ docker build -t myspringbootapp .
```

> **Note:** The Docker image name must be all lowercase. Using uppercase characters (like `MySpringBootApp`) will cause Docker to reject the tag name.

## Run the Container

Run the container, mapping port `8080`:

```bash
$ docker run -p 8080:8080 myspringbootapp
```

The application starts up in under a second:

```text
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.1.1)

INFO 1 --- [main] c.e.demo.MySpringBootAppApplication     : Starting MySpringBootAppApplication v0.0.1-SNAPSHOT using Java 20.0.2...
INFO 1 --- [main] o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port(s): 8080 (http) with context path ''
INFO 1 --- [main] c.e.demo.MySpringBootAppApplication     : Started MySpringBootAppApplication in 0.942 seconds
```
