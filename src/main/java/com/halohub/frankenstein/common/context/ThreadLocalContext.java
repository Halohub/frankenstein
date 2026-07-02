package com.halohub.frankenstein.common.context;

/**
 * Request-scoped ThreadLocal holder for user identity and other per-request state.
 */
public final class ThreadLocalContext {

    private static final ThreadLocal<Object> HOLDER = new ThreadLocal<>();

    private ThreadLocalContext() {
    }

    @SuppressWarnings("unchecked")
    public static <T> T get() {
        return (T) HOLDER.get();
    }

    public static <T> void set(T value) {
        HOLDER.set(value);
    }

    public static void clear() {
        HOLDER.remove();
    }
}
