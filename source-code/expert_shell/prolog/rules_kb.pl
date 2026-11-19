% rules_kb.pl - Wine-selection knowledge base in readable rule form.
% Load with shell:load_kb/1. Each rule reads:
%   if Attribute is Value and ... then Conclusion.
% The shell asks for any attribute it does not know yet and builds
% the explanation from the conditions of the rule that fired.

if meal is dessert and sweet_preference is yes then serve_port.
if meal is red_meat and bold_preference is yes then serve_cabernet.
if meal is red_meat then serve_merlot.
if meal is fish and light_preference is yes then serve_sauvignon_blanc.
if meal is fish then serve_chardonnay.
if meal is poultry then serve_pinot_noir.
