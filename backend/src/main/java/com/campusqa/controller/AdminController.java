package com.campusqa.controller;

import com.campusqa.common.ApiResult;
import com.campusqa.entity.User;
import com.campusqa.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理员接口
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final UserMapper userMapper;

    /** 管理员密码，可在 application.yml 中配置 */
    @Value("${admin.password:admin123}")
    private String adminPassword;

    /**
     * 管理员登录校验
     * POST /api/admin/login
     */
    @PostMapping("/login")
    public ApiResult<Map<String, String>> login(@RequestBody Map<String, String> body) {
        String password = body.getOrDefault("password", "");
        if (adminPassword.equals(password)) {
            Map<String, String> result = new HashMap<>();
            result.put("token", "admin-session");
            return ApiResult.success(result);
        }
        return ApiResult.error("密码错误");
    }

    /**
     * 获取所有用户列表
     * GET /api/admin/users
     */
    @GetMapping("/users")
    public ApiResult<List<User>> getUsers() {
        List<User> users = userMapper.selectList(null);
        // 隐藏密码
        users.forEach(u -> u.setPassword(null));
        return ApiResult.success(users);
    }

    /**
     * 删除用户
     * DELETE /api/admin/users/{id}
     */
    @DeleteMapping("/users/{id}")
    public ApiResult<Void> deleteUser(@PathVariable Long id) {
        int rows = userMapper.deleteById(id);
        if (rows > 0) {
            return ApiResult.success();
        }
        return ApiResult.error("删除失败，用户不存在");
    }

    /**
     * 获取统计数据
     * GET /api/admin/stats
     */
    @GetMapping("/stats")
    public ApiResult<Map<String, Object>> getStats() {
        List<User> users = userMapper.selectList(null);
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", users.size());
        stats.put("totalQuestions", users.stream().mapToInt(u -> u.getTotalQuestions() != null ? u.getTotalQuestions() : 0).sum());
        stats.put("totalAnswers", users.stream().mapToInt(u -> u.getTotalAnswers() != null ? u.getTotalAnswers() : 0).sum());
        return ApiResult.success(stats);
    }
}
