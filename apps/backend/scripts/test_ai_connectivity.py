#!/usr/bin/env python3
"""
Standalone AI Connectivity Verification Script for Eureka.
Tests reachability of Google Gemini API using configured GEMINI_API_KEY (Free Tier).

Usage:
    python apps/backend/scripts/test_ai_connectivity.py
"""

import sys
import os
from pathlib import Path
import httpx

# Fix Windows console UTF-8 output encoding if available
if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Add project root to sys.path
root_dir = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(root_dir))

from apps.backend.core.config import settings


def test_gemini_model(model_name: str, test_label: str) -> bool:
    print(f"\n--- Testing Google Gemini ({test_label}: {model_name}) ---")
    api_key = settings.GEMINI_API_KEY or os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("[!] GEMINI_API_KEY is not set in environment or .env file.")
        print("    -> Get a FREE API key from: https://aistudio.google.com/")
        return False

    print(f"[*] Key detected: {api_key[:6]}...{api_key[-4:]}")
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
    headers = {
        "Content-Type": "application/json",
    }
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": f"Respond with '{test_label} connectivity verified' and nothing else."}
                ]
            }
        ]
    }

    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.post(url, headers=headers, json=payload)
            if response.status_code == 200:
                data = response.json()
                content = data["candidates"][0]["content"]["parts"][0]["text"].strip()
                print(f"[OK] Response from {model_name}: {content}")
                return True
            else:
                print(f"[FAIL] HTTP {response.status_code}: {response.text}")
                return False
    except Exception as e:
        print(f"[FAIL] Connection error: {str(e)}")
        return False


def main():
    print("=" * 60)
    print("[TEST] Eureka Google Gemini AI Connectivity Verification")
    print("=" * 60)
    
    fast_ok = test_gemini_model(settings.GEMINI_FAST_MODEL, "Fast Model")
    reasoning_ok = test_gemini_model(settings.GEMINI_REASONING_MODEL, "Reasoning Model")
    
    print("\n" + "=" * 60)
    print("Summary:")
    print(f"  - Fast Model ({settings.GEMINI_FAST_MODEL}):       {'[OK] READY' if fast_ok else '[!] FAILED / NOT CONFIGURED'}")
    print(f"  - Reasoning Model ({settings.GEMINI_REASONING_MODEL}):  {'[OK] READY' if reasoning_ok else '[!] FAILED / NOT CONFIGURED'}")
    print("=" * 60)
    
    if not (fast_ok and reasoning_ok):
        print("\nTip: Obtain your FREE Gemini API key from https://aistudio.google.com/ and set GEMINI_API_KEY in .env")


if __name__ == "__main__":
    main()
