FROM node:20-alpine

RUN apk add --no-cache cmake make g++ python3

WORKDIR /app

COPY index.js package.json ./

RUN npm install --production && npm install aws-lambda-ric

ENTRYPOINT ["/app/node_modules/.bin/aws-lambda-ric"]
CMD ["index.handler"]
