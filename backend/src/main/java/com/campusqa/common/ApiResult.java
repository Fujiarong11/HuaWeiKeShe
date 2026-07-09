package com.campusqa.common;

import lombok.Data;

/**
 * 统一 API 返回结果
 */
@Data
public class ApiResult<T> {

    /** 状态码：0 成功，-1 失败 */
    private int code;

    /** 提示信息 */
    private String msg;

    /** 返回数据 */
    private T data;

    private ApiResult(int code, String msg, T data) {
        this.code = code;
        this.msg = msg;
        this.data = data;
    }

    public static <T> ApiResult<T> success(T data) {
        return new ApiResult<>(0, "success", data);
    }

    public static <T> ApiResult<T> success() {
        return new ApiResult<>(0, "success", null);
    }

    public static <T> ApiResult<T> error(String msg) {
        return new ApiResult<>(-1, msg, null);
    }
}
