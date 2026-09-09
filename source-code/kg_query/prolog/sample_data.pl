%% sample_data.pl - Example knowledge graph: 374 static facts
%% (132 typed entities, 242 binary relations).
%% All facts are plain static facts (no runtime asserts); loading
%% this module multiple times never duplicates data.
:- module(sample_data, [
    entity/2,
    relation/3,
    load_sample_data/0
]).

%% Facts: entity(ID, Type)
  entity(mark, person).
  entity(sarah, person).
  entity(chen, person).
  entity(alice, person).
  entity(bob, person).
  entity(diana, person).
  entity(erik, person).
  entity(fatima, person).
  entity(george, person).
  entity(hannah, person).
  entity(ivan, person).
  entity(julia, person).
  entity(karl, person).
  entity(lisa, person).
  entity(marco, person).
  entity(nora, person).
  entity(oscar, person).
  entity(priya, person).
  entity(quentin, person).
  entity(rachel, person).
  entity(stefan, person).
  entity(tanya, person).
  entity(ulrich, person).
  entity(vera, person).
  entity(werner, person).
  entity(xena, person).
  entity(yuki, person).
  entity(zara, person).
  entity(prolog, language).
  entity(lisp, language).
  entity(python, language).
  entity(rust, language).
  entity(haskell, language).
  entity(clojure, language).
  entity(scala, language).
  entity(julia_lang, language).
  entity(racket, language).
  entity(gerbil, language).
  entity(hy, language).
  entity(swift, language).
  entity(kotlin, language).
  entity(go, language).
  entity(erlang, language).
  entity(elm, language).
  entity(ocaml, language).
  entity(fsharp, language).
  entity(ai, field).
  entity(nlp, field).
  entity(knowledge_rep, field).
  entity(robotics, field).
  entity(cv, field).
  entity(ml, field).
  entity(dl, field).
  entity(rl, field).
  entity(logic, field).
  entity(type_theory, field).
  entity(formal_methods, field).
  entity(optimization, field).
  entity(graph_theory, field).
  entity(crypto, field).
  entity(distributed_sys, field).
  entity(concurrent_prog, field).
  entity(swi, implementation).
  entity(scheme, implementation).
  entity(cpython, implementation).
  entity(jvm, implementation).
  entity(beam, implementation).
  entity(llvm, implementation).
  entity(graal, implementation).
  entity(dotnet, implementation).
  entity(chez, implementation).
  entity(gambit, implementation).
  entity(erlang_otp, implementation).
  entity(clang, implementation).
  entity(rustc, implementation).
  entity(ghc, implementation).
  entity(scala_native, implementation).
  entity(clojure_clr, implementation).
  entity(swiftc, implementation).
  entity(goruntime, implementation).
  entity(google, organization).
  entity(meta, organization).
  entity(apple, organization).
  entity(microsoft, organization).
  entity(openai, organization).
  entity(deepmind, organization).
  entity(huggingface, organization).
  entity(anthropic, organization).
  entity(cern, organization).
  entity(nasa, organization).
  entity(darpa, organization).
  entity(ecrf, organization).
  entity(samsung, organization).
  entity(intel, organization).
  entity(neural_net, concept).
  entity(transformer, concept).
  entity(attention, concept).
  entity(backprop, concept).
  entity(gradient_desc, concept).
  entity(softmax, concept).
  entity(fold, concept).
  entity(monad, concept).
  entity(curry_howard, concept).
  entity(pid, concept).
  entity(actor_model, concept).
  entity(csp, concept).
  entity(homoiconicity, concept).
  entity(tail_call, concept).
  entity(pattern_match, concept).
  entity(unification, concept).
  entity(gpt4, project).
  entity(llama, project).
  entity(gemma, project).
  entity(bert, project).
  entity(roberta, project).
  entity(t5, project).
  entity(dalle, project).
  entity(whisper, project).
  entity(alpha_go, project).
  entity(watson, project).
  entity(rosette, project).
  entity(coq, project).
  entity(isabelle, project).
  entity(lean, project).
  entity(attention_paper, publication).
  entity(gpt_paper, publication).
  entity(bert_paper, publication).
  entity(resnet_paper, publication).
  entity(batchnorm_paper, publication).
  entity(dropout_paper, publication).
  entity(word2vec_paper, publication).
  entity(alpha_go_paper, publication).

