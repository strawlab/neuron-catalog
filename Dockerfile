FROM ubuntu:12.04
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y curl
RUN curl https://install.meteor.com/ | sh

# ---- install node ---------
WORKDIR /tmp/node
RUN echo "126ed002d88315b8d37cec1ee4915454  node-v0.10.32-linux-x64.tar.gz" > checksum

RUN curl -O http://nodejs.org/dist/v0.10.32/node-v0.10.32-linux-x64.tar.gz
RUN md5sum --strict --check checksum
RUN rm checksum

WORKDIR /usr/local
RUN tar xzf /tmp/node/node-v0.10.32-linux-x64.tar.gz --strip 1
# -----------

ADD . /neuron-catalog
WORKDIR /neuron-catalog
RUN meteor build --debug --directory /var/www/app

WORKDIR /var/www/app/bundle/programs/server
RUN npm install

ENV PORT 80
ENV ROOT_URL http://127.0.0.1/
ENV MONGO_URL mongodb://db:27017/meteor

EXPOSE 80

WORKDIR /var/www/app/bundle
CMD ["/usr/local/bin/node", "main.js"]
