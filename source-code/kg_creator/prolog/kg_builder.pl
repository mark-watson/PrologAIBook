%% kg_builder.pl - Build knowledge graphs programmatically and store
%% them as Prolog facts
:- module(kg_builder, [
    add_triple/3,
    query_triples/3,
    clear_all_triples/0,
    export_rdf/1,
    export_rdf/2,
    export_cypher/1
]).

:- dynamic triple/3.  % triple(Subject, Predicate, Object)

%% add_triple(+S, +P, +O)
%% Add a triple if not already present (always succeeds)
add_triple(S, P, O) :-
    (   triple(S, P, O)
    ->  true
    ;   assertz(triple(S, P, O))
    ).

%% query_triples(?S, ?P, ?O)
query_triples(S, P, O) :- triple(S, P, O).

%% clear_all_triples - remove every triple from the store
clear_all_triples :-
    retractall(triple(_, _, _)).

%% export_rdf(+FileName)
%% export_rdf(+FileName, +BaseIRI)
%% Export triples as N-Triples RDF. N-Triples needs absolute IRIs, so
%% each name becomes BaseIRI followed by the name (the default base is
%% http://example.org/kg/). An object that is an atom with no spaces
%% names a resource and becomes an IRI; any other object (a string, a
%% number, or an atom with spaces) becomes a literal, with \, " and
%% newlines escaped. A subject or predicate that is not a valid name
%% makes export_rdf fail with a message.
export_rdf(FileName) :-
    export_rdf(FileName, 'http://example.org/kg/').

export_rdf(FileName, Base) :-
    setup_call_cleanup(
        open(FileName, write, Stream),
        forall(triple(S, P, O),
               write_ntriple(Stream, Base, S, P, O)),
        close(Stream)
    ).

write_ntriple(Stream, Base, S, P, O) :-
    (   valid_name(S), valid_name(P)
    ->  rdf_object(Base, O, OText),
        format(Stream, '<~w~w> <~w~w> ~w .~n', [Base, S, Base, P, OText])
    ;   format(user_error, 'export_rdf: invalid name in triple ~w~n',
               [triple(S, P, O)]),
        fail
    ).

valid_name(A) :-
    atom(A),
    A \== '',
    \+ sub_atom(A, _, _, _, ' ').

rdf_object(Base, O, Text) :-
    valid_name(O),
    !,
    format(atom(Text), '<~w~w>', [Base, O]).
rdf_object(_, O, Text) :-
    escape_literal(O, Esc),
    format(atom(Text), '"~w"', [Esc]).

%% escape_literal(+In, -Out) - escape \ " and newline for N-Triples
escape_literal(In, Out) :-
    format(atom(A), '~w', [In]),
    atom_chars(A, Chars),
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
    format(atom(A1), '~w', [A]),
    atom_chars(A1, Chars),
    bt_chars(Chars, EscChars),
    atom_chars(Esc, EscChars),
    atom_concat('`', Esc, T),
    atom_concat(T, '`', Quoted).

bt_chars([], []).
bt_chars(['`'|Cs], ['`','`'|Esc]) :- !, bt_chars(Cs, Esc).
bt_chars([C|Cs], [C|Esc]) :- bt_chars(Cs, Esc).
