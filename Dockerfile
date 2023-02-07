FROM eclipse-temurin:11.0.18_10-jre-focal

ARG JAR_FILE=build/libs/*.jar

COPY ${JAR_FILE} app.jar

ENV TZ=Asia/Seoul

RUN ln -snf /us/share/zoneinfo/STZ /etc/localtime && echo STZ > /etc/timezone

ENTRYPOINT ["java", "-jar", "/app.jar", "-Duser.timezone=Asia/Seoul"]