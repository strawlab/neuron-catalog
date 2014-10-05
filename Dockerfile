FROM ubuntu:12.04
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y curl
RUN curl https://install.meteor.com/ | sh

ADD . /neuron-catalog

WORKDIR /neuron-catalog

ENV MONGO_URL mongodb://db:27017/meteor

EXPOSE 80
CMD ["/usr/local/bin/meteor", "run", "--port=80"]
