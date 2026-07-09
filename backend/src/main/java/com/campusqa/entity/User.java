package com.campusqa.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户实体 - 对应 campus_qa 数据库 users 表
 */
@Data
@TableName("users")
public class User {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 手机号（唯一，用于登录） */
    private String phone;

    /** 用户名 */
    private String username;

    /** 密码（BCrypt 加密存储） */
    private String password;

    /** 昵称 */
    private String name;

    /** 头像 URL */
    private String avatar;

    /** 个人简介 */
    private String bio;

    /** 学院 */
    private String college;

    /** 专业 */
    private String major;

    /** 年级 */
    private String grade;

    /** 声望值 */
    private Integer reputation;

    /** 被采纳次数 */
    private Integer acceptedCount;

    /** 总回答数 */
    private Integer totalAnswers;

    /** 总提问数 */
    private Integer totalQuestions;

    /** 粉丝数 */
    private Integer followerCount;

    /** 关注数 */
    private Integer followingCount;

    /** 创建时间 */
    private LocalDateTime createdAt;
}
