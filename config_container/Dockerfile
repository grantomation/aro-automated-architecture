# podman build -t name:tag -f ./config_container/Dockerfile .

FROM registry.access.redhat.com/ubi8-minimal:latest

LABEL name="aro_config" \
      vendor="none" \
      version="1" \
      release="0" \
      summary="ARO Day 2 configuration" \
      description="This contianer will configure an ARO private cluster"

RUN microdnf install wget tar gzip curl jq && mkdir /data

RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
tar xvf oc.tar.gz -C /bin && \
rm -f /bin/README && \
rm -f oc.tar.gz

RUN wget https://get.helm.sh/helm-v3.10.1-linux-amd64.tar.gz && \
tar xvf helm-v3.10.1-linux-amd64.tar.gz -C /bin linux-amd64/helm --strip-components 1

COPY openshift_operators/* /data/

RUN chmod +x /data/openshift_config.sh

RUN chown -R 1001:0 /data && \
    chmod -R g=u /data

WORKDIR /data

ENV HOME=/data

USER 1001