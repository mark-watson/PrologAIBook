%% diagnosis.pl - Simple medical diagnosis reasoner
%% Demonstrates reasoning with multiple rules and explanation
%%
%% This implementation is a pure function of the input symptom list:
%% it matches the patient's symptoms against the disease knowledge base
%% using subset/2 without asserting or retracting any dynamic state.

:- module(diagnosis, [
    diagnose/2
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

%% Disease knowledge base
disease(flu, [fever, cough, fatigue, body_aches]).
disease(cold, [sneezing, runny_nose, sore_throat]).
disease(allergy, [sneezing, itchy_eyes, runny_nose]).
disease(bronchitis, [cough, chest_pain, fatigue, shortness_of_breath]).
disease(migraine, [headache, nausea, light_sensitivity]).
