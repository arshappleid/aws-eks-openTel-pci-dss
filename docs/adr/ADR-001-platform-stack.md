# ADR-001: Platform Stack Selection

## Status
Proposed

## Context
Initial selection of core cloud, IaC, CI/CD, and orchestration technologies.

## Decision
Use AWS EKS, Terraform, GitOps with Argo CD, GitHub Actions.

## Consequences
Requires strong security scanning gates and credential federation via OIDC.
