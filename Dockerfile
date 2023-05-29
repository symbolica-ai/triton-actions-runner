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
    build-essential curl git jq libclang-dev libffi-dev libsqlite3-dev libssl-dev pkg-config python3 python3-venv python3-dev python3-pip sqlite3 libpq-dev \
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
RUN /venv/bin/python -m pip install --no-cache-dir cmake torch regex

# install custom triton, remove triton repo after
RUN cd /home/docker \
    && git clone --branch symbolica_stable https://github.com/symbolica-ai/triton.git \
    && cd triton/python \
    && /venv/bin/python -m pip install .

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
