%% exs.pl - Examples for ancestor/2 over the family in bk.pl
pos(ancestor(tom, bob)).
pos(ancestor(tom, ann)).
pos(ancestor(tom, jim)).
pos(ancestor(pam, jim)).
pos(ancestor(bob, jim)).
pos(ancestor(pat, jim)).

neg(ancestor(bob, tom)).
neg(ancestor(jim, tom)).
neg(ancestor(ann, pat)).
neg(ancestor(liz, ann)).
neg(ancestor(pat, bob)).
