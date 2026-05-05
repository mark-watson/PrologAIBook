# Wine Advisor

A wine recommendation expert system using meal pairing rules and taste preferences. Companion code for the Expert Systems chapter.

## Running Examples

```shell
cd source-code/wine_advisor
swipl -s load.pl
```

```prolog
?- recommend_wine(red_meat, bold, Wine).
?- recommend_wine(fish, light, Wine).
?- recommend_wine(poultry, any, Wine).
```

## Running Tests

```shell
swipl -g "['tests/test_wine.pl'], run_tests, halt" -s load.pl
```

## Description

A concrete expert system case study that recommends wines based on meal type and taste preference. The knowledge base contains wine facts (`wine/4` with name, color, body, and sweetness), meal pairing rules (`meal_pairs_with/2`), and preference matching rules. The system demonstrates how Prolog's unification naturally handles the multi-criteria matching required for recommendation engines — the query `recommend_wine(fish, light, Wine)` backtracks through all wines that satisfy both the meal-color and preference-body constraints.
