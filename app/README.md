# Simple Time Service

A minimal Node.js microservice that returns:
- Current server timestamp (`ISO 8601`)
- Client IP address

## API

- `GET /`
  - Response:
    ```json
    {
      "timestamp": "2026-04-07T12:34:56.789Z",
      "ip": "::1"
    }
    ```

## Prerequisites

- Node.js 24+ and npm
- Docker (optional, for container deployment)
- Kubernetes cluster and `kubectl` (optional, for K8s deployment)

## Run Locally

From the `app` directory:

```bash
npm install
npm start
```

Service runs on `http://localhost:3000` by default.

You can override the port:

```bash
PORT=8080 npm start
```

## Deploy with Docker

Build the image:

```bash
docker build -t simpletimeservice:latest .
```

Run the container:

```bash
docker run --rm -p 3000:3000 simpletimeservice:latest
```

Test:

```bash
curl http://localhost:3000/
```