FROM nginx:1.17.4

RUN apt-get update
RUN apt-get -y install python3
RUN apt-get -y install python3-pip
RUN apt-get -y install dos2unix

COPY app/dist /usr/share/nginx/html
COPY api/dist/api-*-py3-none-any.whl /app/

RUN cd /app && whl_file=`ls | grep whl` && pip3 install $whl_file && cd ..
