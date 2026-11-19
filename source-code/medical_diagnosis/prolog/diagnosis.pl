%% diagnosis.pl - Simple medical diagnosis reasoner
%% Demonstrates reasoning with multiple rules and explanation
%%
%% This implementation is a pure function of the input symptom list:
%% it matches the patient's symptoms against the disease knowledge base
%% using subset/2 without asserting or retracting any dynamic state.

:- module(diagnosis, [
    diagnose/2,
    rank_diagnoses/2
]).

%% diagnose(+PatientSymptoms, -DiagnosisWithExplanation)
%% Pure list-based matching: succeeds iff some disease's required
%% symptoms are a subset of the patient's symptoms.
diagnose(Symptoms, diagnosis(Disease, Explanation)) :-
    disease(Disease, RequiredSymptoms),
    subset(RequiredSymptoms, Symptoms),
    format(atom(Explanation),
           'Diagnosis: ~w based on symptoms: ~w',
           [Disease, RequiredSymptoms]).

%% rank_diagnoses(+PatientSymptoms, -Ranked)
%% Ranked is a list of match(Score, Disease, Matched, Missing) terms,
%% best first, for every disease that shares at least one symptom
%% with the patient. Score is the fraction of the disease's symptoms
%% that the patient has, rounded to two places.
rank_diagnoses(Symptoms, Ranked) :-
    findall(match(Score, Disease, Matched, Missing),
            (   disease(Disease, Required),
                intersection(Required, Symptoms, Matched),
                Matched \== [],
                subtract(Required, Symptoms, Missing),
                length(Matched, M),
                length(Required, R),
                Score is round(100 * M / R) / 100.0
            ),
            Matches),
    sort(1, @>=, Matches, Ranked).

%% Disease knowledge base
disease(flu, [fever, cough, fatigue, body_aches]).
disease(cold, [sneezing, runny_nose, sore_throat]).
disease(allergy, [sneezing, itchy_eyes, runny_nose]).
disease(bronchitis, [cough, chest_pain, fatigue, shortness_of_breath]).
disease(migraine, [headache, nausea, light_sensitivity]).
