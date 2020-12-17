FROM perl:5.20
RUN cpanm Carton
WORKDIR /usr/src/myapp
COPY cpanfile* /usr/src/myapp/
RUN carton install
COPY . /usr/src/myapp/
RUN mkdir -p /home/apache/vhosts/ae09ag.kodekoan.com/htdocs /home/apache/vhosts/ae09.com/htdocs/art
RUN carton exec perl ./generate.pl
