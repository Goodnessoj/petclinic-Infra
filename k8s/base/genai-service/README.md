# GenAI Service Raw Manifests

This folder is reserved for raw Kubernetes manifests for `genai-service`.

The current YAML files are empty. The active deployment is the
`genai-service-dev` or `genai-service-prod` Argo CD Application, which renders
`helm/petclinic-service` with `helm-values/genai-service.yaml`.

`genai-service` consumes the Kubernetes `openai-secret`.
