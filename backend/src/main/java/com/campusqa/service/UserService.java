package com.campusqa.service;

import com.campusqa.common.ApiResult;
import com.campusqa.dto.LoginRequest;
import com.campusqa.dto.RegisterRequest;
import com.campusqa.dto.UserResponse;

/**
 * 用户服务接口
 */
public interface UserService {

    /**
     * 注册新用户
     */
    ApiResult<UserResponse> register(RegisterRequest request);

    /**
     * 手机号 + 密码登录
     */
    ApiResult<UserResponse> login(LoginRequest request);

    /**
     * 根据手机号查询用户
     */
    ApiResult<UserResponse> getUserByPhone(String phone);
}
