{{/*
WF_SECRET_KEY: the app's master key (base64 of 32 random bytes; the server
HKDF-derives its JWT + secrets-encryption keys from it). Generated once on
first render via the else branch and read back (b64dec) on every later
render, so upgrades and reinstalls keep the same key. To rotate: delete the
wealthfolio-app Secret and upgrade.
*/}}
{{- define "wealthfolio.secretKey" -}}
{{- $existing := (lookup "v1" "Secret" .Release.Namespace "wealthfolio-app") -}}
{{- if and $existing $existing.data (index $existing.data "WF_SECRET_KEY") -}}
{{- index $existing.data "WF_SECRET_KEY" | b64dec -}}
{{- else -}}
{{- randAlphaNum 32 | b64enc -}}
{{- end -}}
{{- end }}
