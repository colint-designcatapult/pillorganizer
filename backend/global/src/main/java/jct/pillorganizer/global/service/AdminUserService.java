package jct.pillorganizer.global.service;

import jct.pillorganizer.global.dto.AdminCognitoUserPageDto;

/**
 * Abstracts access to the Cognito admin user pool so the control-plane
 * stays decoupled from the AWS SDK.
 * A local (mock) implementation is used in development/tests;
 * the real Cognito implementation is active in the {@code global} environment.
 */
public interface AdminUserService {

    /**
     * Returns a page of all users in the admin Cognito user pool.
     *
     * @param paginationToken opaque token from a previous response, or {@code null} for the first page
     * @param limit           maximum number of users to return (1-60)
     * @return page of Cognito users with optional next-page token
     */
    AdminCognitoUserPageDto listUsers(String paginationToken, int limit);

    /**
     * Returns a page of users belonging to a specific Cognito group.
     *
     * @param groupName       name of the Cognito group (e.g. {@code admin-tenant-acme})
     * @param paginationToken opaque token from a previous response, or {@code null} for the first page
     * @param limit           maximum number of users to return (1-60)
     * @return page of Cognito users in the group with optional next-page token
     */
    AdminCognitoUserPageDto listGroupUsers(String groupName, String paginationToken, int limit);
}
