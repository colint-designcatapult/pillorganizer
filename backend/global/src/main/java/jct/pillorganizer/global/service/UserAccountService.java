package jct.pillorganizer.global.service;

/**
 * Manages Cognito user account lifecycle for the normal (public) user pool.
 */
public interface UserAccountService {

    /**
     * Deletes a user from the normal Cognito user pool by their subject (sub) identifier.
     */
    void deleteUser(String userSub);
}
