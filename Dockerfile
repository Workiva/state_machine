FROM drydock-prod.workiva.net/workiva/dart2_base_image:0.0.0-dart2.18.7

WORKDIR /build/
ADD pubspec.yaml /build
RUN dart pub get
FROM scratch
