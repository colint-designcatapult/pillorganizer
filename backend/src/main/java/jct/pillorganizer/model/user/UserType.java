package jct.pillorganizer.model.user;

/**
 * The purpose of this enumeration was to differentiate between devices (which can login) and regular users. This is
 * a bad idea and must be refactored out.
 * @deprecated
 */
public enum UserType {

    STANDARD,
    DEVICE,
    ANONYMOUS

}
