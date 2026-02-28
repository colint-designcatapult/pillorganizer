package jct.pillorganizer.tenant.service;

import com.github.ksuid.Ksuid;
import jakarta.inject.Singleton;

@Singleton
public class KsuidService {

    public String generateKsuid() {
        return Ksuid.newKsuid().toString();
    }

}
