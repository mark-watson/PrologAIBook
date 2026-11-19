%% repair_loop.pl - Ask an LLM for a portfolio, check it with the
%% guardrails, and send any violations back for a corrected answer.
:- module(repair_loop, [
    safe_portfolio/4,
    safe_portfolio/5
]).

:- use_module(guardrails).
:- use_module('../../llm_client/prolog/gemini').

%% safe_portfolio(+Age, +Risk, +MaxTries, -Json)
%% Json is an LLM recommendation for a client of the given Age and
%% risk tolerance (low, medium, or high) that passes every guardrail.
%% Each failed attempt is printed, and its violations go into the next
%% prompt. Fails if no attempt passes within MaxTries.
safe_portfolio(Age, Risk, MaxTries, Json) :-
    safe_portfolio(Age, Risk, "", MaxTries, Json).

%% safe_portfolio(+Age, +Risk, +Request, +MaxTries, -Json)
%% As safe_portfolio/4, with an extra client request (text) added to
%% the prompt. A request can conflict with the rules, for example
%% "The client wants 25% in crypto."; the guardrails still decide.
safe_portfolio(Age, Risk, Request, MaxTries, Json) :-
    first_prompt(Age, Risk, Request, Prompt),
    attempt(Prompt, 1, MaxTries, Json).

attempt(Prompt, N, Max, Json) :-
    N =< Max,
    gemini_generate(Prompt, Reply, [json(true), temperature(0.7)]),
    validate_portfolio_json(Reply, Errors),
    (   Errors == []
    ->  format("Attempt ~w passed the guardrails.~n", [N]),
        Json = Reply
    ;   format("Attempt ~w rejected:~n", [N]),
        forall(member(E, Errors), format("  - ~w~n", [E])),
        repair_prompt(Prompt, Reply, Errors, Prompt1),
        N1 is N + 1,
        attempt(Prompt1, N1, Max, Json)
    ).

first_prompt(Age, Risk, Request, Prompt) :-
    format(string(Prompt),
"Recommend an investment portfolio for a client aged ~w with ~w risk
tolerance. ~w
Reply with JSON only, in this form:
{\"client_age\": ~w, \"risk_tolerance\": \"~w\",
 \"allocations\": {\"stocks\": N, \"bonds\": N, \"crypto\": N, \"cash\": N}}
where each N is a whole-number percentage.",
           [Age, Risk, Request, Age, Risk]).

%% The repair prompt repeats the request, shows the rejected answer,
%% and lists the rules it broke, word for word.
repair_prompt(Prompt, Reply, Errors, Prompt1) :-
    atomic_list_concat(Errors, '\n- ', ErrorText),
    format(string(Prompt1),
"~w

Your previous answer was:
~w
It broke these rules:
- ~w
Reply with a corrected JSON portfolio that follows every rule.",
           [Prompt, Reply, ErrorText]).
