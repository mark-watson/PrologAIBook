// app.js - ShipLogic application to load SWI-Prolog WASM and query recommendations

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
