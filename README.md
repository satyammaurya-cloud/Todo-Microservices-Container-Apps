# Todo-Microservices-Container-Apps

Container Apps - MicroTodoUI with Terraform IaC

#### 🚀 Distributed To-Do Microservices Platform (Azure Container Apps)

An enterprise-grade, event-driven microservices platform built with Python (FastAPI), React, and Azure Container Apps. Designed with strict domain isolation, multi-stage container optimization, and declarative Infrastructure as Code (IaC) via Terraform.


## 🏗️ Architecture Overview



```markdown
                  +-----------------------------+
                  |   React Web Frontend (UI)   |
                  |    (Nginx / Port 80)        |
                  +--------------+--------------+
                                 |
                                 | Public HTTP / Ingress
                                 v
   +-----------------------------------------------------------+
   |             Azure Container Apps Environment              |
   |                         ("to-do")                         |
   |                                                           |
   |   +-------------------+  +-------------------+  +-------+ |
   |   | Add-Task Service  |  | Get-Task Service  |  | ...   | |
   |   | (FastAPI / 8000)  |  | (FastAPI / 8000)  |  |       | |
   |   +---------+---------+  +---------+---------+  +---+---+ |
   +-------------|----------------------|----------------|-----+
                 |                      |                |
                 +----------------------+----------------+
                                        |
                                        v  ODBC Driver 18 (Encrypted)
                         +------------------------------+
                         |   Azure SQL Database PaaS    |
                         |          ("tododb")          |
                         +------------------------------+

```

### 💡 Core Design Principles
* **Single Responsibility Domain Isolation:** Read, Write, and Delete pathways are decoupled into dedicated Python microservices for independent scaling profiles and fault isolation.
* **Declarative Infrastructure:** 100% of the cloud footprint (Azure Container Apps Environment, Azure SQL Server, Firewall Rules, and Ingress) is provisioned declaratively via Terraform.
* **Minimal Attack Surface Containers:** Multi-stage Docker builds separate compilation tools (`gcc`, `unixodbc-dev`) from the final runtime image, leveraging `python:3.9-slim` to minimize image footprint (~300MB runtime overhead) and eliminate OS-level vulnerabilities.
* **Externalized Configuration:** Zero hardcoded credentials or dynamic infrastructure references. Internal connection routes and database connection strings are injected dynamically at runtime via Environment Variables (`CONNECTION_STRING`).

---

## 🧰 Tech Stack & Component Mapping

| Component | Technology | Primary Role |
| :--- | :--- | :--- |
| **Frontend UI** | React, Nginx, Docker | Single-Page Application served via lightweight Nginx runtime container. |
| **Write Service** | Python 3.9, FastAPI, SQLAlchemy | `add-task-service`: Ingests and validates incoming task write requests. |
| **Read Service** | Python 3.9, FastAPI, SQLAlchemy | `get-task-service`: Serves task list queries with database read-efficiency. |
| **Delete Service** | Python 3.9, FastAPI, SQLAlchemy | `delete-task-service`: Handles task removal domain operations. |
| **Database** | Azure SQL Database (PaaS) | Fully managed relational data store using ODBC Driver 18 for secure transport. |
| **Orchestration** | Azure Container Apps (ACA) | Serverless container host with native Ingress, DNS, and logging integration. |
| **Provisioning** | Terraform (HashiCorp) | AzureRM provider orchestrating complete cloud lifecycle management. |

---

## 📁 Repository Structure

```text
.
├── AddTaskTodoMicroservice/        # Add Task Backend Service
│   ├── app.py                      # FastAPI App Domain Logic
│   ├── Dockerfile                  # Multi-Stage Build Specification
│   └── requirements.txt            # Application Dependencies
├── GetTasksTodoMicroservice/       # Read Task Backend Service
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── DeleteTaskTodoMicroservice/     # Delete Task Backend Service
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── MicroTodoUI/                    # React Frontend UI
│   ├── src/
│   │   └── config.js               # Externalized API Routes Configuration
│   └── Dockerfile                  # Multi-Stage Nginx Build
└── Infra/                          # Infrastructure as Code
    └── main.tf                     # Complete Azure Provisioning Plan

```

---

## ⚡ Multi-Stage Docker Build Strategy

To satisfy strict enterprise security and performance metrics, all backend services implement a strict two-stage compilation pattern:

1. **Stage 1 (Builder):** Pulls build essentials (`gcc`, `g++`, `unixodbc-dev`), resolves dependencies, and compiles wheel targets into isolated runtime trees (`/install`).
2. **Stage 2 (Runner):** Extracts clean binaries from the builder onto a clean `python:3.9-slim` image, installs runtime-only Microsoft ODBC Driver 18, cleans package index caches (`/var/lib/apt/lists/*`), and executes the Uvicorn ASGI server as an unprivileged container process.

---

## 🚀 Complete End-to-End Execution Guide

### Prerequisites

* [Terraform CLI](https://www.terraform.io/) (v1.3.0+)
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) (`az login` authenticated)
* [Docker Engine](https://www.docker.com/)

---

### Step 1: Provision Infrastructure & Backend ACA Services

Navigate to the `Infra/` directory, initialize providers, and apply the infrastructure state:

```bash
cd Infra
terraform init
terraform plan -out=tfplan.binary
terraform apply tfplan.binary

```

---

### Step 2: Capture Generated Ingress Endpoints

Upon successful application, extract the generated backend FQDNs from the terminal output:

```text
Outputs:

add_task_url    = "[https://add-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io](https://add-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io)"
get_task_url    = "[https://get-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io](https://get-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io)"
delete_task_url = "[https://delete-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io](https://delete-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io)"

```

---

### Step 3: Configure Frontend Routes & Rebuild Container

Update `MicroTodoUI/src/config.js` with the real HTTPS endpoints obtained from Step 2:

```javascript
// MicroTodoUI/src/config.js
const CONFIG = {
  ADD_TASK_URL: "[https://add-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io/tasks](https://add-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io/tasks)",
  GET_TASK_URL: "[https://get-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io/tasks](https://get-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io/tasks)",
  DELETE_TASK_URL: "[https://delete-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io/tasks](https://delete-task-service.lemonsand-3f1e1df3.centralindia.azurecontainerapps.io/tasks)"
};

export default CONFIG;

```

Rebuild the React production image and push to Docker Hub:

```bash
# Build production-ready Nginx image
docker build -t vrun01999/microtodoui:v3 ./MicroTodoUI

# Push image to registry
docker push vrun01999/microtodoui:v3

```

---

### Step 4: Deploy UI Service via Terraform

Ensure `Infra/main.tf` references image tag `v3` for `microtodoui`, then run:

```bash
cd Infra
terraform apply -auto-approve

```

---

## 🔍 Day-2 Operations & Diagnostics

### Real-Time Container Application Logs

Monitor live FastAPI execution and runtime logs directly via Azure CLI:

```bash
az containerapp logs show \
  --name add-task-service \
  --resource-group rg-todo-microservices \
  --follow

```

### SQL Database Connection Verification

Verify that microservices are persisting data correctly by querying Azure SQL via Azure CLI or Query Editor:

```sql
-- Connect to Azure SQL Database Query Editor
SELECT * FROM Tasks;

```

```

```
