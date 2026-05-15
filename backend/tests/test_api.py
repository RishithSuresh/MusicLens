from dataclasses import replace
from pathlib import Path
import sys

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import main


client = TestClient(main.app)


def test_health_endpoint() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert "runtime_env" in payload
    assert "features" in payload


def test_ready_endpoint() -> None:
    response = client.get("/ready")
    assert response.status_code == 200
    payload = response.json()
    assert "status" in payload
    assert "dependencies" in payload
    assert "analyzer_available" in payload["dependencies"]
    assert "composer_available" in payload["dependencies"]


def test_analyze_rejects_non_audio_upload() -> None:
    response = client.post(
        "/analyze",
        files={"file": ("note.txt", b"not-audio", "text/plain")},
    )
    assert response.status_code == 400
    assert "audio file" in response.json()["detail"]


def test_analyze_rejects_empty_audio_upload() -> None:
    response = client.post(
        "/analyze",
        files={"file": ("track.wav", b"", "audio/wav")},
    )
    assert response.status_code == 400
    assert "empty" in response.json()["detail"].lower()


def test_compose_respects_prompt_length_limit() -> None:
    original_settings = main.settings
    main.settings = replace(main.settings, max_prompt_chars=20)
    try:
        response = client.post(
            "/compose",
            json={"prompt": "A very long prompt that should exceed the configured cap", "use_llm": False},
        )
    finally:
        main.settings = original_settings

    assert response.status_code == 400
    assert "max length" in response.json()["detail"]
