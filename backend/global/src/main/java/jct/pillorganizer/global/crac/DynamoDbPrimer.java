package jct.pillorganizer.global.crac;

import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.DeviceRepo;
import jct.pillorganizer.global.repo.UserRepo;
import lombok.extern.flogger.Flogger;
import org.crac.Context;
import org.crac.Resource;

import java.util.Optional;

@Flogger
@Singleton
@Requires(env = "lambda")
public class DynamoDbPrimer implements OrderedResource {

    private final DeviceRepo deviceRepo;
    private final UserRepo userRepo;

    @Inject
    public DynamoDbPrimer(DeviceRepo deviceRepo, UserRepo userRepo) {
        this.deviceRepo = deviceRepo;
        this.userRepo = userRepo;
    }

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        try {
            Optional<DeviceEntity> device = deviceRepo.findBySerialNumber("SN-DOES-NOT-EXIST");
            Optional<UserEntity> user = this.userRepo.findBySub("USER-DOES-NOT-EXIST");
            log.atInfo().log("DynamoDB primed: %s %s", device.toString(), user.toString());
        } catch (Exception e) {
            log.atInfo().withCause(e).log("Exception during DynamoDB priming");
        }
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {

    }
}
