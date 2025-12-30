# HSM Adapter Interface

This document defines the reference interface for a Hardware Security Module (HSM)
used by ASIOS to provide cryptographic causal binding between kernel admission and
physical execution.

## Purpose
Bind **Mission → Admission → Cryptographic Signature → Execution** with no bypass path.

## Interface (Python)

from abc import ABC, abstractmethod
from typing import Dict, Any

class AureonHSMAdapter(ABC):
    @abstractmethod
    def sign_action(self, admission_token: str, action_payload: Dict[str, Any]) -> str:
        pass

    @abstractmethod
    def verify_integrity(self) -> bool:
        pass

## Requirements
- Non-exportable private key (HSM enclave)
- Deterministic payload canonicalization (RFC 8785)
- Downstream hardware must reject unsigned actions

## Versioning
- Reference interface introduced in v0.1.0
- Concrete implementations expected in v0.1.1+

