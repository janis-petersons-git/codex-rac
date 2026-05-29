# Unit Test Skill

Purpose:

- derive test cases from scenario inputs and generated artifacts
- produce Postman or SOAP UI collections
- define happy-path and negative-path assertions

Primary knowledge sources:

- `docs/session-bootstrap.md`
- `knowledge/cpi/agent-operation.md`
- `examples/runtime/sample-runtime-test-payload.json`
- `examples/runtime/sample-stock-response.xml`
- `examples/runtime/sample-stock-response-rearranged.xml`

Required behavior:

- derive test payloads and expected responses from structured examples or scenario inputs
- keep runtime request and response fixtures sanitized and reusable
- make assertions explicit for both transport success and business payload correctness
- update the repo when a reusable test-fixture or assertion pattern is discovered