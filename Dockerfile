# base
FROM nvidia/cuda:12.1.0-devel-ubuntu20.04

# add source label to associate docker image to the repo
LABEL org.opencontainers.image.source=https://github.com/symbolica-ai/triton-actions-runner

# set the github runner version
ARG RUNNER_VERSION="2.304.0"

# add a non-sudo user for actions
RUN  useradd -m docker

# install python and the packages the your code depends on along with jq so we can parse JSON
# add additional packages as necessary
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential curl git jq libclang-dev libffi-dev libsqlite3-dev libssl-dev pkg-config python3 python3-venv python3-dev python3-pip sqlite3 libpq-dev cmake ninja-build wget m4 \
    && rm -rf /var/lib/apt/lists/*

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN chown -R docker ~docker && DEBIAN_FRONTEND=noninteractive /home/docker/actions-runner/bin/installdependencies.sh

# copy over the start.sh script
COPY start.sh start.sh

# make the script executable
RUN chmod +x start.sh

RUN python3 -m venv /venv \
    && /venv/bin/python -m pip install --upgrade pip

# install largest dependencies known to man
# TODO: might not be needed (new triton install has it covered)
RUN /venv/bin/python -m pip install --no-cache-dir cmake torch regex

# install custom triton, remove triton repo after
RUN cd /home/docker \
    && git clone --branch symbolica_stable https://github.com/symbolica-ai/triton.git \
    && cd triton/tt_aot\
    && /venv/bin/python -m pip install .

# install custom nauty
RUN cd /home/docker \
    && wget https://pallini.di.uniroma1.it/nauty2_8_6.tar.gz \
    && tar -xzf nauty2_8_6.tar.gz \
    && cd nauty2_8_6 \
    && export CFLAGS="-O3" \
    && export CXXFLAGS="-O3" \
    && mkdir -p /usr/local/nauty \
    && ./configure --prefix /usr/local/nauty \
    && make -j8 all \
    && make -j8 install \
    && ln -s /usr/local/nauty/bin/* /usr/local/bin \
    && ln -s /usr/local/nauty/lib/* /usr/local/lib \

# install custom GAP
RUN cd /home/docker \
    && wget https://github.com/gap-system/gap/releases/download/v4.12.2/gap-4.12.2.tar.gz \
    && tar -xzf gap-4.12.2.tar.gz \
    && cd gap-4.12.2 \
    && export CFLAGS="-O3" \
    && export CXXFLAGS="-O3" \
    && mkdir -p /usr/local/gap \
    && ./configure --prefix /usr/local/gap \
    && make -j8 all \
    && make -j8 install \
    && cd pkg \
    && ../bin/BuildPackages.sh --with-gaproot=/usr/local/gap/lib/gap \
    && cp -R * /usr/local/gap/share/gap/pkg \
    && ln -s /usr/local/gap/bin/* /usr/local/bin \
    && ln -s /usr/local/gap/lib/* /usr/local/lib \

# install BlissInterface package
RUN cd /usr/local/gap/share/gap/pkg \
    && wget https://github.com/gap-packages/BlissInterface/releases/download/v0.22/BlissInterface-0.22.tar.gz \
    && tar -xzf BlissInterface-0.22.tar.gz \
    && rm BlissInterface-0.22.tar.gz \
    && export CFLAGS="-O3" \
    && export CXXFLAGS="-O3" \
    && mv BlissInterface-0.22 BlissInterface \
    && cd BlissInterface \
    && ./configure --with-gaproot=/usr/local/gap/lib/gap \
    && make -j8

# install IncidenceStructures package
RUN cd /usr/local/gap/share/gap/pkg \
    && wget https://github.com/nagygp/IncidenceStructures/releases/download/v0.3/IncidenceStructures-0.3.tar.gz \
    && tar -xzf IncidenceStructures-0.3.tar.gz \
    && rm IncidenceStructures-0.3.tar.gz \
    && mv IncidenceStructures-0.3 IncidenceStructures

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
