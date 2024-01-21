---
title: Run a SpringBoot jar on Docker
categories: docker spring
---
Some articles suggest to run a centos docker image to run SpringBoot app. Since CentOS is deprecated, I found that [amazoncorretto](https://hub.docker.com/_/amazoncorretto) is an option.

Dockerfile
```docker
FROM amazoncorretto:20

VOLUME [ "/data" ]
ADD MySpringBootApp-0.0.1-SNAPSHOT.jar MySpringBootApp
RUN sh -c 'touch /ValidatingFormInput.jar'
ENTRYPOINT [ "java", "-jar", "/MySpringBootApp" ]
```

Build Docker image

```
$ docker build -t myspringbootapp .  
```
Note that the Docker image name has to be lower case.

Run the docker container

```bash
$ docker run -p 8080:8080 myspringbootapp

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.1.1)

2023-08-22T00:41:04.306Z  INFO 1 --- [           main] i.s.s.V.MySpringBootAppApplication   : Starting MySpringBootAppApplication v0.0.1-SNAPSHOT using Java 20.0.2 with PID 1 (/MySpringBootAppApplication.jar started by root in /)
2023-08-22T00:41:04.307Z  INFO 1 --- [           main] i.s.s.V.MySpringBootAppApplication   : No active profile set, falling back to 1 default profile: "default"
2023-08-22T00:41:04.800Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port(s): 8080 (http)
2023-08-22T00:41:04.805Z  INFO 1 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2023-08-22T00:41:04.805Z  INFO 1 --- [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.10]
2023-08-22T00:41:04.838Z  INFO 1 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2023-08-22T00:41:04.838Z  INFO 1 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 505 ms
2023-08-22T00:41:05.006Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2023-08-22T00:41:05.013Z  INFO 1 --- [           main] i.s.s.V.MySpringBootAppApplication   : Started MySpringBootAppApplication in 0.942 seconds (process running for 1.172)
2023-08-22T00:41:18.153Z  INFO 1 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2023-08-22T00:41:18.153Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2023-08-22T00:41:18.154Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms

```
