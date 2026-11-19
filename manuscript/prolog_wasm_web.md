# Client-Side Prolog with WebAssembly


A web application with a Prolog reasoning engine usually needs a server running Prolog. The browser talks to it over HTTP, WebSockets, or a bridge such as Janus in Python. That design costs server time and hosting fees, adds network delay, and needs a connection.

**WebAssembly (WASM)** offers another way. SWI-Prolog, which is written in C, can be compiled to WASM, so the browser downloads the whole engine and runs Prolog itself.

This has three advantages:
1. **No server cost**: Prolog runs on the user's machine. The server only hosts static files (HTML, CSS, JavaScript, WASM).
2. **Low latency**: Queries run locally in well under a millisecond, so the page can update as the user changes options.
3. **Offline use**: Once the files are loaded, the expert system works without a network connection, which suits progressive web applications (PWAs).

The cost is the download: the WASM engine and its data file total several megabytes, which the browser fetches before the first query.

In this chapter we look at **SipLogic**, a wine advisor page. It loads SWI-Prolog WASM, reads a Prolog rule file, and runs recommendations in the browser.

{width: "80%"}
![Prolog WASM Web App Demo](prolog-wasm.jpg)

## Architecture of a WASM Prolog Application

The browser downloads the SWI-Prolog WASM runtime and our rule file, puts the rules in Emscripten's virtual file system, and then JavaScript sends queries to the engine:

1. **WASM Initialization**: The browser loads `swipl-web.js` (from a CDN or local assets), which instantiates the SWI-Prolog engine.
2. **Virtual FS Write**: The application fetches the text of `rules.pl` and writes it to Emscripten's virtual memory filesystem (e.g., at `/rules.pl`).
3. **Engine Consultation**: JavaScript queries the engine to run `consult('/rules.pl')`.
4. **Query loop**: When the user changes a selector (food, body, sweetness), an event listener builds and runs a Prolog query. The engine returns the variable bindings as JavaScript values.

{width: "80%"}
![Architecture diagram for the WebAssembly Prolog example](FIG_prolog_wasm_web.jpg)


## Recommender System Logic

The advisor is a set of wine facts, food pairing rules, and a recommendation predicate. Here is the file **prolog_wasm_web/rules.pl**:

```prolog
% rules.pl - Wine Recommendation Expert System for WASM

% Database of Wines: wine(Name, Color, Body, Sweetness)
wine(cabernet_sauvignon, red, full_body, dry).
wine(merlot, red, medium_body, dry).
wine(pinot_noir, red, light_body, dry).
wine(chardonnay, white, full_body, dry).
wine(sauvignon_blanc, white, medium_body, dry).
wine(riesling, white, light_body, sweet).
wine(moscato, white, light_body, sweet).
wine(port, red, full_body, sweet).
wine(sauternes, white, full_body, sweet).

% Pairing rules: pair(WineColor, FoodType)
pair(red, meat).
pair(red, cheese).
pair(white, fish).
pair(white, poultry).
pair(white, spicy_food).
pair(white, dessert).
pair(red, dessert).

% Recommend a wine based on food, body preference, and sweetness
% preference.
% Returns Wine name, its Color, and a justification string.
recommend(Food, PreferredBody, PreferredSweetness, Wine, Color,
    Explanation) :-
    wine(Wine, Color, Body, Sweetness),
    % Check food pairing compatibility
    pair(Color, Food),
    % Match preferences ('any' matches every value)
    matches(PreferredBody, Body),
    matches(PreferredSweetness, Sweetness),
    % Generate a human-readable explanation
    generate_explanation(Wine, Color, Body, Sweetness, Food,
        Explanation).

% matches(+Preference, +Value)
matches(any, _) :- !.
matches(Value, Value).

% Build an explanation sentence. Atoms such as full_body become
% words such as full-bodied.
generate_explanation(Wine, Color, Body, Sweetness, Food, Explanation) :-
    words(Wine, WineWords),
    words(Food, FoodWords),
    body_words(Body, BodyWords),
    format(string(Explanation),
           "A ~w wine is a classic pairing for ~w. ~w is a ~w, ~w ~w wine.",
           [Color, FoodWords, WineWords, BodyWords, Sweetness, Color]).

body_words(full_body, 'full-bodied').
body_words(medium_body, 'medium-bodied').
body_words(light_body, 'light-bodied').

% words(+Atom, -Text): replace underscores with spaces.
words(Atom, Text) :-
    atomic_list_concat(Parts, '_', Atom),
    atomic_list_concat(Parts, ' ', Text).
```

`recommend/6` pairs the food with wine colors, checks the body and sweetness preferences (`any` matches every value), and builds an explanation with `format/3`. `words/2` turns an atom such as `sauvignon_blanc` into the text `sauvignon blanc` by splitting on underscores and joining with spaces.

