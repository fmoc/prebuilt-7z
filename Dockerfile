FROM centos:7

RUN yum update -y && \
    yum install -y epel-release centos-release-scl && \
    yum install -y wget p7zip devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11
