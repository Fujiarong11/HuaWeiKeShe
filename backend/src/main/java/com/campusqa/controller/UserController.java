package com.campusqa.controller;

import com.campusqa.common.ApiResult;
import com.campusqa.dto.LoginRequest;
import com.campusqa.dto.RegisterRequest;
import com.campusqa.dto.UserResponse;
import com.campusqa.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 用户接口 Controller
 */
@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * 注册
     * POST /api/user/register
     */
    @PostMapping("/register")
    public ApiResult<UserResponse> register(@Valid @RequestBody RegisterRequest request) {
        return userService.register(request);
    }

    /**
     * 登录
     * POST /api/user/login
     */
    @PostMapping("/login")
    public ApiResult<UserResponse> login(@Valid @RequestBody LoginRequest request) {
        return userService.login(request);
    }

    /**
     * 根据手机号查询用户
     * GET /api/user/getUser?phone=xxx
     */
    @GetMapping("/getUser")
    public ApiResult<UserResponse> getUser(@RequestParam("phone") String phone) {
        return userService.getUserByPhone(phone);
    }
}
