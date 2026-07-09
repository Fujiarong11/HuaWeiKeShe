-- ============================================================
-- 校园问答互助平台 - 数据库初始化脚本
-- ============================================================

CREATE DATABASE IF NOT EXISTS campus_qa
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE campus_qa;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY COMMENT '用户ID（雪花算法）',
    phone VARCHAR(11) NOT NULL UNIQUE COMMENT '手机号',
    username VARCHAR(50) NOT NULL COMMENT '用户名',
    password VARCHAR(255) NOT NULL COMMENT '密码（BCrypt加密）',
    name VARCHAR(50) DEFAULT '' COMMENT '昵称',
    avatar VARCHAR(500) DEFAULT '' COMMENT '头像URL',
    bio VARCHAR(500) DEFAULT '' COMMENT '个人简介',
    college VARCHAR(100) DEFAULT '' COMMENT '学院',
    major VARCHAR(100) DEFAULT '' COMMENT '专业',
    grade VARCHAR(20) DEFAULT '' COMMENT '年级',
    reputation INT DEFAULT 0 COMMENT '声望值',
    accepted_count INT DEFAULT 0 COMMENT '被采纳次数',
    total_answers INT DEFAULT 0 COMMENT '总回答数',
    total_questions INT DEFAULT 0 COMMENT '总提问数',
    follower_count INT DEFAULT 0 COMMENT '粉丝数',
    following_count INT DEFAULT 0 COMMENT '关注数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';
