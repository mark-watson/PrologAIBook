% mock_janus.pl — pure-Prolog replacement for library(janus) py_call/2.
% Consulted by tests/test_pipeline.pl only when the real Janus foreign
% library fails to dlopen (e.g. mismatched Python3.framework RPATH).
% It mocks exactly the calls the pipeline makes:
%   nlp_bridge:extract_entities(Text)
%   nlp_bridge:mock_entities(Text)
% The entities mirror the rule-based fallback in python/nlp_bridge.py.

:- multifile(janus:py_call/2).

janus:py_call(nlp_bridge:extract_entities(Text), Entities) :-
    mock_py_entities(Text, Entities).
janus:py_call(nlp_bridge:mock_entities(Text), Entities) :-
    mock_py_entities(Text, Entities).

mock_py_entities(Text, Entities) :-
    split_string(Text, " \t\n", " \t\n", Tokens),
    findall(_{text: W, label: L},
        (   member(Tok, Tokens),
            normalize_space(atom(A), Tok),
            atom_string_clean(A, W),
            W \= '',
            once(mock_label(W, L))
        ),
        Entities).

% Split out a trailing period or comma, matching nlp_bridge's
% word.strip(",.") behaviour.
atom_string_clean(A0, A) :-
    atom_concat(A, '.', A0), !.
atom_string_clean(A0, A) :-
    atom_concat(A, ',', A0), !.
atom_string_clean(A, A).

mock_label('John',   'PERSON').
mock_label('Smith',  'PERSON').
mock_label('London', 'GPE').
mock_label('Paris',  'GPE').
