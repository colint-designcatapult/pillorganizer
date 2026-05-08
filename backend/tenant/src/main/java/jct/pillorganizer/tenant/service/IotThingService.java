package jct.pillorganizer.tenant.service;

/**
 * Manages AWS IoT Core Thing lifecycle operations.
 */
public interface IotThingService {

    /**
     * Deletes the IoT Thing with the given name from AWS IoT Core.
     */
    void deleteThing(String thingName);
}
