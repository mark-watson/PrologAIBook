% rules.pl - Wine Recommendation Expert System for WASM

% Database of Wines: wine(Name, Color, Body, Sweetness)
wine(cabernet_sauvignon, red, full_body, dry).
wine(merlot, red, medium_body, dry).
wine(pinot_noir, red, light_body, dry).
wine(chardonnay, white, full_body, dry).
wine(sauvignon_blanc, white, medium_body, dry).
wine(riesling, white, light_body, sweet).
wine(moscato, white, light_body, sweet).
wine(port, red, full_body, sweet).
wine(sauternes, white, full_body, sweet).

% Pairing rules: pair(WineColor, FoodType)
pair(red, meat).
pair(red, cheese).
pair(white, fish).
pair(white, poultry).
pair(white, spicy_food).
pair(white, dessert).
pair(red, dessert).

% Recommend a wine based on food, body preference, and sweetness
% preference.
% Returns Wine name, its Color, and a justification string.
recommend(Food, PreferredBody, PreferredSweetness, Wine, Color,
    Explanation) :-
    wine(Wine, Color, Body, Sweetness),
    % Check food pairing compatibility
    pair(Color, Food),
    % Match preferences ('any' matches every value)
    matches(PreferredBody, Body),
    matches(PreferredSweetness, Sweetness),
    % Generate a human-readable explanation
    generate_explanation(Wine, Color, Body, Sweetness, Food,
        Explanation).

% matches(+Preference, +Value)
matches(any, _) :- !.
matches(Value, Value).

% Build an explanation sentence. Atoms such as full_body become
% words such as full-bodied.
generate_explanation(Wine, Color, Body, Sweetness, Food, Explanation) :-
    words(Wine, WineWords),
    words(Food, FoodWords),
    body_words(Body, BodyWords),
    format(string(Explanation),
           "A ~w wine is a classic pairing for ~w. ~w is a ~w, ~w ~w wine.",
           [Color, FoodWords, WineWords, BodyWords, Sweetness, Color]).

body_words(full_body, 'full-bodied').
body_words(medium_body, 'medium-bodied').
body_words(light_body, 'light-bodied').

% words(+Atom, -Text): replace underscores with spaces.
words(Atom, Text) :-
    atomic_list_concat(Parts, '_', Atom),
    atomic_list_concat(Parts, ' ', Text).
