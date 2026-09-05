# DevInsight

## An AI-Powered Software Engineering Intelligence Platform for Project Risk Prediction and Root Cause Analysis

DevInsight is a research project that aims to help software development teams **predict software errors, prioritize them based on project context, explain the reasons behind predictions, and provide AI-powered recommendations**.

The core research process is:

**Predict → Prioritize → Explain → Recommend**

The overall concept is:

**Technical Intelligence → Project Intelligence → Decision Intelligence**

---

## Research Focus

DevInsight focuses on:

- Software Error and Risk Prediction
- Machine Learning
- Project-Aware Error Prioritization
- Explainable AI (XAI)
- Developer Workload Analysis
- Project Requirements
- AI-Powered Recommendations

The main research idea is to move beyond simply predicting code errors by considering the **importance of the error within the actual software project**.

For example, a high-risk error affecting a critical client requirement should receive greater attention than a similar-risk error affecting a low-priority feature.

---

## System Workflow

```text
GitHub Repository
        ↓
Data Collection
        ↓
Data Cleaning & Processing
        ↓
Feature Engineering
        ↓
ML Error Risk Prediction
        ↓
Project-Aware Error Prioritization
        ↓
XAI Explanation
        ↓
AI Recommendation
        ↓
Web Dashboard + Mobile Application
```

---

## Main Components

### 1. Repository Data Collection

Data will be collected from GitHub repositories, including:

- Commits
- Code changes
- Issues
- Pull Requests
- CI/CD information
- Developer activity

### 2. Error Risk Prediction

Machine-learning models will analyze repository-derived features to predict whether files or code changes are likely to be defect-prone.

Candidate models include:

- Logistic Regression
- Random Forest
- XGBoost

### 3. Error Prioritization

Predicted risk will be combined with project-related information such as:

- Error severity
- Client requirements
- Requirement importance
- Developer workload
- CI/CD failures
- Project deadlines

This produces a **project-aware priority** rather than relying only on prediction probability.

### 4. Explainable AI

Techniques such as **SHAP and LIME** will be investigated to explain the factors that contribute to individual predictions.

### 5. AI Recommendations

An LLM will use the structured prediction, prioritization, explanation, and project-context information to generate grounded recommendations.

The LLM will act as a **recommendation and communication layer**, not as the primary error-prediction model.

---

## Technology Stack

### Machine Learning & Data Processing

- Python
- Pandas
- NumPy
- Scikit-learn
- XGBoost

### Explainable AI

- SHAP
- LIME

### Software Analysis

- Pylint
- ESLint
- Dart Analyzer

### Repository Data

- GitHub REST API
- GitHub GraphQL API
- GitHub Actions API

### Database & Backend

- Supabase
- PostgreSQL

### Applications

- Flutter
- Dart

### Generative AI

- LLM API

---

## Dataset

The primary dataset will be constructed using **public GitHub repositories**.

The initial target is approximately **10–20 repositories**, with multiple programming languages and sufficient development history for machine-learning experiments.

The research will focus on obtaining sufficient historical observations rather than relying only on a small number of manually created code files.

A controlled repository may also be used for testing the data collection and analysis pipeline.

---

## Web Dashboard

The web dashboard is designed mainly for **project managers**.

It will provide information related to:

- Project overview
- Software risks
- Error prioritization
- Project requirements
- Developer workload
- Delivery risk
- XAI explanations
- AI recommendations

---

## Mobile Application

The mobile application is designed mainly for **developers**.

It will focus on:

- Assigned high-priority errors
- Error risk information
- Error explanations
- Alerts
- Recommended actions

---

## Research Questions

### RQ1

How accurately can machine-learning models identify defect-prone software files or changes using repository-derived information?

### RQ2

To what extent does combining technical risk with project requirements, severity, CI/CD information, developer workload, and delivery context support project-aware prioritization compared with technical-risk ranking alone?

### RQ3

How useful are traceable explanations and grounded AI-generated recommendations in helping developers and project managers determine which software problems deserve attention and what actions they should consider?

---

## Research Contribution

The main research contribution is not simply combining GitHub, Machine Learning, XAI, and LLM technologies.

DevInsight investigates how **technical software-risk evidence can be transformed into project-aware and explainable decision support**.

The proposed intelligence model is:

```text
Technical Evidence
        ↓
Technical Intelligence
        ↓
Project Context
        ↓
Project Intelligence
        ↓
Explainable Evidence
        ↓
Decision Intelligence
        ↓
Human Decision
```

The central research idea is:

> **Technical risk does not always equal project priority.**

DevInsight investigates whether adding project context and traceable AI recommendations can provide better support for software-project decision making.

---

## Current Project Status

- Project proposal completed
- Proposal presentation completed
- Proposal viva completed
- Research article prepared
- Initial code-error creation and Pylint testing completed
- UI/UX design started
- Dataset preparation in progress
- ML pipeline development in progress

---

## Project Structure

```text
DevInsight/
│
├── data/
├── notebooks/
├── src/
├── web/
├── mobile/
├── database/
├── docs/
└── tests/
```

---

## Team

**Final Year Project – Group 9**

---

> **Note:** DevInsight is currently under development as a research project. Machine-learning performance, prioritization effectiveness, and AI recommendation quality will be validated through the planned experiments and evaluation.
