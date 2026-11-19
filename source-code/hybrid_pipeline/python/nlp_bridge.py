"""nlp_bridge.py - Python-side bridge for Janus Hybrid NLP Pipeline"""

import warnings

# The macOS system Python links an old LibreSSL; urllib3 (pulled in by
# spaCy) warns about it on import. The warning does not affect NER.
warnings.filterwarnings("ignore", message=".*OpenSSL.*")

# Load spaCy and its small English model; fall back to simple rules if
# either is missing.
try:
    import spacy
    nlp = spacy.load("en_core_web_sm")
except Exception:
    spacy = None
    nlp = None


def backend():
    """Name of the NER method in use: 'spacy' or 'rules'."""
    return "spacy" if nlp is not None else "rules"


def _dict_entity(text, label):
    """One entity as a plain dict; Janus converts dicts to Prolog dicts."""
    return {'text': text, 'label': label}


def mock_entities(text):
    """Rule-based fallback used when spaCy (or its model) is unavailable.

    Public so the test suite can exercise the fallback explicitly.
    """
    entities = []
    for word in text.split():
        clean = word.strip(",.")
        if clean in ["John", "Smith"]:
            entities.append(_dict_entity(clean, "PERSON"))
        elif clean in ["London", "Paris"]:
            entities.append(_dict_entity(clean, "GPE"))
    return entities


def extract_entities(text):
    """Extract Named Entities from text. Uses spaCy or a mock rule-based
    fallback. Returns a list of {'text': str, 'label': str} dicts so both
    paths hand Prolog the exact same shape."""
    if nlp is None:
        return mock_entities(text)
    doc = nlp(text)
    return [_dict_entity(ent.text, ent.label_) for ent in doc.ents]
