package com.campusqa.dto;

import lombok.Builder;
import lombok.Data;

/**
 * 用户信息响应
 */
@Data
@Builder
public class UserResponse {

    private Long id;
    private String phone;
    private String username;
    private String name;
    private String avatar;
    private String bio;
    private String college;
    private String major;
    private String grade;
    private Integer reputation;
    private Integer acceptedCount;
    private Integer totalAnswers;
    private Integer totalQuestions;
    private Integer followerCount;
    private Integer followingCount;
    private String createdAt;
}
