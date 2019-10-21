FROM google/dart:2.4.1

WORKDIR /build/
ADD pubspec.yaml /build
RUN pub get
FROM scratch
