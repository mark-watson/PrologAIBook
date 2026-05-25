# Client-Side Prolog with WebAssembly

Traditionally, incorporating a Prolog-based reasoning engine into a web application required a backend server running SWI-Prolog or another dialect. The web front-end would communicate with this server via HTTP REST APIs, WebSockets, or a language-specific bridge like Janus in Python. While this is a standard design, it introduces server overhead, hosting costs, network latency, and requires an internet connection to function.

**WebAssembly (WASM)** changes this paradigm. By compiling the entire SWI-Prolog engine (written in C) into a highly optimized WASM binary, we can download and run Prolog directly in the user's web browser. 

This architecture offers several key advantages:
1. **Zero Server Cost**: The logic engine runs entirely on client CPU cycles. The server only needs to host static files (HTML, CSS, JS, WASM).
2. **Sub-millisecond Latency**: Queries execute locally in microsecond loops, allowing interface elements to update instantly as users toggle options.
3. **Offline Resilience**: Once the static files are loaded, the expert system works without any network connection, making it suitable for progressive web applications (PWAs).

In this chapter, we explore **SipLogic**, a Wine Advisor expert system dashboard. It loads SWI-Prolog WASM, reads a local Prolog rule-base, and runs recommendations interactively on the client side.


{width: "80%"}
![Architecture diagram for the WebAssembly Prolog example](FIG_prolog_wasm_web.jpg)


## Architecture of a WASM Prolog Application

The execution model inside the browser is simple. The browser downloads the SWI-Prolog WASM runtime and our expert system rule file. It then uses the Emscripten virtual file system to load the rules inside the compiled runtime, after which JavaScript communicates with the engine via queries:

1. **WASM Initialization**: The browser loads `swipl-web.js` (from a CDN or local assets), which instantiates the SWI-Prolog engine.
2. **Virtual FS Write**: The application fetches the text of `rules.pl` and writes it to Emscripten's virtual memory filesystem (e.g., at `/rules.pl`).
3. **Engine Consultation**: JavaScript queries the engine to run `consult('/rules.pl')`.
4. **Interactive Query Loop**: Whenever the user updates UI filters (food, body preference, sweetness), a JavaScript event listener triggers, constructing and executing a Prolog query. The engine returns bindings as native JavaScript objects.

---

## Recommender System Logic

Our advisor is defined by a Prolog database containing wine facts, food pairing rules, and a recommendation predicate.

Here is the code in **source-code/prolog_wasm_web/rules.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
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
    % Match preferences if specified (or allow any if 'any' is selected)
    (PreferredBody == any ; Body == PreferredBody),
    (PreferredSweetness == any ; Sweetness == PreferredSweetness),
    % Generate a human-readable explanation
    generate_explanation(Wine, Color, Body, Sweetness, Food,
        Explanation).

% Generate a beautiful explanation sentence
generate_explanation(Wine, Color, Body, Sweetness, Food, Explanation) :-
    format(string(Explanation), 





                               "Because you are eating ~w, a ~w wine is a classic pairing. ~w is a ~w, ~w ~w wine that perfectly matches your taste preferences.",
           [Food, Color, Wine, Body, Sweetness, Color]).
~~~~~~~~

The recommendation logic matches the user's food selection with compatible wine colors, verifies matching body and sweetness preferences (using the fallback term `any`), and calls `format/3` to return a customized justification sentence.

---

## JavaScript Integration

The JavaScript layer manages the lifecycle of the WASM engine: downloading the loader, fetching the rules, initializing the query handler, and responding to DOM input events.

Here is the implementation in **source-code/prolog_wasm_web/app.js**:

{lang="javascript",linenos=off}
~~~~~~~~
let prologEngine = null;

// DOM Elements
const statusBadge = document.getElementById('statusBadge');
const statusText = document.getElementById('statusText');
const resultsContainer = document.getElementById('resultsContainer');
const foodSelect = document.getElementById('foodSelect');
const bodySelect = document.getElementById('bodySelect');
const sweetnessSelect = document.getElementById('sweetnessSelect');

