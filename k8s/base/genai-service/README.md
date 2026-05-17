# GenAI Service Raw Manifests

This folder contains the raw Kubernetes Deployment and Service for
`genai-service`.

The active deployment is still the
`genai-service-dev` or `genai-service-prod` Argo CD Application, which renders
`helm/petclinic-service` with `helm-values/genai-service.yaml`.

`genai-service` consumes the Kubernetes `openai-secret`.
