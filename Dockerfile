FROM nvidia/cuda:9.2-runtime-ubuntu18.04

ENV ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8
ENV OPENBLAS_NUM_THREADS=1
ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/main/main restricted universe/g' /etc/apt/sources.list &&\
    apt-get update &&\
    apt-get -y upgrade &&\
    apt-get -y install locales

ENV LC_CTYPE="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"
RUN locale-gen "en_US.UTF-8" &&\
    dpkg-reconfigure locales

RUN apt-get -y install wget\
                       gnupg\
                       gnupg1\
                       gnupg2
RUN wget -O- http://neuro.debian.net/lists/bionic.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9 || { wget -q -O- http://neuro.debian.net/_static/neuro.debian.net.asc | apt-key add -; }
RUN apt-get update &&\
    apt-get -y install git\
                       build-essential\
                       zlib1g-dev\
                       g++\
                       gcc\
                       dc\
                       bc\
                       fonts-freefont-ttf

WORKDIR /
RUN wget https://github.com/Kitware/CMake/releases/download/v3.13.2/cmake-3.13.2.tar.gz &&\
    tar -xvzf cmake-3.13.2.tar.gz &&\
    rm -rf cmake-3.13.2.tar.gz
WORKDIR /cmake-3.13.2
RUN ./bootstrap &&\
    make -j 8 &&\
    make install

RUN apt-get -y install libeigen3-dev\
                       libqt5opengl5-dev\
                       libqt5svg5-dev libgl1-mesa-dev\
                       libfftw3-dev\
                       libtiff5-dev\
                       libpng-dev\
                       clang\
                       libblas-dev liblapack-dev

RUN mkdir -p /tmp/fsl_sources
WORKDIR /tmp/fsl_sources
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py &&\
    python fslinstaller.py -d /usr/share/fsl && \
    rm -rf /usr/share/fsl/src\
           /usr/share/fsl/data\
           /usr/share/fsl/build\
           /usr/share/fsl/include\
           /usr/share/fsl/build.log\
           /usr/share/fsl/tcl\
           /usr/share/fsl/LICENSE\
           /usr/share/fsl/src\
           /usr/share/fsl/README\
           /usr/share/fsl/refdoc\
           /usr/share/fsl/python\
           /usr/share/fsl/doc\
           /usr/share/fsl/config\
           /usr/share/fsl/fslpython


ENV FSLDIR=/usr/share/fsl
ENV PATH=${FSLDIR}/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/share/fsl:/usr/share/fsl/bin
ENV FSLBROWSER=/etc/alternatives/x-www-browser
ENV FSLCLUSTER_MAILOPTS=n
ENV FSLMULTIFILEQUIT=TRUE
ENV FSLOUTPUTTYPE=NIFTI_GZ
ENV FSLTCLSH=/usr/bin/tclsh
ENV FSLWISH=/usr/bin/wish
ENV POSSUMDIR=/usr/share/fsl

WORKDIR /
RUN mkdir ants_build &&\
    git clone https://github.com/ANTsX/ANTs.git
WORKDIR /ANTs
RUN git fetch --tags &&\
    git checkout tags/v2.3.4 -b v2.3.4
WORKDIR /ants_build
RUN cmake \
    -DBUILD_SHARED_LIBS=OFF \
    -DUSE_VTK=OFF \
    -DSuperBuild_ANTS_USE_GIT_PROTOCOL=OFF \
    -DBUILD_TESTING=OFF \
    -DRUN_LONG_TESTS=OFF \
    -DRUN_SHORT_TESTS=OFF ../ANTs &&\
    make -j 2
WORKDIR /ants_build/ANTS-build
RUN make install
ENV ANTSPATH=/opt/ANTs/bin/
ENV PATH=$PATH:$ANTSPATH

WORKDIR /
RUN apt-get -y install unzip qt5-default &&\
    git clone https://github.com/MRtrix3/mrtrix3.git
WORKDIR /mrtrix3
RUN git fetch --tags &&\
    git checkout tags/3.0_RC3 -b 3.0_RC3 &&\
    ./configure &&\
    NUMBER_OF_PROCESSORS=8 ./build
ENV PATH=/mrtrix3/bin:$PATH

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libsm6 libxext6 libxrender-dev python3-pip python3.7 libtool autoconf pkg-config &&\
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1 &&\
    update-alternatives --config python3 &&\
    update-alternatives  --set python3 /usr/bin/python3.7 &&\
    python3.7 -m pip install pip &&\
    pip3 install --upgrade pip &&\
    apt-get -y install python3-lxml python3-six python3.7-dev python3.7-tk

ENV MESA=mesa-19.0.8.tar.gz
ENV VTK=VTK-8.2.0.tar.gz

RUN rm -rf /VTK-src && mkdir /VTK-src
RUN rm -rf /VTK-build && mkdir /VTK-build
RUN rm -rf /mesa-src && mkdir /mesa-src

COPY $VTK /VTK-src
COPY $MESA /mesa-src

WORKDIR /VTK-src
RUN tar zxvf $VTK && rm $VTK

WORKDIR /mesa-src
RUN tar zxvf $MESA && rm $MESA

WORKDIR /mesa-src/mesa-19.0.8
RUN apt install -y xorg-dev\
                   llvm-7 llvm-7-dev llvm-7-runtime
RUN ./configure --prefix=/usr/ --enable-autotools                   \
                  --enable-opengl --disable-gles1 --disable-gles2   \
                  --disable-va --disable-xvmc --disable-vdpau       \
                  --enable-shared-glapi                             \
                  --disable-texture-float                           \
                  --enable-gallium-llvm --enable-llvm-shared-libs   \
                  --with-gallium-drivers=swrast,swr                 \
                  --disable-dri --with-dri-drivers=                 \
                  --disable-egl --with-egl-platforms= --disable-gbm \
                  --disable-glx                                     \
                  --disable-osmesa --enable-gallium-osmesa --with-llvm-prefix=/usr/lib/llvm-7 &&\
    make -j 10 &&\
    make install


RUN update-alternatives --config python3 &&\
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1 &&\
    update-alternatives  --set python3 /usr/bin/python3.7

ENV PYTHON_INCLUDE_DIR=/usr/include/python3.7
ENV PYTHON_LIBS=/usr/lib/python3.7/config-3.7m-x86_64-linux-gnu/libpython3.7.so
ENV PYTHON_LIBRARY=/usr/lib/python3.7/config-3.7m-x86_64-linux-gnu/libpython3.7.so
RUN pip3 install -U setuptools

RUN mv /usr/bin/python /usr/bin/bk_python
RUN ln -s /usr/bin/python3.7 /usr/bin/python

WORKDIR /VTK-build

RUN cmake -DCMAKE_BUILD_TYPE=Release \
          -DVTK_WRAP_PYTHON=ON \
          -DVTK_USE_X=OFF \
          -DBUILD_SHARED_LIBS=ON \
          -DVTK_OPENGL_HAS_OSMESA=ON \
          -DVTK_DEFAULT_RENDER_WINDOW_OFFSCREEN=ON \
          -DOSMESA_INCLUDE_DIR=/usr/include/ \
          -DOSMESA_LIBRARY=/usr/lib/libOSMesa.so \
          -DCMAKE_INSTALL_PREFIX=/usr/ ../VTK-src/VTK*

RUN  make -j 8 &&\
     make install

RUN mv /usr/bin/bk_python /usr/bin/python

ENV PYTHONPATH=/usr/lib/x86_64-linux-gnu/python3.7/site-packages/:/usr/bin/
ENV LD_LIBRARY_PATH=/usr/bin/

WORKDIR /
