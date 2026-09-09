%% shell.pl - Expert system shell with backward
%% chaining and explanations
:- module(shell, [
    consult_expert/1,
    explain/1,
    ask_question/1,
    provide_answer/2,
    reset_known/0,
    load_kb/1
]).

:- dynamic known/2.  % known(Attribute, Value) - user-provided facts

%% reset_known - Clear all user-provided answers
reset_known :-
    retractall(known(_, _)).

%% provide_answer(+Attribute, +Value)
%% Programmatically supply an answer (used by tests and non-interactive
%% drivers) instead of prompting the user.
provide_answer(Attribute, Value) :-
    retractall(known(Attribute, _)),
    assertz(known(Attribute, Value)).

%% consult_expert(-Conclusion) - Main entry point
%% When a KB has been loaded via load_kb/1, its hypothesis/1 rules
%% (in module user) are tried first; otherwise the built-in default
%% applies.  Answers provided earlier via provide_answer/2 are kept;
%% call reset_known/0 explicitly for a fresh consultation.
consult_expert(Conclusion) :-
    consult_kb_hypothesis(Conclusion),
    !.

consult_kb_hypothesis(Conclusion) :-
    kb_file(_),
    !,
    user:hypothesis(Conclusion).
consult_kb_hypothesis(Conclusion) :-
    hypothesis(Conclusion).

%% explain(+Conclusion) - Show reasoning chain
explain(Conclusion) :-
    explanation_text(Conclusion, Explanation),
    format("Conclusion: ~w~n", [Conclusion]),
    format("Reasoning: ~w~n", [Explanation]).

explanation_text(C, E) :-
    kb_file(_),
    user:hypothesis_explanation(C, E),
    !.
explanation_text(C, E) :-
    hypothesis_explanation(C, E).

%% ask_question(+Attribute) - Ask user for information
%% Reuse a known answer; otherwise read a line, strip a trailing '.',
%% and convert to an atom or number as appropriate.  EOF aborts the
%% consultation gracefully.
ask_question(Attribute) :-
    known(Attribute, Value),
    !,
    format("~w: (cached) ~w~n", [Attribute, Value]).
ask_question(Attribute) :-
    format("~nWhat is the value of ~w? ", [Attribute]),
    catch(read_line_to_string(user_input, Line),
          _, Line = end_of_file),
    (   Line == end_of_file
    ->  format("~nEOF reached; aborting consultation.~n"),
        fail
    ;   normalize_answer(Line, Value),
        provide_answer(Attribute, Value)
    ).

%% normalize_answer(+RawString, -Value)
%% Strip a trailing '.', try a numeric conversion, else produce an atom.
normalize_answer(Raw, Value) :-
    string_codes(Raw, Codes0),
    strip_trailing_dot(Codes0, Codes),
    string_codes(Term, Codes),
    (   catch(atom_number(Term, Value), _, fail)
    ->  true
    ;   atom_string(Value, Term)
    ).

strip_trailing_dot(Codes, Rest) :-
    append(Rest, [0'.], Codes),
    !.
strip_trailing_dot(Codes, Codes).

%% load_kb(+File) - Consult a knowledge-base file defining hypothesis/1
%% and hypothesis_explanation/2 rules (if_/then_ style conditions read
%% known/2 answers via check/1).  Clears previously loaded KB rules.
:- dynamic kb_file/1.

load_kb(File) :-
    retractall(kb_file(_)),
    unload_old_kb,
    assertz(kb_file(File)),
    open(File, read, In),
    repeat,
      read(In, Term),
      (   Term == end_of_file
      ->  close(In), !
      ;   assertz(user:Term),
          fail
      ).

unload_old_kb :-
    forall(clause(user:hypothesis(_), _, Ref), erase(Ref)),
    forall(clause(user:hypothesis_explanation(_, _), _, Ref),
           erase(Ref)),
    dynamic(user:hypothesis/1),
    dynamic(user:hypothesis_explanation/2).

%% check(+Condition) - True when the attribute has been answered as
%% requested, prompting via ask_question/1 when not yet known.
check(A == V) :- !,
    (   known(A, V)
    ->  true
    ;   \+ known(A, _),
        ask_question(A),
        known(A, V)
    ).

%% Default hypothesis rules (used when no KB is loaded)
hypothesis(unknown) :-
    format("Could not determine a conclusion from the given facts.~n").

hypothesis_explanation(
    unknown,
    'Insufficient data to reach a conclusion.').
