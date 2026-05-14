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

{{- define "petclinic-service.image" -}}
{{- $tag := required "image.tag is required. Pass the exact tag pushed by the app build, for example --set image.tag=$IMAGE_TAG." .Values.image.tag -}}
{{- if .Values.image.repository -}}
{{- printf "%s:%s" (.Values.image.repository | trimSuffix ":") $tag -}}
{{- else -}}
{{- $registry := required "image.registry is required when image.repository is not set." .Values.image.registry -}}
{{- $prefix := required "image.repositoryPrefix is required when image.repository is not set." .Values.image.repositoryPrefix | trimSuffix "-" -}}
{{- $imageName := default (include "petclinic-service.name" .) .Values.image.name -}}
{{- printf "%s/%s-%s:%s" ($registry | trimSuffix "/") $prefix $imageName $tag -}}
{{- end -}}
{{- end -}}
