# Orchestrator Skill

Purpose:

- classify the incoming request
- identify missing information
- produce a valid scenario file
- route the scenario to the correct specialist skill

Inputs:

- user request
- optional existing scenario file
- repository knowledge and policies

Outputs:

- completed scenario YAML
- selected worker list
- handoff notes for execution
