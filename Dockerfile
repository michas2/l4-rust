FROM debian:stable
MAINTAINER Michael Schnupp <michael_schnupp@genua.de>
CMD [ "bash","-l" ]

#########  setup environment  #########

RUN apt-get update && apt-get install -y \
	build-essential gcc-multilib genext2fs \
	mtools xorriso pkgconf gawk git wget bash bc subversion qemu grub-pc-bin

#########  get code from subversion  #########

WORKDIR /l4
#ENV REPOMGR_SVN_REV 72
RUN svn cat https://svn.l4re.org/repos/oc/l4re/trunk/repomgr | perl - init https://svn.l4re.org/repos/oc/l4re fiasco l4re l4linux_requirements |grep -v '^A  '
RUN svn -q co https://svn.l4re.org/repos/oc/l4linux/trunk src/l4linux
RUN cd src/l4/pkg; svn -q up cons
ADD l4.diff l4.diff
RUN git config --global user.email "you@example.com" && git config --global user.name "Your Name"
RUN cd src && git init . && echo ".svn" >.gitignore && git add . && git commit -qam checkout && git apply ../l4.diff

#########  build fiasco  #########

RUN make -C src/kernel/fiasco B=../../../obj/fiasco
COPY fiasco.config obj/fiasco/globalconfig.out
RUN make -C obj/fiasco olddefconfig
RUN make -C obj/fiasco V=0

#########  build l4  #########

RUN make -C src/l4 DROPSCONF_DEFCONFIG=mk/defconfig/config.amd64 B=../../obj/l4
RUN make -C obj/l4 V=0

######### helper #########

SHELL [ "/bin/bash","-lc" ]
RUN mkdir /modules
RUN ln -s /l4/obj/l4/bin/amd64_K8/bootstrap /modules/
RUN ln -s /l4/obj/fiasco/fiasco /modules/
RUN ln -s /l4/obj/l4/bin/amd64_K8/l4f/{sigma0,moe,l4re} /modules/
ADD run.sh /usr/local/bin/run
ADD build.sh /usr/local/bin/build
ADD fa.sh /usr/local/bin/fa

######### install musl #######

RUN wget https://www.musl-libc.org/releases/musl-1.1.16.tar.gz
RUN tar xf musl-1.1.16.tar.gz
RUN cd musl-1.1.16 && ./configure --prefix=/usr/local
RUN make -C musl-1.1.16 install

######### install rust #######

ENV USER root
ENV HOME /root
WORKDIR /root

RUN apt-get install -y curl vim file
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN rustup target add x86_64-unknown-linux-musl
RUN rustup install nightly
RUN rustup default nightly
RUN rustup target add x86_64-unknown-linux-musl

RUN rustup component add rust-src
RUN cargo install xargo
ADD x86_64-l4re-uclibc.json x86_64-l4re-uclibc.json
ENV RUST_TARGET_PATH /root

######### build project #######

RUN cargo new --bin hello
WORKDIR hello
RUN echo '[dependencies.std]' >> Xargo.toml
RUN echo 'features = ["panic_abort"]' >> Xargo.toml
RUN cargo build --target x86_64-unknown-linux-musl
#RUN xargo build --target x86_64-unknown-linux-musl
RUN xargo build --target x86_64-l4re-uclibc
RUN file target/x86_64*/debug/hello /l4/obj/l4/bin/amd64_K8/l4f/hello
#RUN run /l4/obj/l4/bin/amd64_K8/l4f/hello
