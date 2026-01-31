package jct.pillorganizer.model.user;

import jakarta.persistence.Transient;

/**
 * Represents something that can act like an authenticated user in the system. This application has a few different
 * classes of users, including devices, users, and anonymous users. Classes that implement this interface signify
 * that the class can be used to authenticate with the system.
 * TODO: refactor this concept to better integrate with BaseUser and authentication subsystem
 */
public interface Authenticatable {

    long getId();
    @Transient
    UserType getUserType();

}
