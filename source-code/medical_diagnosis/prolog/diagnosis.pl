%% diagnosis.pl - Simple medical diagnosis reasoner
%% Demonstrates reasoning with multiple rules and explanation
:- module(diagnosis, [
    diagnose/2,
    symptom/1
]).

:- dynamic symptom/1.

%% diagnose(+PatientSymptoms, -DiagnosisWithExplanation)
diagnose(Symptoms, diagnosis(Disease, Explanation)) :-
    maplist(assert_symptom, Symptoms),
    disease(Disease, RequiredSymptoms),
    subset(RequiredSymptoms, Symptoms),
    format(atom(Explanation),
           'Diagnosis: ~w based on symptoms: ~w',
           [Disease, RequiredSymptoms]),
    retract_symptoms(Symptoms).

assert_symptom(S) :- assert(symptom(S)).
retract_symptoms([]).
retract_symptoms([S|Rest]) :- retract(symptom(S)), retract_symptoms(Rest).

%% Disease knowledge base
disease(flu, [fever, cough, fatigue, body_aches]).
disease(cold, [sneezing, runny_nose, sore_throat]).
disease(allergy, [sneezing, itchy_eyes, runny_nose]).
disease(bronchitis, [cough, chest_pain, fatigue, shortness_of_breath]).
disease(migraine, [headache, nausea, light_sensitivity]).
