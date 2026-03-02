package jct.pillorganizer.tenant.function;

import com.amazonaws.services.lambda.runtime.events.SQSBatchResponse;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import io.micronaut.context.ApplicationContext;
import io.micronaut.function.aws.MicronautRequestHandler;
import io.micronaut.serde.ObjectMapper;
import jakarta.inject.Inject;
import jct.pillorganizer.core.message.BaseMessage;
import jct.pillorganizer.tenant.service.QueueProcessorService;
import lombok.extern.flogger.Flogger;

import java.util.ArrayList;
import java.util.List;

@Flogger
public class TenantQueueProcessor extends MicronautRequestHandler<SQSEvent, SQSBatchResponse> {
    @Inject
    ObjectMapper mapper;

    @Inject
    QueueProcessorService queueProcessorService;

    public TenantQueueProcessor() {
        // Empty ctor for lambda
    }

    @Inject
    public TenantQueueProcessor(ApplicationContext context, QueueProcessorService queueProcessorService) {
        super(context);
        this.mapper = context.getBean(ObjectMapper.class);
        this.queueProcessorService = queueProcessorService;
    }

    @Override
    public SQSBatchResponse execute(SQSEvent input) {
        List<SQSBatchResponse.BatchItemFailure> batchItemFailures = new ArrayList<>();

        for (SQSEvent.SQSMessage message : input.getRecords()) {
            try {
                // Attempt to process
                BaseMessage baseMessage = this.mapper.readValue(message.getBody(), BaseMessage.class);
                this.queueProcessorService.processQueueMessage(baseMessage);

            } catch (Exception e) {
                log.atInfo().withCause(e).log("Could not process message: %s", message.getBody());
                // Add the message ID to the failure list
                batchItemFailures.add(new SQSBatchResponse.BatchItemFailure(message.getMessageId()));
            }
        }

        // AWS deletes successful messages and keeps these failed ones in the queue
        return new SQSBatchResponse(batchItemFailures);
    }
}
