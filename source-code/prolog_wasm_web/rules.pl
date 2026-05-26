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
    % Match preferences if specified (or allow any if 'any' is selected)
    (PreferredBody == any ; Body == PreferredBody),
    (PreferredSweetness == any ; Sweetness == PreferredSweetness),
    % Generate a human-readable explanation
    generate_explanation(Wine, Color, Body, Sweetness, Food,
        Explanation).

% Generate a beautiful explanation sentence
generate_explanation(Wine, Color, Body, Sweetness, Food, Explanation) :-
    format(string(Explanation), 
\          "Because you are eating ~w, a ~w wine is a classic pairing. ~w is a ~w, ~w ~w wine that perfectly matches your taste preferences.",
           [Food, Color, Wine, Body, Sweetness, Color]).
