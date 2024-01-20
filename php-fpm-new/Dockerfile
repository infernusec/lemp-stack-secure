ARG IMAGE_TAG=9.3.20231119
FROM rockylinux:${IMAGE_TAG}
USER root
RUN dnf update -y; dnf upgrade -y; dnf makecache -y; dnf install -y epel-release; dnf config-manager --set-enabled crb; dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.3.rpm
WORKDIR /tmp/build
COPY ./build.sh /tmp/build/
RUN chmod +x /tmp/build/build.sh
RUN /tmp/build/build.sh