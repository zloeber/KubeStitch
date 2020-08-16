apiVersion: v1
data:
  vault-agent-config.hcl: |
    # Comment this out if running as sidecar instead of initContainer
    exit_after_auth = true

    pid_file = "/home/vault/pidfile"

    auto_auth {
        method "kubernetes" {
            mount_path = "auth/kubernetes"
            config = {
                role = "$role"
            }
        }

        sink "file" {
            config = {
                path = "/home/vault/.vault-token"
            }
        }
    }

    template {
    destination = "/etc/secrets/index.html"
    contents = <<EOT
    <html>
    <body>
    <p>Some secrets:</p>
    {{- with secret "$kvpath/data/$name/config" }}
    <ul>
    <li><pre>username: {{ .Data.data.username }}</pre></li>
    <li><pre>password: {{ .Data.data.password }}</pre></li>
    </ul>
    {{ end }}
    </body>
    </html>
    EOT
    }
kind: ConfigMap
metadata:
  name: $name-vaultagent-config
