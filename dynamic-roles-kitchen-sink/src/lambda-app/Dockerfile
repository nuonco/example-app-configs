FROM node:20-alpine

WORKDIR /app

COPY index.js package.json ./

RUN npm install --production && npm install aws-lambda-ric

ENTRYPOINT ["/app/node_modules/.bin/aws-lambda-ric"]
CMD ["index.handler"]
