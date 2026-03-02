package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.ParameterExpression;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.device.ProvisionRecord;
import jct.pillorganizer.tenant.model.user.BaseUser;
import jct.pillorganizer.tenant.model.user.User;

import java.util.List;
import java.util.Optional;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface ProvisionRecordRepository extends CrudRepository<ProvisionRecord, String> {
    List<ProvisionRecord> findByProvisionedByAndLogicalDeviceIsNull(User user);
    Optional<ProvisionRecord> findByProvisionedByAndClaimToken(User user, String claimToken);
    List<ProvisionRecord> findAllByLogicalDevice(LogicalDevice logicalDevice);

    @Query("UPDATE provision_record r SET disabled_at = CURRENT_TIMESTAMP " +
            "WHERE r.logical_device_id = :logicalDeviceId AND r.disabled_at IS NULL AND r.device_id != :recordId")
    @ParameterExpression(name = "logicalDeviceId", expression = "#{activeRecord.logicalDevice.id}")
    @ParameterExpression(name = "recordId", expression = "#{activeRecord.deviceId}")
    void disableAllForDeviceExcept(ProvisionRecord activeRecord);
}
