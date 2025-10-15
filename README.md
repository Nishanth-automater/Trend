LOADBALANCER URL FOR APPLICATION
http://a86bf4ad5d2eb45968e942c94c2edcc8-827676824.us-west-2.elb.amazonaws.com/

GOOGLE DOCS URL SETUP INSTRUCTION
https://docs.google.com/document/d/1F_tFaTxlSyk7oPDWdsor3zcts2myD7orRultAoYSRrs/edit?usp=sharing

PIPELINE SETUP

# Trend Application – CI/CD Pipeline Setup

**Overview

This project automates the end-to-end deployment of a React application to AWS EKS using Jenkins, Docker, and Terraform.
The pipeline builds, pushes, and deploys the containerized application into Kubernetes with a single commit trigger.


Jenkins Pipeline Explanation

**Pipeline Type**

* Declarative Jenkins Pipeline (configured in Jenkinsfile).
* Triggered automatically via GitHub webhook on each commit.

Pipeline Stages

| Stage                  | Description                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------------- |
| **Checkout**           | Clones the `main` branch from GitHub using Jenkins credentials.                                      |
| **Build Docker Image** | Builds Docker image from the application source code.                                                |
| **Push to DockerHub**  | Logs into DockerHub using Jenkins credentials and pushes the image (`nishanth420/trend-app:latest`). |
| **Deploy to EKS**      | Applies Kubernetes manifests (`deployment.yml`, `service.yml`) to deploy the new image.              |

Post Actions

* On success → Logs “Deployment to EKS successful!”
* On failure → Displays pipeline failure message in Jenkins console.

