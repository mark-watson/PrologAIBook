%% categorizer.pl - Bag-of-words text categorization with expanded
%% vocabulary
:- module(categorizer, [
    categorize/2
]).

%% Category keyword weights — 8 categories, ~40 words each (~320 total)
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
    batting, pitching, goaltender, referee, scrimmage, relegation,
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
    box_office_hit, genre, screenplay, red_carpet, nominee, biopic,
    soundtrack
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
%% Returns list of category-score pairs, sorted by score descending
categorize(Words, Categories) :-
    findall(
        Score-Category,
        (   category_words(Category, Keywords),
            score_category(Words, Keywords, Score),
            Score > 0
        ),
        Pairs
    ),
    sort(1, @>=, Pairs, Categories).

score_category(Words, Keywords, Score) :-
    include(word_in_list(Keywords), Words, Matches),
    length(Matches, Score).

word_in_list(Keywords, Word) :-
    downcase_atom(Word, Lower),
    member(Lower, Keywords).
