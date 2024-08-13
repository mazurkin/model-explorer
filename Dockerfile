FROM ubuntu:22.04
USER root

# system
RUN apt-get -y update \
  && apt-get -y install curl \
  && apt-get clean

# user
RUN groupadd --gid 1000 conda \
 && useradd --uid 1000 --gid 1000 conda

# conda
ARG CONDA_VERSION=py310_24.3.0-0
RUN mkdir -p '/opt/miniconda' \
 && curl --no-progress-meter -o '/tmp/miniconda.sh' "https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" \
 && bash "/tmp/miniconda.sh" -b -f -p /opt/miniconda \
 && rm "/tmp/miniconda.sh"
ENV PATH="/opt/miniconda/bin:${PATH}"

# conda setup
RUN conda install -n base conda-libmamba-solver \
 && conda config --set solver libmamba

# conda environment
RUN conda create --yes --name model-explorer python=3.10.12 conda-forge::poetry=1.8.3

# fix libstd lookup
RUN rm /opt/miniconda/envs/model-explorer/lib/libstdc++.so.6.0.29 \
 && ln -sf /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.30 /opt/miniconda/envs/model-explorer/lib/libstdc++.so \
 && ln -sf /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.30 /opt/miniconda/envs/model-explorer/lib/libstdc++.so.6

# copy dependency control
COPY poetry.lock pyproject.toml poetry.toml /tmp/environment/poetry/

# install dependencies
RUN cd /tmp/environment/poetry/ \
 && conda run --no-capture-output --live-stream --name model-explorer poetry install --no-root

# files
COPY bin /opt/model-explorer/bin

# mutable volumes (the rest of the filesystem is considered as immutable)
VOLUME ["/home/conda"]
VOLUME ["/tmp"]

# python environment
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# system
ENV USER=conda

# application
USER conda
WORKDIR "/opt/model-explorer/bin"
ENTRYPOINT ["/bin/bash"]
CMD []
