%% sample_kb.pl - Wine-selection knowledge base for expert_shell
%%
%% If_/then_ style hypotheses: each condition is checked via
%% shell:check/1, which reuses known/2 answers or asks the user.
%% shell:load_kb/1 asserts these clauses into module `user` so the
%% shell can find them via user:hypothesis/1 and
%% user:hypothesis_explanation/2.

hypothesis(serve_port) :-
    shell:check(meal == dessert),
    shell:check(sweet_preference == yes).

hypothesis(serve_riesling) :-
    shell:check(sweet_preference == yes),
    \+ shell:known(meal, dessert).

hypothesis(serve_cabernet) :-
    shell:check(meal == red_meat),
    shell:check(bold_preference == yes).

hypothesis(serve_sauvignon_blanc) :-
    shell:check(meal == fish),
    shell:check(light_preference == yes).

hypothesis_explanation(serve_port,
    'A dessert meal plus a sweet preference points to port.').
hypothesis_explanation(serve_riesling,
    'A sweet preference without a dessert meal suggests riesling.').
hypothesis_explanation(serve_cabernet,
    'Red meat plus a bold preference points to cabernet sauvignon.').
hypothesis_explanation(serve_sauvignon_blanc,
    'Fish plus a light preference points to sauvignon blanc.').
