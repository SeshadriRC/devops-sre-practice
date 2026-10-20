# DevOps & SRE Daily Practice Tracker

This repository tracks daily hands-on practice, scenarios, break-fix challenges, and architectural drills.

---

## 📋 Technology Coverage & Progress

| Technology | Status | Core Focus Areas / Completed Labs |
| :--- | :--- | :--- |
| **Ansible** | `Not Started` | Idempotency, dynamic inventory, roles, error handling, AWS automation |
| **Terraform** | `Not Started` | Modules, state manipulation/import, drift remediation, least-privilege IAM, zero-downtime |
| **Kubernetes** | `Not Started` | Probes, scheduling/taints/tolerations, PDB, HPA, ingress, troubleshooting CrashLoopBackOff |
| **Docker** | `Not Started` | Multi-stage builds, rootless containers, security scanning, minimal base images (distroless) |
| **AWS** | `Not Started` | VPC networking, ECS Fargate, IAM policies, cost controls, CloudWatch integration |
| **ArgoCD** | `Not Started` | GitOps workflows, sync strategies (Blue/Green, Canary with Rollouts), drift self-healing |
| **Jenkins** | `Not Started` | Declarative pipelines, shared libraries, ephemeral agents (Docker/K8s), credential security |
| **ELK** | `Not Started` | Logstash pipeline tuning, index lifecycle management (ILM), Elasticsearch query performance |
| **Prometheus** | `Not Started` | PromQL deep dive, recording rules, alert rules, custom exporters, scrape optimization |
| **Grafana** | `Not Started` | Dashboard design for 4 Golden Signals, alerting integration, multi-datasource panels |
| **Git** | `Not Started` | Advanced rebase, cherry-pick, conflict resolution, bisect for bug hunting, branch strategies |
| **Python** | `Not Started` | SRE automation scripts, boto3 AWS SDK, Prometheus client, CLI tools, API integrations |
| **Shell Scripting** | `Completed` | Robust Bash (`set -euo pipefail`), `flock` atomic locks, `trap` signal handling, exponential backoff |

---

## 🗓️ Daily Activity Log

| Day | Date | Primary Tech | Lab / Challenge Title | Lab Path | Notes / Key Learnings | Status |
|:---:|:---:|:---:|:---|:---|:---|:---:|
| Day 1 | 2026-10-20 | Shell Scripting | Defensive SRE Automation (Traps, flock, pipefail) | [`labs/day-01-shell-sre/`](labs/day-01-shell-sre/) | Refactored deadlocking watchdog: `flock`, `trap EXIT`, bounded backoff, guarded `${VAR:?}` | `Completed` |
| Day 2 | - | TBD | *Next hands-on practical session* | `labs/day-02/` | - | `Planned` |

---

## 🛡️ Guardrails & Operational Rules
1. **Zero Unapproved Installs**: Always ask user permission before running any package manager (`apt`, `pip`, `brew`, `curl | bash`, etc.).
2. **Laptop Resource Efficiency**: Keep local workloads lightweight (Docker Compose / isolated configs / mock stubs instead of heavy minikube clusters).
3. **AWS Teardown Protocol**: Any cloud resource provisioned must have an immediate `terraform destroy` or automated cleanup verified at the end of each session.
