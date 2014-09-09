FROM ubuntu:12.04
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y curl
RUN curl https://install.meteor.com/ | sh

ADD . /fly-neuron-catalog

WORKDIR /fly-neuron-catalog

EXPOSE 80
CMD ["/usr/local/bin/meteor", "run", "--port=80"]
