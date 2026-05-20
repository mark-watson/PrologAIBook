%% exs.pl - Positive and Negative Examples for Popper
pos(grandparent(pam, ann)).
pos(grandparent(pam, pat)).
pos(grandparent(tom, ann)).
pos(grandparent(tom, pat)).
pos(grandparent(bob, jim)).

neg(grandparent(pam, bob)).
neg(grandparent(tom, liz)).
neg(grandparent(bob, pat)).
neg(grandparent(ann, jim)).
neg(grandparent(jim, pam)).
