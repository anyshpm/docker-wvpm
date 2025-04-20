FROM node:22.11-alpine3.20 as frontend-builder

ENV APP_DIR=/app
ENV BUILD_DIR=/home/wvpm

COPY web_src $BUILD_DIR/web_src

WORKDIR $BUILD_DIR

RUN cd web_src && \
    npm install && \
    npm run build && \
    ls -al && \
    rm -rf node_modules


FROM maven:3.8-openjdk-11-slim as backend-builder

ENV APP_DIR=/app
ENV BUILD_DIR=/home/wvpm

COPY --from=frontend-builder $BUILD_DIR $BUILD_DIR
COPY pom.xml $BUILD_DIR
COPY src $BUILD_DIR/src
COPY libs $BUILD_DIR/libs

WORKDIR $BUILD_DIR

RUN mkdir -p $APP_DIR/config && \
    mvn clean package -Dmaven.test.skip=true && \
    cp target/*.jar $APP_DIR && \
    cp src/main/resources/application-wvpm.yml $APP_DIR/config/application.yml


FROM openjdk:11-jre-slim

ENV LC_ALL zh_CN.UTF-8
ENV APP_DIR=/app

COPY --from=backend-builder ${APP_DIR} ${APP_DIR}
COPY docker-entrypoint.sh $APP_DIR

WORKDIR ${APP_DIR}

RUN chmod +x docker-entrypoint.sh

# TODO: 为什么此处不能用环境变量？
#ENTRYPOINT ["${APP_DIR}/docker-entrypoint.sh"]
ENTRYPOINT ["/app/docker-entrypoint.sh"]
