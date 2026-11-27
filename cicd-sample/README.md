# Spring Boot CI/CD Sample
Run:   mvn spring-boot:run
Test:  curl http://localhost:8080/api/health
Docker: mvn package && docker build -t cicd-sample . && docker run -p 8080:8080 cicd-sample
