package com.campusqa;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;

@SpringBootApplication
@MapperScan("com.campusqa.mapper")
public class CampusQaApplication {

    public static void main(String[] args) {
        SpringApplication.run(CampusQaApplication.class, args);
    }

    @Bean
    CommandLineRunner startupBanner(Environment env) {
        return args -> {
            String port = env.getProperty("server.port", "8080");
            System.out.println("\n╔════════════════════════════════════════════════╗");
            System.out.println("║   🎓 校园问答互助平台 - 后端服务启动成功         ║");
            System.out.println("╠════════════════════════════════════════════════╣");
            System.out.println("║   📋 后台管理: http://localhost:" + port + "/admin.html   ║");
            System.out.println("║   📡 API 接口: http://localhost:" + port + "/api/          ║");
            System.out.println("╚════════════════════════════════════════════════╝\n");
        };
    }
}
