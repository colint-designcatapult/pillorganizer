package jct.pillorganizer.tenant.service;

/**
 * Manages AWS IoT Core Thing lifecycle operations.
 */
public interface IotThingService {

    /**
     * Revokes all certificates attached to the given Thing: detaches each principal,
     * deactivates its certificate, then deletes it.
     */
    void revokeAllCerts(String thingName);

    /**
     * Deletes the IoT Thing with the given name from AWS IoT Core.
     */
    void deleteThing(String thingName);
}
