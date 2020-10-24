###############################################################################
# The FUSE driver needs elevated privileges, run Docker with --privileged=true
###############################################################################

FROM alpine:latest

ENV MNT_POINT /var/obsfs
ENV OBSFS_IAM_ROLE=none
ENV OBSFS_ACCESS_KEY=''
ENV OBSFS_SECRET_KEY=''
ENV OBSFS_BUCKET=''
ENV OBSFS_ENDPOINT=''

VOLUME /var/obsfs

# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk --update add bash fuse libcurl libxml2 libstdc++ libgcc alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git;

RUN git clone https://github.com/huaweicloud/huaweicloud-obs-obsfs.git; \
    cd huaweicloud-obs-obsfs; \
    chmod +x autogen.sh; \
    ./autogen.sh; \
    ./configure --prefix=/usr ; \
    make; \
    make install; \
    make clean; \
    rm -rf /var/cache/apk/*; \
    apk del git automake autoconf;

RUN sed -i s/"#user_allow_other"/"user_allow_other"/g /etc/fuse.conf

COPY docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

CMD /docker-entrypoint.sh
