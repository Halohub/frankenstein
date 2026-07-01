package com.halohub.frankenstein.aspect;

import com.halohub.frankenstein.annotation.RateLimit;
import com.halohub.frankenstein.common.exception.RateLimitException;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.concurrent.TimeUnit;

@Aspect
@Component
@ConditionalOnBean(RedisTemplate.class)
public class RateLimitAspect {

    private final RedisTemplate<String, String> redisTemplate;

    public RateLimitAspect(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Around("@annotation(rateLimit)")
    public Object rateLimit(ProceedingJoinPoint point, RateLimit rateLimit) throws Throwable {
        String key = rateLimit.key();
        if (!StringUtils.hasText(key)) {
            key = point.getSignature().toLongString();
        }
        String count = redisTemplate.opsForValue().get(key);
        if (count == null) {
            redisTemplate.opsForValue().set(key, "1", rateLimit.period(), TimeUnit.SECONDS);
            return point.proceed();
        }
        if (Integer.parseInt(count) >= rateLimit.limit()) {
            throw new RateLimitException(rateLimit.message());
        }
        redisTemplate.opsForValue().increment(key);
        return point.proceed();
    }
}
