FROM rabbitmq:3.12
RUN rabbitmq-plugins enable --offline rabbitmq_mqtt rabbitmq_web_mqtt rabbitmq_auth_backend_oauth2

COPY --chown=rabbitmq:rabbitmq rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
VOLUME /var/lib/rabbitmq/mnesia/data
EXPOSE 1883/tcp
EXPOSE 15675/tcp