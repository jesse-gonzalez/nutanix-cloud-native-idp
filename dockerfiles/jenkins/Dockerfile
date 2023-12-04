FROM jenkins/jenkins:lts

RUN jenkins-plugin-cli --latest false --plugins \
    kubernetes \
    workflow-aggregator \
    git \
    configuration-as-code \
    github \
    blueocean \
    job-dsl \
    ldap \
    docker-workflow \
    dependency-check-jenkins-plugin \
    jacoco \
    slack \
    sonar \
    pitmutation \
    kubernetes-cli