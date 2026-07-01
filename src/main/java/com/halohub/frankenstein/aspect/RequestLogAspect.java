package com.halohub.frankenstein.aspect;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import com.halohub.frankenstein.common.context.ThreadLocalContext;

import java.util.HashMap;
import java.util.Map;

@Aspect
@Component
@Slf4j
public class RequestLogAspect {

    private static final boolean ENABLED = true;
    private static final boolean LOG_PARAMETERS = true;
    private static final boolean LOG_RESPONSE_TIME = true;
    private static final boolean LOG_CLIENT_IP = true;
    private static final int MAX_PARAMETER_LENGTH = 2000;

    @Around("execution(public * com.halohub.frankenstein.controller..*Controller.*(..))")
    public Object logRequestParams(ProceedingJoinPoint joinPoint) throws Throwable {
        if (!ENABLED) {
            return joinPoint.proceed();
        }
        
        long startTime = System.currentTimeMillis();
        
        try {
            HttpServletRequest request = getCurrentRequest();
            String methodName = joinPoint.getSignature().toShortString();
            String className = joinPoint.getTarget().getClass().getSimpleName();
            Object[] args = joinPoint.getArgs();
            String[] paramNames = getParameterNames(joinPoint);
            Map<String, Object> paramMap = buildParameterMap(paramNames, args);
            log.info("========================== request start ==========================");
            log.info("Controller: {}", className);
            log.info("方法: {}", methodName);
            if (request != null) {
                log.info("URL: {} {}", request.getMethod(), request.getRequestURI());
                if (LOG_CLIENT_IP) {
                    log.info("IP地址: {}", getClientIP(request));
                }
                Long userId = ThreadLocalContext.getCurrentUserId();
                if (userId != null) {
                    log.info("用户ID: {}", userId);
                }
            }
            if (LOG_PARAMETERS) {
                log.info("参数: {}", formatParameters(paramMap));
            }
            Object result = joinPoint.proceed();
            if (LOG_RESPONSE_TIME) {
                long duration = System.currentTimeMillis() - startTime;
                log.info("响应时间: {}ms", duration);
            }
            log.info("========================== request end ==========================");
            
            return result;
            
        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            log.error("========================== request exception ========================== time: {}ms, exception: {}", duration, e.getMessage());
            throw e;
        }
    }

    private HttpServletRequest getCurrentRequest() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            return attributes != null ? attributes.getRequest() : null;
        } catch (Exception e) {
            return null;
        }
    }

    private String[] getParameterNames(ProceedingJoinPoint joinPoint) {
        int paramCount = joinPoint.getArgs().length;
        String[] paramNames = new String[paramCount];
        for (int i = 0; i < paramCount; i++) {
            paramNames[i] = "arg" + i;
        }
        return paramNames;
    }

    private Map<String, Object> buildParameterMap(String[] paramNames, Object[] args) {
        Map<String, Object> paramMap = new HashMap<>();
        for (int i = 0; i < paramNames.length && i < args.length; i++) {
            Object arg = args[i];
            if (arg != null && !isServletObject(arg)) {
                paramMap.put(paramNames[i], processParameterData(arg));
            }
        }
        return paramMap;
    }
    

    private boolean isServletObject(Object obj) {
        String className = obj.getClass().getName();
        return className.contains("javax.servlet") || 
               className.contains("jakarta.servlet") ||
               className.contains("org.springframework.web") ||
               className.contains("org.springframework.ui");
    }
    

    private Object processParameterData(Object obj) {
        if (obj == null) {
            return null;
        }
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            String jsonStr = objectMapper.writeValueAsString(obj);
            if (jsonStr.length() > MAX_PARAMETER_LENGTH) {
                jsonStr = jsonStr.substring(0, MAX_PARAMETER_LENGTH) + "...[cut]";
            }
            return jsonStr;
        } catch (Exception e) {
            return obj.getClass().getSimpleName() + "@" + Integer.toHexString(obj.hashCode());
        }
    }
    

    private String formatParameters(Map<String, Object> paramMap) {
        if (paramMap.isEmpty()) {
            return "no parameter";
        }
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Object> entry : paramMap.entrySet()) {
            if (sb.length() > 0) {
                sb.append(", ");
            }
            sb.append(entry.getKey()).append("=").append(entry.getValue());
        }
        return sb.toString();
    }
    

    private String getClientIP(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("WL-Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("HTTP_CLIENT_IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("HTTP_X_FORWARDED_FOR");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
    }
} 