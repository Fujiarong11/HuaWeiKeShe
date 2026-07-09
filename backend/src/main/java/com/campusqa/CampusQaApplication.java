package com.campusqa;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.campusqa.mapper")
public class CampusQaApplication {

    public static void main(String[] args) {
        SpringApplication.run(CampusQaApplication.class, args);
    }
}
