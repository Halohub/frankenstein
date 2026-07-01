package com.halohub.frankenstein.common.context;

import com.halohub.frankenstein.pojo.UserInfoContextBo;

/**
 * Request-scoped ThreadLocal holder for user identity and other per-request state.
 */
public final class ThreadLocalContext {

    public static ThreadLocal<UserInfoContextBo> threadLocal = new ThreadLocal<>();

    public static void setThreadLocal(UserInfoContextBo userInfoContextBo) {
        threadLocal.set(userInfoContextBo);
    }

    public static UserInfoContextBo getUserInfoContextBo(){
        return threadLocal.get();
    }

    public static void remove(){
        threadLocal.remove();
    }

    public static Long getCurrentUserId(){
        UserInfoContextBo userInfoContextBo = threadLocal.get();
        return userInfoContextBo!= null? userInfoContextBo.getUserId() : null;
    }

}
