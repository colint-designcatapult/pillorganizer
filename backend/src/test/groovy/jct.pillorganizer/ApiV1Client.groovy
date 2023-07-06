package jct.pillorganizer


import io.micronaut.http.annotation.*
import io.micronaut.http.client.annotation.Client
import jct.pillorganizer.dto.*
import jct.pillorganizer.model.medication.ScheduledMedication

@Client()
@Headers(
    @Header(name = "X-Local-TZ", value = "America/Detroit")
)
interface ApiV1Client {

    @Post('http://localhost:8080/api/v1/user/register_anonymous')
    def registerAnonymous();

    @Post('http://localhost:8080/api/v1/auth/login_anonymous')
    def loginAnonymous(int id, String secret);

    @Post('http://localhost:8080/api/v1/user/register')
    def register(String email, String password);

    @Post('http://localhost:8080/api/v1/auth/login')
    def login(String username, String password);


    @Post('http://localhost:8080/api/v1/device/provision/start')
    @Header(name = "X-Local-TZ", value = "America/Detroit")
    def provisionStart(String serialNo, String deviceClass);

    @Post('http://localhost:8080/api/v1/device/provision/{id}/verify')
    def checkProvisionStatus(@QueryValue long id, @Body VerifyProvision vp);

    @Get('http://localhost:8080/api/v1/device/list')
    List<DeviceUserDTO> listDevices();

    @Put('http://localhost:8080/api/v1/device/{id}')
    DeviceUserDTO deviceSettings(@QueryValue long id, @Body UpdateDeviceUserSettings body);

    @Get("http://localhost:8080/api/v1/device/{id}/dispense_time")
    SimpleScheduleDTO getDispenseTime(@QueryValue long id);

    @Post("http://localhost:8080/api/v1/device/{id}/dispense_time")
    SimpleScheduleDTO setDispenseTime(@QueryValue long id, @Body SimpleScheduleDTO body);

    @Post("http://localhost:8080/api/v1/device/{id}/medication")
    ScheduledMedication saveMedication(@QueryValue long id, @Body SaveMedicationDTO body);


}
