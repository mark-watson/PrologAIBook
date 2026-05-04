%% wine_rules.pl - Wine selection expert system
:- module(wine_rules, [
    recommend_wine/3
]).

%% recommend_wine(+MealType, +Preference, -Wine)
recommend_wine(MealType, Preference, Wine) :-
    wine(Wine, Color, Body, _Sweetness),
    meal_pairs_with(MealType, Color),
    preference_matches(Preference, Body).

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

%% Preference matching
preference_matches(bold, full).
preference_matches(moderate, medium).
preference_matches(light, light).
preference_matches(any, _).
