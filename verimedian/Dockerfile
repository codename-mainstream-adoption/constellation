# build the rapidsnark executable
FROM ubuntu:22.04 as rapidsnark_builder
RUN apt-get update && apt-get install -y build-essential cmake libgmp-dev libsodium-dev nasm curl m4 git
RUN git clone https://github.com/iden3/rapidsnark.git
WORKDIR rapidsnark
RUN git submodule init
RUN git submodule update
RUN ./build_gmp.sh host
RUN mkdir build_prover
WORKDIR build_prover
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../package
RUN make -j4 && make install

# compile the witness calculator in the docker image
FROM rapidsnark_builder AS wtns_calc_builder
WORKDIR /build
RUN mkdir -p moving_median_cpp
COPY build/moving_median_cpp/*.cpp ./moving_median_cpp/
COPY build/moving_median_cpp/*.hpp ./moving_median_cpp/
COPY build/moving_median_cpp/Makefile ./moving_median_cpp/
COPY build/moving_median_cpp/*.dat ./moving_median_cpp/
COPY build/moving_median_cpp/*.asm ./moving_median_cpp/
RUN cp -r /rapidsnark/depends/json/single_include/nlohmann ./moving_median_cpp
WORKDIR moving_median_cpp
RUN make

# build the verimedian python library
FROM python:3.11.6-slim as verimedian_builder
WORKDIR /verimedian
COPY requirements.txt .
COPY setup.py .
COPY verimedian ./verimedian
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python -m venv $VIRTUAL_ENV
RUN pip install -r requirements.txt

# build the final image
FROM python:3.11.6-slim
RUN apt-get update && apt-get install -y libgomp1
RUN mkdir /build
COPY build/verification_key.json /build
COPY build/moving_median.zkey /build
COPY --from=verimedian_builder /opt/venv /opt/venv
COPY --from=wtns_calc_builder /build/moving_median_cpp/moving_median.dat /build
COPY --from=rapidsnark_builder /rapidsnark/package/bin/prover /opt/venv/bin/prover
COPY --from=wtns_calc_builder /build/moving_median_cpp/moving_median /opt/venv/bin
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"