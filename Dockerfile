FROM gmaslowski/jdk:latest as builder
ENV DIR=/root/android
WORKDIR $DIR
RUN ls && \
# sed -i 's/http:\/\/dl-cdn.alpinelinux.org/https:\/\/mirrors.aliyun.com/g' /etc/apk/repositories && \
apk update && \
apk add --no-cache ca-certificates && \
apk add git && \
git clone https://github.com/nelenkov/android-backup-extractor.git && \
cd android-backup-extractor && \
./gradlew

FROM openjdk:8u265-jre-slim-buster as builder2
ENV DIR=/root/android
WORKDIR $DIR
COPY ./decrypt.py $DIR
RUN ls && \
# sed -i "s@http://deb.debian.org@https://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
apt-get update && \
apt-get install -y --fix-missing python curl python-dev libssl-dev gcc && \
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
python2 get-pip.py && \
# -i https://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com/pypi/simple/
python2 -m pip install pysqlcipher --install-option="--bundled" && \
# -i https://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com/pypi/simple/
python2 -m pip install pyinstaller && \
pyinstaller -F --distpath ./ decrypt.py

FROM openjdk:8u265-jre-slim-buster as builder3
ENV DIR=/root/android
WORKDIR $DIR
COPY ./process.py $DIR
RUN ls && \
# sed -i "s@http://deb.debian.org@https://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
apt-get update && \
apt-get install -y --fix-missing python3 python3-pip && \
# -i https://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com/pypi/simple/
python3 -m pip install pyinstaller && \
pyinstaller -F --distpath ./ process.py

FROM openjdk:8u265-jre-slim-buster as run
ENV DIR=/root/android
WORKDIR $DIR
COPY --from=0 /root/android/android-backup-extractor/build/libs/abe-all.jar $DIR
COPY --from=1 /root/android/decrypt $DIR
COPY --from=2 /root/android/process $DIR
RUN ls
CMD ./process