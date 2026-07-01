package com.halohub.frankenstein.aspect;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;

@Aspect
@Component
@Slf4j
public class ResponseTimeAspect {

    @Around("@annotation(com.halohub.frankenstein.annotation.ResponseTime)")
    public Object logResponseTime(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();
        Object result = joinPoint.proceed();
        long timeTaken = System.currentTimeMillis() - startTime;
        String methodName = joinPoint.getSignature().toShortString();
        log.info("Method: {} executed in {} ms", methodName, timeTaken);
        return result;
    }
}
