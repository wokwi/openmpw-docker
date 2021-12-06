# OpenMPW tools for MPW-3 and MPW-4
# Copyright (C) 2021 Uri Shaked
#
# SPDX-FileCopyrightText: © 2021 Uri Shaked <uri@wokwi.com>
# SPDX-License-Identifier: MIT

FROM ubuntu:21.10

LABEL description="OpenMPW tools for MPW-3 and MPW-4"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y git curl wget python3 python3-pip

# Install tools: ngspice, klayout
RUN apt-get install -y ngspice klayout

# Install magic
RUN mkdir /build
WORKDIR /build
RUN apt-get install -y tcsh csh tcl-dev tk-dev libcairo2-dev
RUN git clone git://opencircuitdesign.com/magic
WORKDIR /build/magic
RUN git checkout 8.3.209
RUN ./configure
RUN make
RUN make install
WORKDIR /
RUN rm -rf /build

# Create a user for the Open PDK
RUN useradd -ms /bin/bash openmpw
USER openmpw

# Configure environment
ENV ASICTOOLS_ROOT=/home/openmpw/tools
ENV PDK_ROOT=$ASICTOOLS_ROOT/pdk
ENV OPENLANE_ROOT=$ASICTOOLS_ROOT/openlane
ENV PDK_PATH=$PDK_ROOT/sky130A
ENV SKYWATER_COMMIT=c094b6e83a4f9298e47f696ec5a7fd53535ec5eb
ENV OPEN_PDKS_COMMIT=14db32aa8ba330e88632ff3ad2ff52f4f4dae1ad
ENV OPENLANE_TAG=mpw-3a
ENV OPENLANE_IMAGE_NAME=efabless/openlane:$OPENLANE_TAG
ENV IMAGE_NAME=$OPENLANE_IMAGE_NAME
ENV CARAVEL_ROOT=$ASICTOOLS_ROOT/caravel_user_project/caravel

# Install PDK + OpenLane
RUN mkdir $ASICTOOLS_ROOT
WORKDIR $ASICTOOLS_ROOT
RUN git clone https://github.com/efabless/caravel_user_project.git

WORKDIR $ASICTOOLS_ROOT/caravel_user_project
RUN git checkout mpw-3

RUN make install
RUN make pdk
# The following two use docker, so they fail:
#RUN make openlane
#RUN make user_proj_example

# cocotb
RUN pip3 install cocotb

# OSS Cad Suite
WORKDIR $ASICTOOLS_ROOT
RUN curl -L https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2021-09-29/oss-cad-suite-linux-x64-20210929.tgz | tar zxf -

# RISC-V toolchain
WORKDIR $ASICTOOLS_ROOT
RUN curl -L https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-linux-ubuntu14.tar.gz | tar zxf -

# Bonus: openlane_summary and multi_project_tools by matt venn
WORKDIR $ASICTOOLS_ROOT
RUN git clone https://github.com/mattvenn/openlane_summary
RUN git clone https://github.com/mattvenn/multi_project_tools
WORKDIR $ASICTOOLS_ROOT/multi_project_tools
RUN pip install -r requirements.txt

# Configure PATH
ENV PATH=$PATH:$ASICTOOLS_ROOT/oss-cad-suite/bin:/home/openmpw/.local/bin:$ASICTOOLS_ROOT/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-linux-ubuntu14/bin:$ASICTOOLS_ROOT/openlane_summary

CMD bash