// Initialize the SWI-Prolog WASM engine
async function initProlog() {
    try {
        console.log("Initializing SWI-Prolog WASM...");
        
        // 1. Initialize SWIPL loader
        const swipl = await SWIPL({
            arguments: ["-q"],
            locateFile: (path) => `https://unpkg.com/swipl-wasm@0.1.0/dist/${path}`
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

        // 4. Consult the rules inside Prolog
        prologEngine.query("consult('/rules.pl').").once();
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
        resultsContainer.innerHTML = `
            <div class="empty-state">
                <span class="empty-icon">⚠️</span>
                <p>Failed to initialize the SWI-Prolog engine.</p>
                <p style="font-size: 0.85rem; color: var(--text-secondary);">${error.message}</p>
            </div>
        `;
    }
}

// Run query and display results
function runRecommendation() {
    if (!prologEngine) return;

    const food = foodSelect.value;
    const body = bodySelect.value;
    const sweetness = sweetnessSelect.value;

    resultsContainer.innerHTML = '';

    // Construct Prolog query
    // Example: recommend('meat', 'full_body', 'dry', Wine, Color, Explanation).
    const queryStr = `recommend('${food}', '${body}', '${sweetness}', Wine, Color, Explanation).`;
    console.log("Executing Query:", queryStr);

    try {
        const query = prologEngine.query(queryStr);
        const recommendations = [];

        // Fetch all matching solutions
        let result = query.next();
        while (result && !result.done) {
            // Unpack variables (Prolog bindings are returned as JS values)
            // String values are decoded/retrieved
            const wine = formatPrologValue(result.value.Wine);
            const color = formatPrologValue(result.value.Color);
            const explanation = formatPrologValue(result.value.Explanation);

            recommendations.push({ wine, color, explanation });
            result = query.next();
        }
        query.close();

        // Display results
        if (recommendations.length === 0) {
            resultsContainer.innerHTML = `
                <div class="empty-state">
                    <span class="empty-icon">🍷</span>
                    <p>No perfect pairings found matching your specific preferences.</p>
                    <p style="font-size: 0.85rem; color: var(--text-secondary);">Try selecting 'Any Body' or 'Any Sweetness' to expand choices.</p>
                </div>
            `;
        } else {
            recommendations.forEach(rec => {
                const card = document.createElement('div');
                card.className = `wine-card ${rec.color}`;
                
                // Format wine name for presentation (replace underscores with spaces)
                const formattedName = rec.wine.replace(/_/g, ' ');

                card.innerHTML = `
                    <div class="wine-header">
                        <h3 class="wine-name">${formattedName}</h3>
                        <span class="wine-type-badge">${rec.color}</span>
                    </div>
                    <p class="wine-justification">${rec.explanation}</p>
                `;
                resultsContainer.appendChild(card);
            });
        }

    } catch (err) {
        console.error("Query execution error:", err);
        resultsContainer.innerHTML = `
            <div class="empty-state">
                <span class="empty-icon">⚠️</span>
                <p>Query execution failed.</p>
                <p style="font-size: 0.85rem; color: var(--text-secondary);">${err.message}</p>
            </div>
        `;
    }
}

// Convert Prolog terms to clean JS strings
function formatPrologValue(val) {
    if (typeof val === 'string') return val;
    // Handle atoms represented as objects or arrays of codes
    if (val && typeof val === 'object' && val.toString) {
        return val.toString();
    }
    return String(val);
}

// Start on page load
window.addEventListener('DOMContentLoaded', initProlog);
~~~~~~~~

---

## Running the Application Locally

Because modern web browsers block asynchronous network requests (such as `fetch`) when pages are loaded from local file paths (`file://`), you cannot test the project by double-clicking the `index.html` file. Instead, you must run a simple local HTTP server from the project directory.

Open a terminal, navigate to the `source-code/prolog_wasm_web` directory, and run the built-in Python HTTP server module:

{linenos=off}
~~~~~~~~
$ python -m http.server 8000 --directory .
~~~~~~~~

Then, open [http://localhost:8000](http://localhost:8000) in your web browser. You will see the status badge transition from red (**Prolog Loading...**) to a glowing emerald green (**Prolog WASM Online**). Changing any of the pairing selectors dynamically triggers queries that instantaneously update the recommended list.

---

## Key Design Decisions

**Loading from CDN vs. Self-Hosting WASM.** In this example, the Emscripten JS and WASM assets are loaded via the UNPKG CDN (`https://unpkg.com/swipl-wasm@0.1.0/dist/`). For production applications, it is usually better to self-host these assets on your own web server or Content Delivery Network to avoid dependencies on external CDN infrastructure and to enforce Strict Content Security Policies (CSP).

**File System Emulation.** Emscripten maps virtual memory structures to regular file system logic. The call `swipl.FS.writeFile('/rules.pl', rulesText)` creates a virtual file that SWI-Prolog's core `consult` predicate reads as if it were a physical file on disk. This is a powerful feature: it means you can reuse existing complex Prolog databases without modifying the Prolog codebase to load from strings.

**The Query Lifecycle.** Unlike a traditional long-running command-line loop, querying WASM Prolog in JavaScript uses an iterator pattern:
- `prologEngine.query(queryStr)` returns an active query handle.
- Calling `.next()` returns a dictionary of the variable bindings (e.g., `{ Wine: "merlot", Color: "red" }`) or a state object indicating the query is complete.
- **Always** call `query.close()` once you are done fetching results to free the internal memory structures allocated in the WASM heap.
