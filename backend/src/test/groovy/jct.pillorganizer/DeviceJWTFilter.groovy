package jct.pillorganizer

import io.micronaut.http.HttpResponse
import io.micronaut.http.MutableHttpRequest
import io.micronaut.http.annotation.Filter
import io.micronaut.http.filter.ClientFilterChain
import io.micronaut.http.filter.HttpClientFilter
import jakarta.inject.Singleton
import org.reactivestreams.Publisher

@Filter("/api/v1_2/device/**")
@Singleton
class DeviceJWTFilter implements HttpClientFilter {

    def creds = null

    void setCreds(def creds) {
        this.creds = creds
    }

    @Override
    Publisher<? extends HttpResponse<?>> doFilter(MutableHttpRequest<?> request, ClientFilterChain chain) {
        if(creds == null) {
            return chain.proceed(request)
        } else {
            return chain.proceed(request.bearerAuth(creds))
        }
    }
}
