{{- define "petclinic-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "petclinic-service.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "petclinic-service.name" . -}}
{{- end -}}
{{- end -}}

{{- define "petclinic-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "petclinic-service.labels" -}}
helm.sh/chart: {{ include "petclinic-service.chart" . }}
app.kubernetes.io/name: {{ include "petclinic-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: petclinic
petclinic.io/environment: {{ .Values.environment | quote }}
{{- end -}}

{{- define "petclinic-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "petclinic-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "petclinic-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "petclinic-service.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Build container image reference.

Expected values:
image:
  registry: 974263620909.dkr.ecr.us-east-2.amazonaws.com
  repository: petclinic-dev-config-server
  tag: 64a3a3d
  pullPolicy: IfNotPresent

Final image:
974263620909.dkr.ecr.us-east-2.amazonaws.com/petclinic-dev-config-server:64a3a3d
*/}}
{{- define "petclinic-service.image" -}}
{{- $tag := required "image.tag is required. Pass the exact image tag pushed by the app build, for example --set image.tag=$IMAGE_TAG." .Values.image.tag -}}
{{- $repository := required "image.repository is required. Example: petclinic-dev-config-server." .Values.image.repository | trimPrefix "/" | trimSuffix ":" -}}
{{- $registry := .Values.image.registry | trimSuffix "/" -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}