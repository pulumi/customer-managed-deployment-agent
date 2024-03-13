FROM --platform=$BUILDPLATFORM alpine:3.18 as buildenv

RUN apk add curl 

ENV HOME /home/builder

RUN curl -fsSL https://raw.githubusercontent.com/pulumi/customer-managed-deployment-agent/main/install.sh | sh

FROM alpine:3.18


ENV PATH="${PATH}:/usr/local/bin/customer-managed-deployment-agent"

COPY --from=buildenv /home/builder/.pulumi/bin/customer-managed-deployment-agent /usr/local/bin/customer-managed-deployment-agent

CMD [ "customer-managed-deployment-agent", "run"]