The rules are plain Prolog, so we can test them with native SWI-Prolog before they reach the browser: `make test` runs **tests/test_rules.pl**.

---

## JavaScript Integration

The JavaScript code loads the WASM engine, fetches and consults the rules, and answers changes to the selectors. Here is most of **prolog_wasm_web/app.js**:

```javascript
// app.js - SipLogic application to load SWI-Prolog WASM and query recommendations

const SWIPL_WASM_VERSION = '8.1.2';

let prologEngine = null;

// Whitelisted values for each user-facing selector.  Anything else
// is rejected before it can reach a Prolog query string.
const ALLOWED = {
    food: ['meat', 'cheese', 'poultry', 'fish', 'spicy_food', 'dessert'],
    body: ['any', 'full_body', 'medium_body', 'light_body'],
    sweetness: ['any', 'dry', 'sweet']
};

// pq(atom): single-quote-escape a value as a Prolog atom, defensively.
// Whitelisted values are already safe; this guards any other code path
// that builds query strings.
function pq(atom) {
    return "'" + String(atom).replace(/\\/g, '\\\\').replace(/'/g, "\\'") + "'";
}

function checkedValue(name, raw) {
    if (ALLOWED[name].indexOf(raw) === -1) {
        throw new Error(`Invalid ${name} selection: ${raw}`);
    }
    return raw;
}

// DOM Elements
const statusBadge = document.getElementById('statusBadge');
const statusText = document.getElementById('statusText');
const resultsContainer = document.getElementById('resultsContainer');
const foodSelect = document.getElementById('foodSelect');
const bodySelect = document.getElementById('bodySelect');
const sweetnessSelect = document.getElementById('sweetnessSelect');

// Replace the results area with a small (icon, message, detail) state,
// e.g. an empty state, an error banner, or a "still loading" notice.
// icon is one of the short label tokens used by the CSS (⚠️, 🍷, ...).
function showState(icon, message, detail) {
    resultsContainer.textContent = '';

    const state = document.createElement('div');
    state.className = 'empty-state';

    const iconEl = document.createElement('span');
    iconEl.className = 'empty-icon';
    iconEl.textContent = icon;
    state.appendChild(iconEl);

    const messageEl = document.createElement('p');
    messageEl.textContent = message;
    state.appendChild(messageEl);

    if (detail) {
        const detailEl = document.createElement('p');
        detailEl.style.fontSize = '0.85rem';
        detailEl.style.color = 'var(--text-secondary)';
        detailEl.textContent = detail;
        state.appendChild(detailEl);
    }

    resultsContainer.appendChild(state);
}

function showError(message, detail) {
    showState('⚠️', message, detail);
}

// Initialize the SWI-Prolog WASM engine
async function initProlog() {
    try {
        console.log("Initializing SWI-Prolog WASM...");

        // 1. Initialize SWIPL loader
        const swipl = await SWIPL({
            arguments: ["-q"],
            locateFile: (path) =>
                `https://unpkg.com/swipl-wasm@${SWIPL_WASM_VERSION}/dist/swipl/${path}`
        });

        prologEngine = swipl.prolog;
        console.log("SWI-Prolog engine loaded. Fetching rules.pl...");

        // 2. Fetch local rules.pl content
        const response = await fetch('rules.pl');
        if (!response.ok) {
            throw new Error(`Failed to fetch rules.pl: ${response.statusText}`);
        }
        const rulesText = await response.text();

        // 3. Write rules.pl to Emscripten virtual filesystem
        swipl.FS.writeFile('/rules.pl', rulesText);
        console.log("rules.pl written to virtual FS. Consulting...");

        // 4. Consult the rules inside Prolog; surface consult errors in the UI
        const consultResult = prologEngine.query("consult('/rules.pl').").once();
        if (consultResult && consultResult.error) {
            prologEngine = null;
            showError("Failed to consult Prolog rules.", consultResult.message);
            return;
        }
        console.log("Consult complete. Engine is online!");

        // 5. Update UI status
        statusBadge.classList.add('online');
        statusText.textContent = "Prolog WASM Online";

        // Enable inputs
        [foodSelect, bodySelect, sweetnessSelect].forEach(select => {
            select.disabled = false;
        });

        // Run initial recommendation
        runRecommendation();

        // Add event listeners
        [foodSelect, bodySelect, sweetnessSelect].forEach(select => {
            select.addEventListener('change', runRecommendation);
        });

    } catch (error) {
        console.error("Failed to initialize Prolog WASM:", error);
        statusText.textContent = "Error Loading Prolog";
        showError("Failed to initialize the SWI-Prolog engine.", error.message);
    }
}

