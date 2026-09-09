"""nlp_bridge.py - Python-side bridge for Janus Hybrid NLP Pipeline"""

# Load spaCy, fallback gracefully if not installed
try:
    import spacy
    nlp = spacy.load("en_core_web_sm")
except (ImportError, Exception):
    spacy = None
    nlp = None


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
