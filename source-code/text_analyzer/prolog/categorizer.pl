%% categorizer.pl - Bag-of-words text categorization with expanded
%% vocabulary
:- module(categorizer, [
    categorize/2,
    category_words/2,
    keyword_count/3
]).

%% Category keywords: 8 categories with 40 keywords each. A keyword
%% such as machine_learning matches two adjacent words.
category_words(politics, [
    president, congress, election, vote, senator, law, government,
        political,
    democrat, republican, campaign, ballot, bill, legislation, governor,
    cabinet, diplomacy, policy, reform, amendment, referendum, lobbyist,
    partisan, bipartisan, inauguration, veto, debate, delegate,
        constituent,
    judiciary, mayor, ordinance, filibuster, executive, legislature,
    regulation, sanction, treaty, impeachment, oversight
]).
category_words(sports, [
    game, team, player, score, win, tournament, match, championship,
    league, coach, referee, offense, defense, touchdown, goal, season,
    playoff, athlete, stadium, draft, roster, quarter, overtime,
        penalty,
    medal, rivalry, final, semifinal, sprint, marathon, rookie,
        franchise,
    batting, pitching, goaltender, umpire, scrimmage, relegation,
    tryout, concussion
]).
category_words(technology, [
    computer, software, algorithm, data, programming, internet, digital,
    code, hardware, network, server, database, encryption, startup,
    browser, mobile, cloud, cybersecurity, robotics, interface,
        processor,
    framework, deployment, debug, latency, bandwidth, analytics,
    machine_learning, automation, compiler, kernel, firmware,
        middleware,
    container, blockchain, quantum, virtual_reality, augmented_reality,
    neural_network, cryptography
]).
category_words(economy, [
    market, stock, trade, bank, money, economy, financial, tax, debt,
    inflation, interest_rate, revenue, investment, shareholder, bond,
    deficit, gdp, recession, fiscal, equity, commodity, dividend,
    hedge_fund, payroll, subsidy, austerity, consumer, investor, tariff,
    liquidity, mortgage, bankruptcy, cryptocurrency, exchange, stimulus,
    deregulation, arbitrage, yield, benchmark, capital
]).
category_words(healthcare, [
    doctor, nurse, hospital, patient, medicine, surgery, vaccine,
        clinic,
    disease, diagnosis, therapy, prescription, symptom, specialist,
    emergency, pharmacy, insurance, wellness, epidemic, treatment,
    physician, surgeon, pediatric, oncology, cardiology, radiology,
    anesthesia, antibiotic, chronic, pandemic, immunization, outpatient,
    hospice, paramedic, rehabilitation, screening, genome, prosthetic,
    telehealth, nutrition
]).
category_words(education, [
    school, teacher, student, university, college, curriculum, exam,
    degree, professor, lecture, campus, scholarship, enrollment,
    graduation, textbook, research, assignment, classroom, diploma,
    pedagogy, kindergarten, syllabus, tuition, faculty, dissertation,
    seminar, accreditation, internship, literacy, vocational,
    transcript, principal, counselor, standardized_test, tutor,
    registrar, elective, prerequisite, dean, alumni
]).
category_words(entertainment, [
    movie, film, music, actor, director, concert, album, theater,
    celebrity, streaming, award, festival, screenplay, performance,
    hollywood, series, episode, band, release, box_office, soundtrack,
    choreography, premiere, sequel, reboot, franchise, reality_show,
    documentary, animation, podcast, audition, encore, cameo,
    sitcom, genre, blockbuster, red_carpet, nominee, biopic,
    trailer
]).
category_words(environment, [
    climate, energy, pollution, renewable, carbon, emission, recycling,
    sustainability, conservation, wildlife, ecosystem, deforestation,
    solar, wind_power, biodiversity, greenhouse, habitat, drought,
    fossil_fuel, organic, glacier, wetland, coral, aquifer, pesticide,
    landfill, smog, ozone, composting, extinction, carbon_footprint,
    afforestation, desertification, biofuel, hydropower, geothermal,
    endangered, runoff, toxin, ecotourism
]).

%% categorize(+WordList, -Categories)
%% Returns Score-Category pairs for every category with a score
%% above zero, highest score first.
categorize(Words, Categories) :-
    findall(
        Score-Category,
        (   category_words(Category, Keywords),
            keyword_count(Words, Keywords, Score),
            Score > 0
        ),
        Pairs
    ),
    sort(1, @>=, Pairs, Categories).

%% keyword_count(+Words, +Keywords, -Count)
%% Count the words and adjacent word pairs that match a keyword.
keyword_count(Words, Keywords, Count) :-
    maplist(downcase_atom, Words, Lower),
    bigrams(Lower, Pairs),
    append(Lower, Pairs, Terms),
    include(keyword_match(Keywords), Terms, Matches),
    length(Matches, Count).

%% bigrams(+Words, -Joined): [interest, rate] gives [interest_rate].
bigrams([W1, W2|Ws], [B|Bs]) :-
    !,
    atomic_list_concat([W1, W2], '_', B),
    bigrams([W2|Ws], Bs).
bigrams(_, []).

%% keyword_match(+Keywords, +Term)
%% Term is a keyword, or a plural ending in s whose singular is.
keyword_match(Keywords, Term) :-
    (   memberchk(Term, Keywords)
    ->  true
    ;   atom_concat(Singular, s, Term),
        memberchk(Singular, Keywords)
    ).
