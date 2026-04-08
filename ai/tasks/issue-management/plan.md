# Plan: Tooling for Managing issues for Mind Mazeish

## Context 

The project has a [feedback feature](../../../lib/features/feedback) that allows users to publish tagged issues. 

To support rapid updates and iterations, claude skills are needed to:
- read issues
- plan updates 
- use the correct tooling for each issue type
- publish changes addressing the issue
- update issues with structured "user intent" comments to confirm agent understanding
- communicate issue status via comments on the issue

---
### initial user prompt

- read through the repo to understand the types of issues and how they are published.
- propose workflows for addressing each feedback type, including quality gates for resolved issues.
- propose a set of skills for reading, understanding, verifying, planning, executing changes and publishing structured prs addressing issues.
- propose a set of skills for communicating what the agent understands about the issue, the path it will take to investigate it, the plan to resolve it and a summary of the resolution after the pr is published.
- for each proposed skill, include any useful code tools, templates and examples/resources that reduce an agents token usage or streamline its workflow.
- propose contributing standard for this repo to streamline all work done on this project, especially by ai agents. this should be done with a CONTRIBUTING.md file in the project root.
- propose ai agent task research and planning documentation standards utilising the ai/tasks directory. this should include naming conventions, directory structure and a skill/claude.md instruction for using it.  
- propose testing standards and coverage gateways for this project to reduce and prevent bug reports.
- for each proposal, create a proposal doc in ai/tasks/issue-management/proposal
- rewrite this planning doc with a plan to implement these proposals.

all proposals an plans should be clear and concise to reduce verbosity while communicating exactly what will be done. ([example](../../../ai/tasks/question-maintainence/skills-and-models-plan.md))

---