package jct.pillorganizer.global.domain.model;

public record User(
        String userId,
        String email,
        String name,
        long version
) {
}
