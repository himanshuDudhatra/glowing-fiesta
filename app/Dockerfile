FROM node:24-slim

WORKDIR /app

COPY --chown=node:node package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node index.js .

EXPOSE 3000

USER node

CMD ["node", "index.js"]