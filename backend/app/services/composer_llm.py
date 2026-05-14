"""Optional LangGraph-driven enhancement layer for the music composer.

Wraps the deterministic procedural engine with an LLM workflow that
interprets the user's prompt into structured musical parameters and writes a
human-readable narrative. Falls back gracefully to keyword heuristics when
``langgraph`` / ``langchain-openai`` / ``OPENAI_API_KEY`` are unavailable.
"""
from __future__ import annotations

import json
import os
from dataclasses import dataclass

GENRE_KEYWORDS: dict[str, tuple[str, ...]] = {
    "jazz": ("jazz", "swing", "bebop", "blue note"),
    "blues": ("blues", "bluesy"),
    "lofi": ("lofi", "lo-fi", "chill", "study", "rainy"),
    "cinematic": ("cinematic", "epic", "trailer", "soundtrack", "hero"),
    "classical": ("classical", "baroque", "romantic era", "sonata", "concerto"),
    "electronic": ("electronic", "edm", "techno", "house", "synth", "dance"),
    "folk": ("folk", "acoustic", "country", "ballad"),
    "ambient": ("ambient", "drone", "atmospheric", "meditative"),
    "rock": ("rock", "metal", "punk", "grunge"),
    "pop": ("pop", "catchy", "radio"),
}

MOOD_KEYWORDS: dict[str, tuple[str, ...]] = {
    "joyful":   ("happy", "joy", "uplifting", "bright", "cheerful", "sunny"),
    "melancholic": ("sad", "melancholy", "blue", "lonely", "wistful", "rainy"),
    "energetic": ("energetic", "powerful", "intense", "driving", "fast", "explosive"),
    "calm":     ("calm", "peaceful", "gentle", "soft", "relaxing", "meditative"),
    "epic":     ("epic", "cinematic", "heroic", "triumphant", "grand"),
    "dark":     ("dark", "ominous", "haunting", "eerie", "mysterious"),
    "romantic": ("romantic", "love", "tender", "intimate"),
}

MOOD_TO_MODE: dict[str, str] = {
    "joyful": "major", "energetic": "mixolydian", "epic": "minor",
    "melancholic": "minor", "calm": "lydian", "dark": "phrygian",
    "romantic": "major",
}

MOOD_TO_TEMPO: dict[str, int] = {
    "joyful": 120, "energetic": 140, "epic": 96, "melancholic": 72,
    "calm": 70, "dark": 80, "romantic": 84,
}


@dataclass
class InterpretedPrompt:
    genre: str
    mood: str
    mode: str
    tempo_bpm: int
    key: str
    style: str
    bars: int
    used_llm: bool


def _bounded_int(value: object, *, default: int, minimum: int, maximum: int) -> int:
    """Safely parse ``value`` as int and clamp to [minimum, maximum]."""
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return default
    return max(minimum, min(maximum, parsed))


def _heuristic_interpret(prompt: str, overrides: dict) -> InterpretedPrompt:
    text = prompt.lower()
    genre = next((g for g, kws in GENRE_KEYWORDS.items() if any(k in text for k in kws)), "pop")
    mood = next((m for m, kws in MOOD_KEYWORDS.items() if any(k in text for k in kws)), "joyful")
    mode = overrides.get("mode") or MOOD_TO_MODE.get(mood, "major")
    tempo = overrides.get("tempo_bpm") or MOOD_TO_TEMPO.get(mood, 110)
    key = overrides.get("key") or ("A" if mode == "minor" else "C")
    bars = overrides.get("bars") or 16
    style = overrides.get("style") or genre
    return InterpretedPrompt(genre, mood, mode, int(tempo), key, style, int(bars), used_llm=False)


def _llm_available() -> bool:
    if not os.environ.get("OPENAI_API_KEY"):
        return False
    try:
        import langgraph  # noqa: F401
        import langchain_openai  # noqa: F401
        return True
    except Exception:  # noqa: BLE001
        return False


