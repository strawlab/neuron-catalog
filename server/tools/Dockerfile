FROM dockerfile/mongodb
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y python-pymongo-ext python-boto imagemagick
ADD src /binary-upload-processor

WORKDIR /binary-upload-processor
ENV MONGO_URL mongodb://db:27017/meteor
CMD ["/usr/bin/python", "tail-mongo.py"]