%% Facts: relation(From, Predicate, To)
  relation(mark, writes_about, ai).
  relation(mark, writes_about, nlp).
  relation(mark, writes_about, knowledge_rep).
  relation(sarah, researches, ml).
  relation(sarah, researches, dl).
  relation(chen, researches, nlp).
  relation(chen, researches, knowledge_rep).
  relation(alice, researches, cv).
  relation(alice, researches, dl).
  relation(bob, researches, robotics).
  relation(bob, researches, rl).
  relation(diana, researches, logic).
  relation(diana, researches, type_theory).
  relation(erik, researches, formal_methods).
  relation(fatima, researches, distributed_sys).
  relation(fatima, researches, concurrent_prog).
  relation(george, researches, optimization).
  relation(george, researches, graph_theory).
  relation(hannah, researches, crypto).
  relation(ivan, researches, ml).
  relation(ivan, researches, optimization).
  relation(julia, researches, nlp).
  relation(julia, researches, logic).
  relation(karl, researches, type_theory).
  relation(lisa, researches, ai).
  relation(lisa, researches, robotics).
  relation(marco, researches, concurrent_prog).
  relation(marco, researches, distributed_sys).
  relation(mark, uses, prolog).
  relation(mark, uses, python).
  relation(mark, uses, clojure).
  relation(sarah, uses, python).
  relation(sarah, uses, julia_lang).
  relation(chen, uses, python).
  relation(chen, uses, prolog).
  relation(chen, uses, racket).
  relation(alice, uses, python).
  relation(alice, uses, swift).
  relation(bob, uses, rust).
  relation(bob, uses, python).
  relation(diana, uses, haskell).
  relation(diana, uses, ocaml).
  relation(erik, uses, ocaml).
  relation(erik, uses, haskell).
  relation(fatima, uses, erlang).
  relation(fatima, uses, go).
  relation(george, uses, python).
  relation(george, uses, julia_lang).
  relation(hannah, uses, rust).
  relation(hannah, uses, go).
  relation(ivan, uses, python).
  relation(ivan, uses, clojure).
  relation(julia, uses, lisp).
  relation(julia, uses, prolog).
  relation(karl, uses, haskell).
  relation(karl, uses, ocaml).
  relation(lisa, uses, clojure).
  relation(lisa, uses, python).
  relation(marco, uses, erlang).
  relation(marco, uses, scala).
  relation(prolog, implemented_by, swi).
  relation(lisp, implemented_by, scheme).
  relation(lisp, implemented_by, chez).
  relation(python, implemented_by, cpython).
  relation(rust, implemented_by, rustc).
  relation(haskell, implemented_by, ghc).
  relation(clojure, implemented_by, jvm).
  relation(clojure, implemented_by, graal).
  relation(scala, implemented_by, jvm).
  relation(scala, implemented_by, scala_native).
  relation(clojure, implemented_by, clojure_clr).
  relation(erlang, implemented_by, beam).
  relation(erlang, implemented_by, erlang_otp).
  relation(swift, implemented_by, swiftc).
  relation(go, implemented_by, goruntime).
  relation(racket, implemented_by, chez).
  relation(gerbil, implemented_by, gambit).
  relation(kotlin, implemented_by, jvm).
  relation(fsharp, implemented_by, dotnet).
  relation(ocaml, implemented_by, llvm).
  relation(scheme, implemented_by, chez).
  relation(scheme, implemented_by, gambit).
  relation(ai, uses, neural_net).
  relation(ai, uses, gradient_desc).
  relation(ai, uses, backprop).
  relation(nlp, uses, transformer).
  relation(nlp, uses, attention).
  relation(ml, uses, neural_net).
  relation(ml, uses, gradient_desc).
  relation(ml, uses, softmax).
  relation(dl, uses, neural_net).
  relation(dl, uses, backprop).
  relation(dl, uses, attention).
  relation(logic, uses, unification).
  relation(logic, uses, pattern_match).
  relation(type_theory, uses, curry_howard).
  relation(concurrent_prog, uses, actor_model).
  relation(concurrent_prog, uses, csp).
  relation(distributed_sys, uses, actor_model).
  relation(optimization, uses, gradient_desc).
  relation(optimization, uses, softmax).
  relation(robotics, uses, pid).
  relation(ai, uses, python).
  relation(ai, uses, prolog).
  relation(nlp, uses, python).
  relation(ml, uses, python).
  relation(ml, uses, julia_lang).
  relation(dl, uses, python).
  relation(logic, uses, prolog).
  relation(logic, uses, haskell).
  relation(type_theory, uses, haskell).
  relation(type_theory, uses, ocaml).
  relation(concurrent_prog, uses, erlang).
  relation(concurrent_prog, uses, go).
  relation(distributed_sys, uses, erlang).
  relation(distributed_sys, uses, scala).
  relation(formal_methods, uses, ocaml).
  relation(formal_methods, uses, haskell).
  relation(robotics, uses, rust).
  relation(robotics, uses, python).
  relation(sarah, works_at, google).
  relation(chen, works_at, meta).
  relation(alice, works_at, deepmind).
  relation(bob, works_at, openai).
  relation(diana, works_at, ecrf).
  relation(erik, works_at, cern).
  relation(fatima, works_at, intel).
  relation(george, works_at, nasa).
  relation(hannah, works_at, intel).
  relation(ivan, works_at, anthropic).
  relation(julia, works_at, ecrf).
  relation(karl, works_at, ecrf).
  relation(lisa, works_at, deepmind).
  relation(marco, works_at, samsung).
  relation(nora, works_at, huggingface).
  relation(priya, works_at, google).
  relation(quentin, works_at, apple).
  relation(rachel, works_at, microsoft).
  relation(stefan, works_at, samsung).
  relation(tanya, works_at, darpa).
  relation(ulrich, works_at, cern).
  relation(werner, works_at, nasa).
  relation(google, develops, gemma).
  relation(google, develops, bert).
  relation(google, develops, t5).
  relation(meta, develops, llama).
  relation(openai, develops, gpt4).
  relation(openai, develops, dalle).
  relation(openai, develops, whisper).
  relation(deepmind, develops, alpha_go).
  relation(microsoft, develops, watson).
  relation(anthropic, develops, claude).
  relation(huggingface, develops, transformers_lib).
  relation(apple, develops, mlx_framework).
  relation(nasa, develops, curiosity).
  relation(cern, develops, root_framework).
  relation(samsung, develops, knox).
  relation(intel, develops, openvino).
  relation(darpa, develops, darpa_xai).
  relation(ecrf, develops, rosette).
  relation(gpt4, based_on, transformer).
  relation(gpt4, based_on, attention).
  relation(llama, based_on, transformer).
  relation(bert, based_on, transformer).
  relation(bert, based_on, attention).
  relation(roberta, based_on, transformer).
  relation(t5, based_on, transformer).
  relation(dalle, based_on, transformer).
  relation(whisper, based_on, transformer).
  relation(alpha_go, based_on, rl).
  relation(alpha_go, based_on, neural_net).
  relation(coq, based_on, curry_howard).
  relation(isabelle, based_on, logic).
  relation(lean, based_on, type_theory).
  relation(attention_paper, introduces, attention).
  relation(gpt_paper, introduces, transformer).
  relation(bert_paper, introduces, transformer).
  relation(resnet_paper, introduces, neural_net).
  relation(batchnorm_paper, introduces, neural_net).
  relation(dropout_paper, introduces, neural_net).
  relation(word2vec_paper, introduces, nlp).
  relation(attention_paper, published_at, nips).
  relation(gpt_paper, published_at, nips).
  relation(bert_paper, published_at, naacl).
  relation(resnet_paper, published_at, cvpr).
  relation(word2vec_paper, published_at, nips).
  relation(mark, collaborates_with, chen).
  relation(mark, collaborates_with, julia).
  relation(sarah, collaborates_with, ivan).
  relation(alice, collaborates_with, lisa).
  relation(bob, collaborates_with, nora).
  relation(diana, collaborates_with, karl).
  relation(diana, collaborates_with, julia).
  relation(erik, collaborates_with, ulrich).
  relation(fatima, collaborates_with, marco).
  relation(george, collaborates_with, werner).
  relation(hannah, collaborates_with, quentin).
  relation(ivan, collaborates_with, priya).
  relation(karl, collaborates_with, erik).
  relation(lisa, collaborates_with, sarah).
  relation(marco, collaborates_with, stefan).
  relation(nora, collaborates_with, rachel).
  relation(sarah, author_of, attention_paper).
  relation(sarah, author_of, gpt_paper).
  relation(chen, author_of, bert_paper).
  relation(alice, author_of, resnet_paper).
  relation(bob, author_of, dropout_paper).
  relation(ivan, author_of, bert_paper).
  relation(lisa, author_of, alpha_go_paper).
  relation(nora, author_of, word2vec_paper).
  relation(rachel, author_of, batchnorm_paper).
  relation(priya, author_of, attention_paper).
  relation(clojure, dialect_of, lisp).
  relation(scheme, dialect_of, lisp).
  relation(racket, dialect_of, scheme).
  relation(gerbil, dialect_of, scheme).
  relation(hy, dialect_of, python).
  relation(scala, runs_on, jvm).
  relation(kotlin, runs_on, jvm).
  relation(clojure, runs_on, jvm).
  relation(elm, compiles_to, javascript).
  relation(ocaml, compiles_to, native).
  relation(attention, builds_on, neural_net).
  relation(transformer, builds_on, attention).
  relation(backprop, enables, gradient_desc).
  relation(curry_howard, relates, logic).
  relation(curry_howard, relates, type_theory).
  relation(actor_model, alternative_to, csp).
  relation(monad, used_in, haskell).
  relation(fold, used_in, haskell).
  relation(fold, used_in, clojure).
  relation(unification, used_in, prolog).
  relation(tail_call, used_in, scheme).
  relation(homoiconicity, property_of, lisp).
  relation(robotics, overlaps_with, ai).
  relation(cv, overlaps_with, dl).
  relation(nlp, overlaps_with, ai).
  relation(ml, subfield_of, ai).
  relation(dl, subfield_of, ml).
  relation(rl, subfield_of, ml).
  relation(nlp, subfield_of, ai).
  relation(knowledge_rep, subfield_of, ai).

%% load_sample_data/0 - retained for backward compatibility;
%% data is already present as static facts, so this is a no-op.
load_sample_data.
