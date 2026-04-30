package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;

import java.util.List;

@Serdeable.Serializable
public record AdminCognitoUserDto(
        String sub,
        String email,
        String status,
        List<String> groups
) {}
