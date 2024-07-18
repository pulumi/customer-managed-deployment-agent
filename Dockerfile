FROM alpine:3.18

ENV PATH="${PATH}:/usr/local/bin"

ARG AGENTBINARY
ARG RUNNERBINARY

COPY ${AGENTBINARY} /usr/local/bin/customer-managed-deployment-agent
COPY ${RUNNERBINARY} /usr/local/bin/workflow-runner

RUN chmod +x /usr/local/bin/customer-managed-deployment-agent /usr/local/bin/workflow-runner

CMD [ "customer-managed-deployment-agent", "run"]