def _llm_interpret(prompt: str, overrides: dict) -> InterpretedPrompt | None:
    """Run a tiny LangGraph workflow that returns interpreted music parameters."""
    try:
        from typing import TypedDict

        from langchain_core.prompts import ChatPromptTemplate
        from langchain_openai import ChatOpenAI
        from langgraph.graph import END, StateGraph

        class S(TypedDict):
            prompt: str
            interpretation: dict

        llm = ChatOpenAI(model=os.environ.get("MUSICLENS_LLM_MODEL", "gpt-4o-mini"), temperature=0.7)
        interpret_prompt = ChatPromptTemplate.from_template(
            "You are a music director. Interpret the request and return ONLY valid JSON with keys: "
            "genre (one of pop, rock, jazz, blues, lofi, cinematic, classical, electronic, folk, ambient), "
            "mood (one of joyful, melancholic, energetic, calm, epic, dark, romantic), "
            "mode (one of major, minor, dorian, mixolydian, lydian, phrygian, harmonic_minor), "
            "tempo_bpm (integer 50-180), key (one of C, C#, D, Eb, E, F, F#, G, Ab, A, Bb, B), "
            "style (short label), bars (integer 8-32). Request: {prompt}"
        )

        def interpret_node(state: S) -> dict:
            chain = interpret_prompt | llm
            raw = chain.invoke({"prompt": state["prompt"]}).content
            try:
                start = raw.find("{")
                end = raw.rfind("}")
                data = json.loads(raw[start : end + 1])
            except Exception:  # noqa: BLE001
                data = {}
            return {"interpretation": data}

        workflow = StateGraph(S)
        workflow.add_node("interpret", interpret_node)
        workflow.set_entry_point("interpret")
        workflow.add_edge("interpret", END)
        result = workflow.compile().invoke({"prompt": prompt, "interpretation": {}})
        data = result.get("interpretation") or {}
        if not data:
            return None
        return InterpretedPrompt(
            genre=str(data.get("genre", "pop")),
            mood=str(data.get("mood", "joyful")),
            mode=overrides.get("mode") or str(data.get("mode", "major")),
            tempo_bpm=_bounded_int(
                overrides.get("tempo_bpm") or data.get("tempo_bpm", 110),
                default=110,
                minimum=40,
                maximum=220,
            ),
            key=overrides.get("key") or str(data.get("key", "C")),
            style=overrides.get("style") or str(data.get("style", "modern")),
            bars=_bounded_int(
                overrides.get("bars") or data.get("bars", 16),
                default=16,
                minimum=4,
                maximum=64,
            ),
            used_llm=True,
        )
    except Exception:  # noqa: BLE001
        return None


def interpret_prompt(prompt: str, *, use_llm: bool, overrides: dict) -> InterpretedPrompt:
    if use_llm and _llm_available():
        result = _llm_interpret(prompt, overrides)
        if result is not None:
            return result
    return _heuristic_interpret(prompt, overrides)


def write_narrative(prompt: str, interp: InterpretedPrompt, progression: list[str]) -> str:
    if interp.used_llm:
        try:
            from langchain_core.prompts import ChatPromptTemplate
            from langchain_openai import ChatOpenAI
            llm = ChatOpenAI(model=os.environ.get("MUSICLENS_LLM_MODEL", "gpt-4o-mini"), temperature=0.8)
            template = ChatPromptTemplate.from_template(
                "Describe the following short composition for a listener in 3-4 vivid sentences. "
                "Request: {prompt}. Genre: {genre}. Mood: {mood}. Key: {key} {mode}. Tempo: {tempo} BPM. "
                "Chord progression: {progression}."
            )
            chain = template | llm
            return chain.invoke({
                "prompt": prompt, "genre": interp.genre, "mood": interp.mood,
                "key": interp.key, "mode": interp.mode, "tempo": interp.tempo_bpm,
                "progression": ", ".join(progression[:8]),
            }).content.strip()
        except Exception:  # noqa: BLE001
            pass
    progression_text = " - ".join(progression[:6]) if progression else "diatonic motion"
    return (
        f"A {interp.mood} {interp.genre} piece in {interp.key} {interp.mode} at {interp.tempo_bpm} BPM. "
        f"It opens softly, develops through {progression_text}, and resolves back to the tonic. "
        f"The arrangement layers a melodic lead, harmonic pad, walking bass, and a {interp.genre}-inspired "
        f"drum groove to support the {interp.mood} character."
    )
