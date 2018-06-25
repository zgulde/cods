package com.zgulde.helloworld;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@SpringBootApplication
@Controller
public class HelloworldApplication {

  @Value("${message}")
  private String message;

  public static void main(String[] args) {
    SpringApplication.run(HelloworldApplication.class, args);
  }

  @ResponseBody
  @GetMapping("/")
  public String hello() {
    return message;
  }
}
