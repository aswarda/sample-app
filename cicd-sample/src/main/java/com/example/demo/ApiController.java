package com.example.demo;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ApiController {

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
            "status", "UP",
            "service", "cicd-sample",
            "version", "1.0.0",
            "timestamp", Instant.now().toString()
        );
    }

    @GetMapping("/hello")
    public Map<String, String> hello() {
        return Map.of("message", "Hello from Spring Boot CI/CD sample");
    }

    @GetMapping("/items")
    public List<Map<String, Object>> items() {
        return List.of(
            Map.of("id", 1, "name", "Item One"),
            Map.of("id", 2, "name", "Item Two")
        );
    }
}
