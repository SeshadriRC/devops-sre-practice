# DevOps & SRE Daily Hands-On Practice

Hands-on repository for daily DevOps engineering and Site Reliability Engineering (SRE) practice.

## 🎯 Objectives
- Build muscle memory across cloud infrastructure, automation, orchestration, and observability.
- Transition from routine operations to senior SRE patterns (SLIs/SLOs, incident management, toil reduction, blast radius minimization).
- Practice realistic production break-fix scenarios.

## 🛠️ Technology Stack
- **Infrastructure & Cloud**: AWS, Terraform
- **Configuration & GitOps**: Ansible, ArgoCD, Git
- **Containers & Orchestration**: Docker, Kubernetes
- **Observability**: Prometheus, Grafana, ELK Stack
- **Automation & Scripting**: Python, Shell (Bash)

## 📁 Repository Structure
```text
devops-sre-practice/
├── TRACKER.md          # Master matrix & daily completion log (never repeat topics)
├── README.md           # Repository documentation & guide
├── labs/               # Daily practical sessions
│   ├── day-01/
│   │   ├── README.md   # Problem statement & scenario
│   │   ├── code/       # IaC, manifests, scripts
│   │   └── solution.md # Analysis, post-mortem, and resolution
└── templates/          # Reusable incident post-mortems & ADR templates
```

## ⚠️ Safe Operation Rules
- **No Unapproved Installs**: All tool installations require explicit user confirmation.
- **Resource Consciousness**: Workloads are tuned for low-spec laptops (avoiding heavy local multi-node clusters).
- **AWS Cost Discipline**: All cloud labs are designed with strict ephemeral lifecycles (clean up via `terraform destroy` at session conclusion).
