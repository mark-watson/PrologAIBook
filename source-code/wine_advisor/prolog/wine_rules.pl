%% wine_rules.pl - Wine selection expert system
:- module(wine_rules, [
    recommend_wine/3
]).

%% recommend_wine(+MealType, +Preference, -Wine)
%% Preference may be a body atom (bold, moderate, light), a sweetness
%% atom (sweet, dry), or 'any' matching all wines on both dimensions.
recommend_wine(MealType, Preference, Wine) :-
    wine(Wine, Color, Body, Sweetness),
    meal_pairs_with(MealType, Color),
    preference_matches(Preference, Body),
    sweetness_matches(Preference, Sweetness).

%% Wine database: wine(Name, Color, Body, Sweetness)
wine(cabernet_sauvignon, red, full, dry).
wine(merlot, red, medium, dry).
wine(pinot_noir, red, light, dry).
wine(chardonnay, white, full, dry).
wine(sauvignon_blanc, white, light, dry).
wine(riesling, white, light, sweet).
wine(champagne, white, light, dry).
wine(rose, rose, light, dry).
wine(port, red, full, sweet).

%% Meal pairing rules
meal_pairs_with(red_meat, red).
meal_pairs_with(poultry, red).
meal_pairs_with(poultry, white).
meal_pairs_with(fish, white).
meal_pairs_with(seafood, white).
meal_pairs_with(pasta, red).
meal_pairs_with(dessert, white).
meal_pairs_with(cheese, red).

%% Preference matching: body dimension.
%% Sweetness preferences (sweet, dry) do not constrain body.
preference_matches(bold, full).
preference_matches(moderate, medium).
preference_matches(light, light).
preference_matches(sweet, _).
preference_matches(dry, _).
preference_matches(any, _).

%% Sweetness matching.
%% Body preferences (bold, moderate, light) do not constrain sweetness.
sweetness_matches(sweet, sweet).
sweetness_matches(dry, dry).
sweetness_matches(bold, _).
sweetness_matches(moderate, _).
sweetness_matches(light, _).
sweetness_matches(any, _).
