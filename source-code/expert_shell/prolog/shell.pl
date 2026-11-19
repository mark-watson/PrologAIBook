%% shell.pl - Expert system shell with backward
%% chaining and explanations
:- module(shell, [
    consult_expert/1,
    explain/1,
    ask_question/1,
    provide_answer/2,
    reset_known/0,
    load_kb/1,
    op(1100, fx, if),
    op(1050, xfx, then),
    op(1000, xfy, and)
]).

%% Operators for knowledge bases written as readable rules:
%%   if meal is dessert and sweet_preference is yes then serve_port.
%% is/2 is already a standard operator (priority 700).

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
    (   user:hypothesis(Conclusion)
    ;   kb_rule(Conclusion, Conditions),
        maplist(check, Conditions)
    ).
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
    kb_rule(C, Conditions),
    maplist(known_condition, Conditions),
    !,
    maplist(condition_text, Conditions, Texts),
    atomic_list_concat(Texts, ' and ', Because),
    format(atom(E), '~w because ~w.', [C, Because]).

explanation_text(C, E) :-
    hypothesis_explanation(C, E).

%% known_condition/1 and condition_text/2 build the text of an
%% explanation from the conditions of the rule that fired.
known_condition(A == V) :- known(A, V).

condition_text(A == V, Text) :-
    format(atom(Text), '~w is ~w', [A, V]).

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

%% load_kb(+File) - Load a knowledge-base file and clear any KB
%% loaded before. The file may hold two kinds of terms:
%%   - Prolog clauses for hypothesis/1 and hypothesis_explanation/2,
%%     whose conditions call shell:check/1. These go into module user.
%%   - Readable rules such as
%%       if meal is dessert and sweet_preference is yes then serve_port.
%%     These become kb_rule(Conclusion, Conditions) facts.
%% Terms are read with this module's operators, so the file needs no
%% op/3 directives.
:- dynamic kb_file/1, kb_rule/2.

load_kb(File) :-
    retractall(kb_file(_)),
    unload_old_kb,
    assertz(kb_file(File)),
    setup_call_cleanup(
        open(File, read, In),
        load_terms(In),
        close(In)).

load_terms(In) :-
    read_term(In, Term, [module(shell)]),
    (   Term == end_of_file
    ->  true
    ;   add_kb_term(Term),
        load_terms(In)
    ).

add_kb_term(if Conds then Conclusion) :- !,
    and_list(Conds, Conditions),
    assertz(kb_rule(Conclusion, Conditions)).
add_kb_term(Term) :-
    assertz(user:Term).

%% and_list(+AndTerm, -Conditions): a is b and c is d gives
%% [a == b, c == d], the form check/1 expects.
and_list(A and B, [C|Cs]) :- !,
    is_condition(A, C),
    and_list(B, Cs).
and_list(A, [C]) :-
    is_condition(A, C).

is_condition(Attr is Value, Attr == Value).

unload_old_kb :-
    retractall(kb_rule(_, _)),
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
