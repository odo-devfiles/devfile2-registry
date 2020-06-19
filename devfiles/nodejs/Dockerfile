FROM registry.access.redhat.com/ubi8/nodejs-12:1-36

USER root

COPY . /project

WORKDIR /project

RUN npm install

ENV PORT 3000

EXPOSE 3000

CMD ["npm", "start"]