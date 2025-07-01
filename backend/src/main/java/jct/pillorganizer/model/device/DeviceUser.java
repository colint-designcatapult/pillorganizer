package jct.pillorganizer.model.device;

import jct.pillorganizer.model.user.BaseUser;
import lombok.Getter;
import lombok.Setter;
import javax.persistence.*;

/**
 * Relates a `BaseUser` to a `Device`. The role the user has to a device is recorded here, whether they are the
 * designated primary user of the device, etc. The notification token for push notification delivery is also stored
 * here. Thus, push notification delivery is routed on a per-device per-user basis.
 * 
 * Note: This entity has a partial unique constraint created via database migration:
 * UNIQUE INDEX device_user_unique_not_deleted ON device_user (device_id, user_id) WHERE deleted = false
 * This allows the same device_id + user_id combination to exist multiple times as long as only one has deleted = false.
 * 
 * TODO: move notification token to another entity to resolve notification counter-intuitiveness
 */
@Entity(name = "device_user")
@Table(name = "device_user")
@Getter
@Setter
public class DeviceUser {

    @Id
    @GeneratedValue(strategy= GenerationType.SEQUENCE, generator="device_user_seq")
    @SequenceGenerator(name = "device_user_seq", sequenceName = "device_user_seq", allocationSize = 1)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "device_id", referencedColumnName = "id", insertable = false, updatable = false)
    private Device device;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "id", insertable = false, updatable = false)
    private BaseUser user;

    @Column(name = "user_id")
    private long userID;

    @Column(name = "device_id")
    private long deviceID;

    @Column(name = "primary_user")
    private boolean primaryUser;

    @Column(name = "owner")
    private boolean owner;

    @Column(name = "notification_token")
    private String notificationToken;

    @Column(name = "deleted")
    private boolean deleted = false;


}
