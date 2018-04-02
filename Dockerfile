FROM kong:0.13.0

MAINTAINER syc, syc33@protonmail.com


ENV KONG_VERSION 0.13.0
ENV KONG_LUA_PACKAGE_PATH /kong-plugins/?.lua;;
ENV KONG_CUSTOM_PLUGINS apitokenauth

ADD kong/ /kong-plugins/kong/
ADD run.sh /

RUN chmod +x run.sh

# Clear entrypoint of base image
ENTRYPOINT []
CMD ["/run.sh"]

EXPOSE 8000 8443 8001 7946

# docker build -t my-kong .