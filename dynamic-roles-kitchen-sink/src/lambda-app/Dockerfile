FROM node:20-bookworm-slim AS build

RUN apt-get update && \
    apt-get install -y --no-install-recommends cmake make g++ python3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json ./
RUN npm install aws-lambda-ric

FROM node:20-bookworm-slim

WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY index.js package.json ./

ENTRYPOINT ["/app/node_modules/.bin/aws-lambda-ric"]
CMD ["index.handler"]
