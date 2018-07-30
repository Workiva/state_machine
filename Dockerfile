FROM drydock-prod.workiva.net/workiva/smithy-runner-generator:350667 as build

# Build Environment Vars
ARG BUILD_ID
ARG BUILD_NUMBER
ARG BUILD_URL
ARG GIT_COMMIT
ARG GIT_BRANCH
ARG GIT_TAG
ARG GIT_COMMIT_RANGE
ARG GIT_HEAD_URL
ARG GIT_MERGE_HEAD
ARG GIT_MERGE_BRANCH
ARG GIT_SSH_KEY
ARG KNOWN_HOSTS_CONTENT
WORKDIR /build/
ADD . /build/

RUN mkdir /root/.ssh && \
    echo "$KNOWN_HOSTS_CONTENT" > "/root/.ssh/known_hosts" && \
    chmod 700 /root/.ssh/ && \
    umask 0077 && echo "$GIT_SSH_KEY" >/root/.ssh/id_rsa && \
    eval "$(ssh-agent -s)" && ssh-add /root/.ssh/id_rsa
RUN echo "Starting the before_script section" && \
		dart --version && \
		echo "before_script section completed"
RUN echo "Starting the script section" && \
		pub get && \
        pub run dependency_validator -i abide,browser,coverage,dart_style,dartdoc,semver_audit && \
        pub run abide && \
        pub run dart_dev format --check && \
        pub run dart_dev analyze && \
        pub run semver_audit report --repo Workiva/state_machine && \
		echo "script section completed"
ARG BUILD_ARTIFACTS_DART-DEPENDENCIES=/build/pubspec.lock
FROM scratch
