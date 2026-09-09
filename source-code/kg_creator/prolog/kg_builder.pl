%% kg_builder.pl - Build knowledge graphs programmatically and store
%% them as Prolog facts
:- module(kg_builder, [
    add_triple/3,
    query_triples/3,
    clear_all_triples/0,
    export_rdf/1,
    export_cypher/1
]).

:- dynamic triple/3.  % triple(Subject, Predicate, Object)

%% add_triple(+S, +P, +O)
%% Add a triple if not already present (always succeeds)
add_triple(S, P, O) :-
    (   triple(S, P, O)
    ->  true
    ;   assert(triple(S, P, O))
    ).

%% query_triples(?S, ?P, ?O)
query_triples(S, P, O) :- triple(S, P, O).

%% clear_all_triples - remove every triple from the store
clear_all_triples :-
    retractall(triple(_, _, _)).

%% export_rdf(+FileName) - Export triples as N-Triples RDF.
%% Object literals are escaped (" and \ and newlines); subject and
%% predicate must be minimal IRIs (non-empty, no spaces) -
%% otherwise export_rdf/1 fails with a message.
export_rdf(FileName) :-
    setup_call_cleanup(
        open(FileName, write, Stream),
        (   forall(
                triple(S, P, O),
                (   valid_iri(S), valid_iri(P)
                ->  escape_literal(O, EscO),
                    format(Stream, '<~w> <~w> "~w" .~n', [S, P, EscO])
                ;   format(user_error,
                        'export_rdf: invalid IRI in triple ~w~n',
                        [triple(S, P, O)]),
                    fail
                )
            )
        ),
        close(Stream)
    ).

valid_iri(A) :-
    (   atom(A) -> true ; string(A) ),
    A \= '',
    \+ sub_atom(A, _, _, _, ' ').

%% escape_literal(+In, -Out) - escape \ " and newline for N-Triples
escape_literal(In, Out) :-
    atom_chars(In, Chars),
    esc_chars(Chars, EscChars),
    atom_chars(Out, EscChars).

esc_chars([], []).
esc_chars(['\\'|Cs], ['\\','\\'|Esc]) :- !, esc_chars(Cs, Esc).
esc_chars(['"'|Cs], ['\\','"'|Esc]) :- !, esc_chars(Cs, Esc).
esc_chars(['\n'|Cs], ['\\','n'|Esc]) :- !, esc_chars(Cs, Esc).
esc_chars([C|Cs], [C|Esc]) :- esc_chars(Cs, Esc).

%% export_cypher(+FileName)
%% Export triples as Neo4j Cypher CREATE statements.  Node names and
%% relationship types are backtick-quoted; embedded backticks are
%% escaped by doubling.
export_cypher(FileName) :-
    setup_call_cleanup(
        open(FileName, write, Stream),
        (   forall(
                triple(S, P, O),
                (   backtick_quote(S, QS),
                    backtick_quote(P, QP),
                    backtick_quote(O, QO),
                    format(Stream, 'CREATE (~w)-[:~w]->(~w)~n',
                        [QS, QP, QO])
                )
            )
        ),
        close(Stream)
    ).

backtick_quote(A, Quoted) :-
    atom_chars(A, Chars),
    bt_chars(Chars, EscChars),
    atom_chars(Esc, EscChars),
    atom_concat('`', Esc, T),
    atom_concat(T, '`', Quoted).

bt_chars([], []).
bt_chars(['`'|Cs], ['`','`'|Esc]) :- !, bt_chars(Cs, Esc).
bt_chars([C|Cs], [C|Esc]) :- bt_chars(Cs, Esc).
