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

## Deploy to Kubernetes

The repository includes `microservice.yml` with:
- A `Deployment` named `simple-time-service`
- A `ClusterIP` `Service` on port `3000`

### 1) Push your image

The manifest currently references:

`himanshududhatra/simpletimeservice:latest`

If you use a different image, update the `image` field in `microservice.yml` first.

### 2) Apply manifests

```bash
kubectl apply -f microservice.yml
```

### 3) Verify rollout

```bash
kubectl get deploy simple-time-service
kubectl get pods -l app=simple-time-service
kubectl get svc simple-time-service
```

### 4) Test from your machine (port-forward)

```bash
kubectl port-forward svc/simple-time-service 3000:3000
curl http://localhost:3000/
```
