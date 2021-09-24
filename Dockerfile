FROM centos:7

RUN yum install -y epel-release centos-release-scl && \
    yum install -y wget p7zip devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9
