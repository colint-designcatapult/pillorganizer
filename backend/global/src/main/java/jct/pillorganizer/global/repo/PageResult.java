package jct.pillorganizer.global.repo;

import io.micronaut.core.annotation.Nullable;

import java.util.List;

/**
 * A single page of DynamoDB query/scan results with an optional cursor to fetch the next page.
 * A null {@code nextCursor} indicates there are no more results.
 */
public record PageResult<T>(List<T> items, @Nullable String nextCursor) {}
