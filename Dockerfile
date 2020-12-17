FROM alpine
RUN apk add --no-cache \
      perl=5.30.3-r0 \
      perl-dev=5.30.3-r0 \
      perl-app-cpanminus=1.7044-r2 \
      curl=7.69.1-r3 \
      tar=1.32-r1 \
      make=4.3-r0 \
      gcc=9.3.0-r2 \
      build-base=0.5-r2 \
      wget=1.20.3-r1 \
      gnupg=2.2.23-r0 \
      imagemagick=7.0.10.48-r0
RUN cpanm Carton
WORKDIR /usr/src/myapp
COPY cpanfile* /usr/src/myapp/
RUN carton install
COPY . /usr/src/myapp/
RUN mkdir -p /home/apache/vhosts/ae09ag.kodekoan.com/htdocs /home/apache/vhosts/ae09.com/htdocs/art
RUN carton exec perl ./generate.pl
