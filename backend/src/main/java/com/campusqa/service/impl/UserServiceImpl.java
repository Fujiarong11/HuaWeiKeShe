package com.campusqa.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campusqa.common.ApiResult;
import com.campusqa.dto.LoginRequest;
import com.campusqa.dto.RegisterRequest;
import com.campusqa.dto.UserResponse;
import com.campusqa.entity.User;
import com.campusqa.mapper.UserMapper;
import com.campusqa.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 用户服务实现
 */
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Override
    public ApiResult<UserResponse> register(RegisterRequest request) {
        // 1. 检查手机号是否已注册
        LambdaQueryWrapper<User> query = new LambdaQueryWrapper<>();
        query.eq(User::getPhone, request.getPhone());
        if (userMapper.selectCount(query) > 0) {
            return ApiResult.error("该手机号已被注册");
        }

        // 2. 创建用户
        User user = new User();
        user.setPhone(request.getPhone());
        user.setUsername(request.getUsername());
        user.setPassword(passwordEncoder.encode(request.getPassword())); // BCrypt 加密
        user.setName(request.getUsername());          // 默认昵称 = 用户名
        user.setAvatar("");
        user.setBio("");
        user.setCollege("");
        user.setMajor("");
        user.setGrade("");
        user.setReputation(0);
        user.setAcceptedCount(0);
        user.setTotalAnswers(0);
        user.setTotalQuestions(0);
        user.setFollowerCount(0);
        user.setFollowingCount(0);
        user.setCreatedAt(LocalDateTime.now());

        userMapper.insert(user);

        // 3. 返回用户信息
        return ApiResult.success(toResponse(user));
    }

    @Override
    public ApiResult<UserResponse> login(LoginRequest request) {
        // 1. 查用户
        LambdaQueryWrapper<User> query = new LambdaQueryWrapper<>();
        query.eq(User::getPhone, request.getPhone());
        User user = userMapper.selectOne(query);

        if (user == null) {
            return ApiResult.error("手机号或密码错误");
        }

        // 2. 验证密码
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            return ApiResult.error("手机号或密码错误");
        }

        // 3. 返回用户信息
        return ApiResult.success(toResponse(user));
    }

    @Override
    public ApiResult<UserResponse> getUserByPhone(String phone) {
        LambdaQueryWrapper<User> query = new LambdaQueryWrapper<>();
        query.eq(User::getPhone, phone);
        User user = userMapper.selectOne(query);

        if (user == null) {
            return ApiResult.error("用户不存在");
        }

        return ApiResult.success(toResponse(user));
    }

    /**
     * Entity → Response DTO
     */
    private UserResponse toResponse(User user) {
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        return UserResponse.builder()
                .id(user.getId())
                .phone(user.getPhone())
                .username(user.getUsername())
                .name(user.getName())
                .avatar(user.getAvatar())
                .bio(user.getBio())
                .college(user.getCollege())
                .major(user.getMajor())
                .grade(user.getGrade())
                .reputation(user.getReputation())
                .acceptedCount(user.getAcceptedCount())
                .totalAnswers(user.getTotalAnswers())
                .totalQuestions(user.getTotalQuestions())
                .followerCount(user.getFollowerCount())
                .followingCount(user.getFollowingCount())
                .createdAt(user.getCreatedAt() != null ? user.getCreatedAt().format(fmt) : "")
                .build();
    }
}
