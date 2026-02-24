FROM node:20-alpine

WORKDIR /var/task

COPY index.js package.json ./

RUN npm install --production && npm install aws-lambda-ric

ENTRYPOINT ["/var/task/node_modules/.bin/aws-lambda-ric"]
CMD ["index.handler"]
