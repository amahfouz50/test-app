package com.shms.testapp.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * TestController — simple endpoints to verify the app is running correctly.
 */
@RestController
@RequestMapping("/api")
public class TestController {

    private static final String APP_NAME    = "SHMS Test App";
    private static final String APP_VERSION = "1.0.0";

    /**
     * GET /api/test
     * Basic liveness check — returns a plain string.
     */
    @GetMapping("/test")
    public ResponseEntity<String> test() {
        return ResponseEntity.ok(
            "✅ %s v%s is up and running! — %s".formatted(
                APP_NAME,
                APP_VERSION,
                LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
            )
        );
    }

    /**
     * GET /api/hello
     * Friendly greeting endpoint.
     */
    @GetMapping("/hello")
    public ResponseEntity<String> hello() {
        return ResponseEntity.ok("👋 Hello from SHMS Test App! Java " + Runtime.version());
    }

    /**
     * GET /api/info
     * Returns basic app info as a JSON-like string.
     */
    @GetMapping("/info")
    public ResponseEntity<String> info() {
        return ResponseEntity.ok("""
            {
              "app"     : "%s",
              "version" : "%s",
              "java"    : "%s",
              "port"    : 7012,
              "status"  : "OK"
            }
            """.formatted(APP_NAME, APP_VERSION, Runtime.version()));
    }

}