// Run query and display results
function runRecommendation() {
    if (!prologEngine) {
        showState('🍷', "The Prolog engine is still loading...",
                  "Recommendations will appear here once it is ready.");
        return;
    }

    let food, body, sweetness;
    try {
        food = checkedValue('food', foodSelect.value);
        body = checkedValue('body', bodySelect.value);
        sweetness = checkedValue('sweetness', sweetnessSelect.value);
    } catch (error) {
        showError("Invalid selection.", error.message);
        return;
    }

    resultsContainer.textContent = '';

    // Construct Prolog query
    // Example: recommend('meat', 'full_body', 'dry', Wine, Color, Explanation).
    const queryStr = `recommend(${pq(food)}, ${pq(body)}, ${pq(sweetness)}, Wine, Color, Explanation).`;
    console.log("Executing Query:", queryStr);

    try {
        const query = prologEngine.query(queryStr);
        const recommendations = [];

        // ... add the event listeners above, then fetch each solution by
        // ... calling query.next() in a loop, checking result.error inside
        // ... and after the loop and calling query.close() on failure paths,
        // ... then render each recommendation with createElement and
        // ... textContent rather than innerHTML. See the complete listing
        // ... in this book's GitHub repository.
```

The CDN URL names an exact version (`8.1.2`) instead of `@latest`, so a new release cannot change the page without warning. User selections must appear in the `ALLOWED` list, and `pq()` quotes them, before they go into a query string, which prevents query injection. The page builds its output with `createElement` and `textContent`, never `innerHTML`, so text from Prolog cannot inject markup. A failed consult or query returns an object with `error: true` and a `message`, which the code shows in the page.

Bindings come back as JavaScript values: an atom as a string, a number as a number, and a list as an array. A Prolog *string* is different. It arrives as a `PrologString` object, `{$t: "s", v: "..."}`, and `JSON.stringify` would wrap it in quote marks. The explanation is a Prolog string, so `formatPrologValue()` checks for this case:

```javascript
// Convert a Prolog value from swipl-wasm to a display string.
// Atoms arrive as JS strings and numbers as JS numbers. A Prolog
// string arrives as a PrologString object ({$t: 's', v: text}), so
// JSON.stringify would wrap it in quote marks; we take .v instead.
// Anything else (a compound term) is shown as JSON.
function formatPrologValue(val) {
    if (typeof val === 'string') return val;
    if (typeof val === 'number') return String(val);
    if (val && val.$t === 's') return val.v;
    return JSON.stringify(val);
}
```

---

## Running the Application Locally

Because modern web browsers block asynchronous network requests (such as `fetch`) when pages are loaded from local file paths (`file://`), you cannot test the project by double-clicking the `index.html` file. Instead, you must run a simple local HTTP server from the project directory.

From the `source-code/prolog_wasm_web` directory, start Python's built-in web server with `make serve`, which runs:

{linenos=off}
~~~~~~~~
$ python3 -m http.server 8000 --directory .
~~~~~~~~

Then open [http://localhost:8000](http://localhost:8000). The status badge changes from red (**Prolog Loading...**) to green (**Prolog WASM Online**) once the engine is ready. Each change to a selector runs a new query and updates the list.

---

## Key Design Decisions

**CDN or self-hosting.** This example loads the Emscripten JavaScript and WASM files from the unpkg CDN, pinned to version `8.1.2` (`https://unpkg.com/swipl-wasm@8.1.2/dist/swipl/`). For production, serve these files yourself, so the page does not depend on a third party and can use a strict Content Security Policy (CSP).

**Virtual file system.** Emscripten gives the WASM program an in-memory file system. `swipl.FS.writeFile('/rules.pl', rulesText)` creates a file there, and `consult/1` reads it like a file on disk. So existing Prolog files work unchanged.

**The query life cycle.** A query in JavaScript works like an iterator:
- `prologEngine.query(queryStr)` returns a query handle.
- Each `.next()` returns `{value: Bindings, done: false}`, where `Bindings` maps variable names to values (e.g., `{Wine: "merlot", Color: "red", ...}`), and finally `{done: true}`.
- `.once()` returns the first solution's bindings directly.
- **Always** call `query.close()` when you stop early, to free the query's memory in the WASM heap.

I checked these details by running `swipl-wasm@8.1.2` under Node.js, which loads the same engine as the browser.

## Optional Practice Problems

1. **Family Queries**: Copy `family.pl` from the Tutorial chapter's `tutorial_basics` project into this directory. Add a text field to `index.html` where the user enters a name, and list that person's siblings and grandparents. Validate the name before it goes into a query.
2. **Timing**: Use `performance.now()` in `app.js` to time each query and show the time in the page.
3. **Self-Hosting**: Copy `swipl-web.js`, `swipl-web.wasm`, and `swipl-web.data` into this directory and change `index.html` and `locateFile` to load them locally. Check in the browser's network panel that nothing comes from unpkg.
