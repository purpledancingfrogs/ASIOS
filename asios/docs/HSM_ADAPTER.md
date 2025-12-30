# HSM Adapter Interface

This document defines the Hardware Security Module (HSM) adapter interface used by ASIOS/Aureon for cryptographic causal binding.

## Purpose
Bind kernel admission decisions to physical execution via non-exportable cryptographic keys.

## Interface (Python)

```python
from abc import ABC, abstractmethod
from typing import Dict, Any

class AureonHSMAdapter(ABC):
    @abstractmethod
    def sign_action(self, admission_token: str, action_payload: Dict[str, Any]) -> str:
        pass

    @abstractmethod
    def verify_integrity(self) -> bool:
        pass
````

## Requirements

* Non-exportable private key (HSM enclave)
* Deterministic payload canonicalization (RFC 8785)
* Downstream hardware must reject unsigned actions

## Versioning

* Reference interface introduced in v0.1.0
* Concrete implementations expected in v0.1.1+

## Summary

Mission → Admission → Cryptographic Binding → Execution
