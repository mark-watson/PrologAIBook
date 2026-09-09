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

        // Fetch all matching solutions
        let result = query.next();
        while (result && !result.done) {
            if (result.error) {
                query.close();
                showError("Query failed.", result.message);
                return;
            }
            // Unpack variables (Prolog bindings are returned as JS values)
            const wine = formatPrologValue(result.value.Wine);
            const color = formatPrologValue(result.value.Color);
            const explanation = formatPrologValue(result.value.Explanation);

            recommendations.push({ wine, color, explanation });
            result = query.next();
        }
        if (result && result.error) {
            query.close();
            showError("Query failed.", result.message);
            return;
        }
        query.close();

        // Display results
        if (recommendations.length === 0) {
            showState('🍷',
                      "No perfect pairings found matching your specific preferences.",
                      "Try selecting 'Any Body' or 'Any Sweetness' to expand choices.");
        } else {
            recommendations.forEach(rec => {
                const card = document.createElement('div');
                card.className = `wine-card ${rec.color}`;

                const header = document.createElement('div');
                header.className = 'wine-header';
                card.appendChild(header);

                // Format wine name (replace underscores with spaces)
                const name = document.createElement('h3');
                name.className = 'wine-name';
                name.textContent = rec.wine.replace(/_/g, ' ');
                header.appendChild(name);

                const badge = document.createElement('span');
                badge.className = 'wine-type-badge';
                badge.textContent = rec.color;
                header.appendChild(badge);

                const justification = document.createElement('p');
                justification.className = 'wine-justification';
                justification.textContent = rec.explanation;
                card.appendChild(justification);

                resultsContainer.appendChild(card);
            });
        }

    } catch (err) {
        console.error("Query execution error:", err);
        showError("Query execution failed.", err.message);
    }
}

// Convert Prolog terms to clean JS strings.
// Compound terms (objects with a functor) are JSON.stringified.
function formatPrologValue(val) {
    if (typeof val === 'string') return val;
    if (val && typeof val === 'object') {
        // Compound term: { $t: 'f', ... } or similar functor object
        return JSON.stringify(val);
    }
    return String(val);
}

// Start on page load
window.addEventListener('DOMContentLoaded', initProlog);
