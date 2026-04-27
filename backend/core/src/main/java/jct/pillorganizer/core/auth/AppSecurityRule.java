package jct.pillorganizer.core.auth;

public class AppSecurityRule {
    public static final String IS_USER = "isUser()";
    public static final String IS_ADMIN = "isAdmin()";
    public static final String IS_GLOBAL_ADMIN = "admin-global";
    public static final String IS_TENANT_ADMIN = "isTenantAdmin()";

    public static String isTenantAdmin(String tenantId) {
        return "admin-tenant-" + tenantId;
    }
}
