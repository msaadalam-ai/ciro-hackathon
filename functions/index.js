const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

admin.initializeApp();

exports.SignalFusionAgent = onRequest(async (req, res) => {
    try {
        const timestamp = new Date().toISOString();

        // 1. Read all 4 mock data files
        // MOCK DATA
        const mockDataPath = path.join(__dirname, "../mock_data");
        const socialData = JSON.parse(fs.readFileSync(path.join(mockDataPath, "social_signals.json"), "utf8"));
        
        let weatherData = [];
        const openWeatherKey = process.env.OPENWEATHER_API_KEY;
        if (openWeatherKey) {
            console.log("[SignalFusionAgent] decision: Fetching real weather data from OpenWeatherMap API.");
            const cities = ['Islamabad,PK', 'Rawalpindi,PK'];
            for (const city of cities) {
                try {
                    const res = await fetch(`https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${openWeatherKey}&units=metric`);
                    if (res.ok) {
                        const data = await res.json();
                        const temp = data.main?.temp || 0;
                        const rainfall = data.rain?.['1h'] || 0;
                        let entry = {
                            id: `live_w_${city.split(',')[0].toLowerCase()}`,
                            type: "weather",
                            source: "DATA_SOURCE: LIVE - OpenWeatherMap API",
                            location: city.split(',')[0],
                            data: {
                                temperature_celsius: temp,
                                rainfall_mm_per_hour: rainfall
                            },
                            timestamp: new Date().toISOString()
                        };
                        if (rainfall > 10) entry.flood_risk = true;
                        if (temp > 40) entry.heatwave_risk = true;
                        weatherData.push(entry);
                    } else {
                        console.error(`[SignalFusionAgent] OpenWeatherMap API returned ${res.status} for ${city}`);
                    }
                } catch (err) {
                    console.error(`[SignalFusionAgent] error fetching weather for ${city}:`, err.message);
                }
            }
            if (weatherData.length === 0) {
                 console.log("[SignalFusionAgent] decision: Failed to fetch live weather, falling back to mock weather data.");
                 weatherData = JSON.parse(fs.readFileSync(path.join(mockDataPath, "weather_signals.json"), "utf8"));
            }
        } else {
            console.log("[SignalFusionAgent] decision: OPENWEATHER_API_KEY not found. Using mock weather data.");
            weatherData = JSON.parse(fs.readFileSync(path.join(mockDataPath, "weather_signals.json"), "utf8"));
        }

        const trafficData = JSON.parse(fs.readFileSync(path.join(mockDataPath, "traffic_signals.json"), "utf8"));
        const resourcesData = JSON.parse(fs.readFileSync(path.join(mockDataPath, "resources.json"), "utf8"));

        console.log("[SignalFusionAgent] decision: Successfully loaded data from all sources.");

        const geminiApiKey = process.env.GEMINI_API_KEY;

        const prompt = `
You are the SignalFusionAgent for CIRO (Crisis Intelligence & Response Orchestrator) in Islamabad/Rawalpindi.
Your task is to analyze the provided signals, fuse them, and output a structured JSON response.

Here is the data:
Social Signals: ${JSON.stringify(socialData)}
Weather Signals: ${JSON.stringify(weatherData)}
Traffic Signals: ${JSON.stringify(trafficData)}
Resources: ${JSON.stringify(resourcesData)}

Perform the following:
1. Score each signal credibility 0-100% based on source type, recency, urgency.
2. Detect the conflict between s1/s2 (flooding) and s3 (water main burst) for G-10.
3. Group signals by location.
4. Filter noise and duplicates.

Return EXACTLY a JSON object with this schema (and nothing else, no markdown):
{
  "agentName": "SignalFusionAgent",
  "timestamp": "${timestamp}",
  "reasoning": "string explaining how you fused the data, scored credibility, grouped by location, and filtered noise/duplicates.",
  "decision": "string summarizing your final assessment of the current crisis state.",
  "confidence": number between 0 and 1,
  "locationsDetected": ["G-10, Islamabad", "Saddar, Rawalpindi"],
  "conflicts": [{"location": "...", "description": "...", "signalsInvolved": ["s1", "s2", "s3"]}],
  "fusedSignals": [
    {
      "location": "...",
      "signals": [...],
      "overallCredibility": number 0-100
    }
  ]
}
`;
        
        let aiResult;
        if (geminiApiKey) {
            console.log("[SignalFusionAgent] decision: Calling Gemini API for signal fusion and conflict detection.");
            const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: prompt }] }],
                    generationConfig: { response_mime_type: "application/json" }
                })
            });

            if (!response.ok) {
                const errorText = await response.text();
                console.error("[SignalFusionAgent] decision: Gemini API error -", errorText);
                throw new Error(`Gemini API error: ${response.statusText}`);
            }

            const data = await response.json();
            const textResponse = data.candidates[0].content.parts[0].text;
            aiResult = JSON.parse(textResponse);
            console.log("[SignalFusionAgent] decision: Received and parsed Gemini API response.");
        } else {
            console.log("[SignalFusionAgent] decision: GEMINI_API_KEY not found. Using fallback logic.");
            aiResult = {
                agentName: "SignalFusionAgent",
                timestamp: timestamp,
                reasoning: "API key missing, simulated fusion.",
                decision: "Simulated response.",
                confidence: 0.5,
                locationsDetected: ["G-10, Islamabad", "Saddar, Rawalpindi"],
                conflicts: [{
                    location: "G-10, Islamabad", 
                    description: "Conflict between social reports of flooding and field report of water main burst.",
                    signalsInvolved: ["s1", "s2", "s3"]
                }],
                fusedSignals: []
            };
        }

        // Store trace to Firebase Realtime Database
        // Use a safe key for Firebase Realtime Database by stripping out invalid characters from timestamp
        const traceKey = timestamp.replace(/[.#$[\]]/g, "_");
        await admin.database().ref(`/traces/SignalFusionAgent/${traceKey}`).set(aiResult);
        console.log(`[SignalFusionAgent] decision: Stored trace to Firebase Realtime Database under /traces/SignalFusionAgent/${traceKey}`);

        res.status(200).json(aiResult);

    } catch (error) {
        console.error("[SignalFusionAgent] error:", error.message);
        console.log("[SignalFusionAgent] decision: Falling back to rule-based analysis.");
        
        const fallbackTimestamp = new Date().toISOString();
        const traceKey = fallbackTimestamp.replace(/[.#$[\]]/g, "_");
        const fallbackResult = {
            agentName: "SignalFusionAgent",
            timestamp: fallbackTimestamp,
            reasoning: "DATA_SOURCE: FALLBACK - Gemini API unavailable. Scored credibility based on rules: Field Report (90%), Twitter (70%), Facebook (65%).",
            decision: "Rule-based assessment: Flooding reports in G-10 conflict with a highly credible field report of a water main burst. High heat detected in Saddar.",
            confidence: 0.6,
            locationsDetected: ["G-10, Islamabad", "Saddar, Rawalpindi"],
            conflicts: [{
                location: "G-10, Islamabad", 
                description: "Conflict between social reports of flooding and field report of water main burst.",
                signalsInvolved: ["s1", "s2", "s3"]
            }],
            fusedSignals: [
                {
                    location: "G-10, Islamabad",
                    signals: [
                        { id: "s1", credibility: 70 },
                        { id: "s2", credibility: 65 },
                        { id: "s3", credibility: 90 }
                    ],
                    overallCredibility: 85
                },
                {
                    location: "Saddar, Rawalpindi",
                    signals: [
                        { id: "s4", credibility: 70 }
                    ],
                    overallCredibility: 70
                }
            ]
        };

        try {
            await admin.database().ref(`/traces/SignalFusionAgent/${traceKey}`).set(fallbackResult);
            console.log(`[SignalFusionAgent] decision: Stored fallback trace to Firebase Realtime Database under /traces/SignalFusionAgent/${traceKey}`);
        } catch (dbError) {
            console.error("[SignalFusionAgent] error: Could not store fallback trace to DB", dbError.message);
        }

        res.status(200).json(fallbackResult);
    }
});

exports.CrisisClassifierAgent = onRequest(async (req, res) => {
    try {
        const timestamp = new Date().toISOString();
        const fusionData = req.body || {};
        
        console.log("[CrisisClassifierAgent] decision: Received input from SignalFusionAgent.");

        const geminiApiKey = process.env.GEMINI_API_KEY;

        const prompt = `
You are the CrisisClassifierAgent for CIRO (Crisis Intelligence & Response Orchestrator).
Your task is to receive fused signal data, classify the crisis, score severity, handle conflicts, and predict evolution.

Here is the fused signal data:
${JSON.stringify(fusionData, null, 2)}

Perform the following strict rules:
1. CLASSIFY each location's crisis:
   - G-10 Islamabad: classify as BOTH urban_flooding (primary) AND water_main_burst (alternative) because signals conflict.
   - Saddar Rawalpindi: classify as heatwave based on 47C temperature.
2. SCORE severity 1-10 with explanation:
   - G-10: severity 8 (high confidence on water issue, uncertain on type).
   - Rawalpindi: severity 7 (extreme heat, vulnerable population).
3. HANDLE the conflict for G-10 explicitly:
   - Social posts credibility 65-70% say flooding.
   - Field report credibility 90% says water main burst.
   - Acknowledge conflict, recommend field verification. Do NOT force a single conclusion.
4. PREDICT evolution:
   - Estimated duration hours
   - Affected radius km
   - Population at risk estimate
   - Spread risk if untreated

Return EXACTLY a JSON object with this schema (and nothing else, no markdown):
{
  "agentName": "CrisisClassifierAgent",
  "timestamp": "${timestamp}",
  "reasoning": "string explaining how you classified, scored, handled conflict, and predicted evolution",
  "confidence": number between 0 and 1,
  "crises": [
    {
      "location": "...",
      "classification": ["...", "..."],
      "severityScore": number 1-10,
      "severityExplanation": "...",
      "conflictResolution": "...",
      "prediction": {
        "durationHours": number,
        "affectedRadiusKm": number,
        "populationAtRisk": number,
        "spreadRisk": "..."
      }
    }
  ]
}
`;

        let aiResult;
        if (geminiApiKey) {
            console.log("[CrisisClassifierAgent] decision: Calling Gemini API (gemini-2.0-flash) for classification.");
            const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiApiKey}`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: prompt }] }],
                    generationConfig: { response_mime_type: "application/json" }
                })
            });

            if (!response.ok) {
                const errorText = await response.text();
                console.error("[CrisisClassifierAgent] error: Gemini API error -", errorText);
                throw new Error(`Gemini API error: ${response.statusText}`);
            }

            const data = await response.json();
            const textResponse = data.candidates[0].content.parts[0].text;
            aiResult = JSON.parse(textResponse);
            console.log("[CrisisClassifierAgent] decision: Successfully parsed Gemini classification response.");
        } else {
            throw new Error("GEMINI_API_KEY not found. Forcing fallback logic.");
        }

        const traceKey = timestamp.replace(/[.#$[\]]/g, "_");
        await admin.database().ref(`/traces/CrisisClassifierAgent/${traceKey}`).set(aiResult);
        console.log(`[CrisisClassifierAgent] decision: Stored trace to Firebase Realtime Database under /traces/CrisisClassifierAgent/${traceKey}`);

        res.status(200).json(aiResult);

    } catch (error) {
        console.error("[CrisisClassifierAgent] error:", error.message);
        console.log("[CrisisClassifierAgent] decision: Falling back to rule-based classification.");
        
        const fallbackTimestamp = new Date().toISOString();
        const traceKey = fallbackTimestamp.replace(/[.#$[\]]/g, "_");
        
        const fallbackResult = {
            agentName: "CrisisClassifierAgent",
            timestamp: fallbackTimestamp,
            reasoning: "DATA_SOURCE: FALLBACK - Gemini API unavailable. Applied rule-based classification for G-10 and Saddar.",
            confidence: 0.6,
            crises: [
                {
                    location: "G-10, Islamabad",
                    classification: ["urban_flooding", "water_main_burst"],
                    severityScore: 8,
                    severityExplanation: "High confidence on water issue, uncertain on type.",
                    conflictResolution: "Social posts credibility 65-70% say flooding. Field report credibility 90% says water main burst. Conflict acknowledged. Recommend field verification immediately. Did not force a single conclusion.",
                    prediction: {
                        durationHours: 12,
                        affectedRadiusKm: 2.5,
                        populationAtRisk: 5000,
                        spreadRisk: "High risk of road damage and further traffic gridlock if untreated."
                    }
                },
                {
                    location: "Saddar, Rawalpindi",
                    classification: ["heatwave"],
                    severityScore: 7,
                    severityExplanation: "Extreme heat of 47C poses severe risk to vulnerable population.",
                    conflictResolution: "No conflicting signals. High credibility on extreme heat.",
                    prediction: {
                        durationHours: 8,
                        affectedRadiusKm: 10,
                        populationAtRisk: 15000,
                        spreadRisk: "Risk of widespread heatstroke if emergency cooling centers are not activated."
                    }
                }
            ]
        };

        try {
            await admin.database().ref(`/traces/CrisisClassifierAgent/${traceKey}`).set(fallbackResult);
            console.log(`[CrisisClassifierAgent] decision: Stored fallback trace to Firebase Realtime Database under /traces/CrisisClassifierAgent/${traceKey}`);
        } catch (dbError) {
            console.error("[CrisisClassifierAgent] error: Could not store fallback trace to DB", dbError.message);
        }

        res.status(200).json(fallbackResult);
    }
});

exports.ResourceAllocatorAgent = onRequest(async (req, res) => {
    try {
        const timestamp = new Date().toISOString();
        const classifierData = req.body || {};
        
        console.log("[ResourceAllocatorAgent] decision: Received input from CrisisClassifierAgent.");

        const mockDataPath = path.join(__dirname, "../mock_data");
        const resourcesData = JSON.parse(fs.readFileSync(path.join(mockDataPath, "resources.json"), "utf8"));

        const geminiApiKey = process.env.GEMINI_API_KEY;

        const prompt = `
You are the ResourceAllocatorAgent for CIRO.
Your task is to allocate constrained resources to classified crises based on severity, uncertainty, and physical distance.

Here is the crisis classification data:
${JSON.stringify(classifierData, null, 2)}

Here is the current resource availability and locations:
${JSON.stringify(resourcesData, null, 2)}

Perform the following strict rules:
1. PRIORITIZE the two crises:
   - G-10 Islamabad (severity 8) gets priority but Saddar Rawalpindi (severity 7) cannot be ignored.
2. ALLOCATE these constrained resources across BOTH crises:
   - 3 ambulances total
   - 2 rescue teams total  
   - 4 police units total
   - 2 water tankers total
   - 1 medical outreach team total
3. SHOW explicit tradeoffs:
   - What Crisis 2 loses because Crisis 1 gets priority
   - Why each resource went where it did
4. HANDLE G-10 uncertainty:
   - Since flooding vs water main is unconfirmed, allocate conservatively.
   - Send water tankers for water main scenario.
   - Keep one rescue team on standby pending field verification.
5. CALCULATE travel time from resource_locations to incident locations (use straight-line approximation, roughly 1km = 2 mins).
6. SHOW before state and after state of resources.

Return EXACTLY a JSON object with this schema (and nothing else, no markdown):
{
  "agentName": "ResourceAllocatorAgent",
  "timestamp": "${timestamp}",
  "allocations": [
    {
      "resourceType": "...",
      "quantityAllocated": number,
      "destination": "...",
      "estimatedTravelTimeMinutes": number,
      "allocationReasoning": "..."
    }
  ],
  "tradeoffs": [
    "tradeoff description 1",
    "tradeoff description 2"
  ],
  "standbyResources": [
    {
      "resourceType": "...",
      "quantity": number,
      "standbyReason": "..."
    }
  ],
  "beforeState": { "ambulances": 3, "rescue_teams": 2, "police_units": 4, "water_tankers": 2, "medical_outreach_teams": 1 },
  "afterState": { ... },
  "totalResponseTimeMinutes": number
}
`;

        let aiResult;
        if (geminiApiKey) {
            console.log("[ResourceAllocatorAgent] decision: Calling Gemini API for resource allocation.");
            const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiApiKey}`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: prompt }] }],
                    generationConfig: { response_mime_type: "application/json" }
                })
            });

            if (!response.ok) {
                const errorText = await response.text();
                console.error("[ResourceAllocatorAgent] error: Gemini API error -", errorText);
                throw new Error(`Gemini API error: ${response.statusText}`);
            }

            const data = await response.json();
            const textResponse = data.candidates[0].content.parts[0].text;
            aiResult = JSON.parse(textResponse);
            console.log("[ResourceAllocatorAgent] decision: Successfully parsed Gemini allocation response.");
        } else {
            throw new Error("GEMINI_API_KEY not found. Forcing fallback logic.");
        }

        if (aiResult && aiResult.allocations) {
            aiResult.allocations.forEach(alloc => {
                console.log(`[ResourceAllocatorAgent] ALLOCATE: ${alloc.quantityAllocated} ${alloc.resourceType} to ${alloc.destination} REASON: ${alloc.allocationReasoning}`);
            });
        }

        const traceKey = timestamp.replace(/[.#$[\]]/g, "_");
        await admin.database().ref(`/traces/ResourceAllocatorAgent/${traceKey}`).set(aiResult);
        console.log(`[ResourceAllocatorAgent] decision: Stored trace to Firebase Realtime Database under /traces/ResourceAllocatorAgent/${traceKey}`);

        res.status(200).json(aiResult);

    } catch (error) {
        console.error("[ResourceAllocatorAgent] error:", error.message);
        console.log("[ResourceAllocatorAgent] decision: Falling back to rule-based allocation.");
        
        const fallbackTimestamp = new Date().toISOString();
        const traceKey = fallbackTimestamp.replace(/[.#$[\]]/g, "_");
        
        const fallbackResult = {
            agentName: "ResourceAllocatorAgent",
            timestamp: fallbackTimestamp,
            allocations: [
                {
                    resourceType: "ambulances",
                    quantityAllocated: 2,
                    destination: "Saddar, Rawalpindi",
                    estimatedTravelTimeMinutes: 25,
                    allocationReasoning: "Heatwave poses severe immediate risk to life, needs transport for heatstroke victims."
                },
                {
                    resourceType: "ambulances",
                    quantityAllocated: 1,
                    destination: "G-10, Islamabad",
                    estimatedTravelTimeMinutes: 10,
                    allocationReasoning: "Standby for possible water incident casualties."
                },
                {
                    resourceType: "police_units",
                    quantityAllocated: 3,
                    destination: "G-10, Islamabad",
                    estimatedTravelTimeMinutes: 8,
                    allocationReasoning: "Required immediately to block flooded roads or water main burst area and manage traffic."
                },
                {
                    resourceType: "police_units",
                    quantityAllocated: 1,
                    destination: "Saddar, Rawalpindi",
                    estimatedTravelTimeMinutes: 20,
                    allocationReasoning: "Crowd control around emergency cooling centers."
                },
                {
                    resourceType: "water_tankers",
                    quantityAllocated: 2,
                    destination: "G-10, Islamabad",
                    estimatedTravelTimeMinutes: 15,
                    allocationReasoning: "Sent to provide backup clean water if water main burst is confirmed."
                },
                {
                    resourceType: "rescue_teams",
                    quantityAllocated: 1,
                    destination: "G-10, Islamabad",
                    estimatedTravelTimeMinutes: 12,
                    allocationReasoning: "Field verification required for conflicting signals (flooding vs water main)."
                },
                {
                    resourceType: "medical_outreach_teams",
                    quantityAllocated: 1,
                    destination: "Saddar, Rawalpindi",
                    estimatedTravelTimeMinutes: 22,
                    allocationReasoning: "Setup mobile cooling and hydration stations for heatwave."
                }
            ],
            tradeoffs: [
                "Saddar (Crisis 2) receives no heavy rescue teams because G-10's water crisis requires immediate technical verification and potential extraction.",
                "G-10 only gets 1 ambulance because Saddar's extreme heatwave requires more direct medical transport capacity for vulnerable populations."
            ],
            standbyResources: [
                {
                    resourceType: "rescue_teams",
                    quantity: 1,
                    standbyReason: "Kept on standby pending field verification of G-10 incident type (urban flooding vs simple water main burst)."
                }
            ],
            beforeState: {
                "ambulances": 3,
                "rescue_teams": 2,
                "police_units": 4,
                "water_tankers": 2,
                "medical_outreach_teams": 1
            },
            afterState: {
                "ambulances": 0,
                "rescue_teams": 0,
                "police_units": 0,
                "water_tankers": 0,
                "medical_outreach_teams": 0
            },
            totalResponseTimeMinutes: 25
        };

        fallbackResult.allocations.forEach(alloc => {
            console.log(`[ResourceAllocatorAgent] ALLOCATE: ${alloc.quantityAllocated} ${alloc.resourceType} to ${alloc.destination} REASON: ${alloc.allocationReasoning}`);
        });

        try {
            await admin.database().ref(`/traces/ResourceAllocatorAgent/${traceKey}`).set(fallbackResult);
            console.log(`[ResourceAllocatorAgent] decision: Stored fallback trace to Firebase Realtime Database under /traces/ResourceAllocatorAgent/${traceKey}`);
        } catch (dbError) {
            console.error("[ResourceAllocatorAgent] error: Could not store fallback trace to DB", dbError.message);
        }

        res.status(200).json(fallbackResult);
    }
});

exports.ResponseCoordinatorAgent = onRequest(async (req, res) => {
    try {
        const timestamp = new Date().toISOString();
        const allocationData = req.body || {};
        
        console.log("[ResponseCoordinatorAgent] decision: Received input from ResourceAllocatorAgent.");

        const geminiApiKey = process.env.GEMINI_API_KEY;

        const prompt = `
You are the ResponseCoordinatorAgent for CIRO.
Your task is to receive resource allocation data and generate actionable responses, alerts, and stakeholder messages.

Here is the resource allocation data:
${JSON.stringify(allocationData, null, 2)}

Perform the following strict rules:
1. PUBLIC ALERTS in both Urdu and English:
   Urdu: "G-10 mein paani bhar gaya hai — is area se guzarna avoid karein"
   English: "PRELIMINARY ALERT: Water emergency in G-10, Islamabad. Avoid the area."
   Mark both as: status: "PRELIMINARY - field verification pending"
2. TRAFFIC REROUTING for G-10:
   - Suggest 2 alternate routes around G-10
   - Show congestion_before: 9.2 and congestion_expected_after: 4.1
3. STAKEHOLDER MESSAGES (separate message for each):
   - PIMS Hospital: prepare for potential casualties
   - Islamabad Police: traffic management instructions
   - Rescue 1122: standby instructions
   - WASA Water Authority: investigate water main on Street 12 G-10
   - Media/Command Center: situation summary
4. HEATWAVE RESPONSE for Rawalpindi:
   - Medical outreach dispatch instructions
   - Public alert in Urdu and English
   - Nearest cooling center locations

Return EXACTLY a JSON object with this schema (and nothing else, no markdown):
{
  "agentName": "ResponseCoordinatorAgent",
  "timestamp": "${timestamp}",
  "publicAlerts": [
    {
      "location": "...",
      "language": "...",
      "message": "...",
      "status": "..."
    }
  ],
  "trafficRerouting": {
    "location": "...",
    "alternateRoutes": ["...", "..."],
    "congestion_before": number,
    "congestion_expected_after": number
  },
  "stakeholderMessages": [
    {
      "stakeholder": "...",
      "message": "..."
    }
  ],
  "heatwaveResponse": {
    "location": "...",
    "dispatchInstructions": "...",
    "publicAlerts": [
      {"language": "...", "message": "..."}
    ],
    "coolingCenters": ["...", "..."]
  }
}
`;

        let aiResult;
        if (geminiApiKey) {
            console.log("[ResponseCoordinatorAgent] decision: Calling Gemini API for response generation.");
            const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiApiKey}`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: prompt }] }],
                    generationConfig: { response_mime_type: "application/json" }
                })
            });

            if (!response.ok) {
                const errorText = await response.text();
                console.error("[ResponseCoordinatorAgent] error: Gemini API error -", errorText);
                throw new Error(`Gemini API error: ${response.statusText}`);
            }

            const data = await response.json();
            const textResponse = data.candidates[0].content.parts[0].text;
            aiResult = JSON.parse(textResponse);
            console.log("[ResponseCoordinatorAgent] decision: Successfully parsed Gemini response.");
        } else {
            throw new Error("GEMINI_API_KEY not found. Forcing fallback logic.");
        }

        const traceKey = timestamp.replace(/[.#$[\]]/g, "_");
        await admin.database().ref(`/actions/${traceKey}`).set(aiResult);
        await admin.database().ref(`/traces/ResponseCoordinatorAgent/${traceKey}`).set(aiResult);
        console.log(`[ResponseCoordinatorAgent] decision: Stored actions to /actions/${traceKey} and trace to /traces/ResponseCoordinatorAgent/${traceKey}`);

        res.status(200).json(aiResult);

    } catch (error) {
        console.error("[ResponseCoordinatorAgent] error:", error.message);
        console.log("[ResponseCoordinatorAgent] decision: Falling back to rule-based response generation.");
        
        const fallbackTimestamp = new Date().toISOString();
        const traceKey = fallbackTimestamp.replace(/[.#$[\]]/g, "_");
        
        const fallbackResult = {
            agentName: "ResponseCoordinatorAgent",
            timestamp: fallbackTimestamp,
            publicAlerts: [
                {
                    location: "G-10, Islamabad",
                    language: "Urdu",
                    message: "G-10 mein paani bhar gaya hai — is area se guzarna avoid karein",
                    status: "PRELIMINARY - field verification pending"
                },
                {
                    location: "G-10, Islamabad",
                    language: "English",
                    message: "PRELIMINARY ALERT: Water emergency in G-10, Islamabad. Avoid the area.",
                    status: "PRELIMINARY - field verification pending"
                }
            ],
            trafficRerouting: {
                location: "G-10, Islamabad",
                alternateRoutes: ["Kashmir Highway via G-9", "Ibn-e-Sina Road via F-10"],
                congestion_before: 9.2,
                congestion_expected_after: 4.1
            },
            stakeholderMessages: [
                { stakeholder: "PIMS Hospital", message: "Prepare for potential casualties from G-10 water emergency." },
                { stakeholder: "Islamabad Police", message: "Traffic management instructions: Block flooded roads around G-10." },
                { stakeholder: "Rescue 1122", message: "Standby instructions: Keep heavy rescue teams on standby pending field verification of G-10 incident type." },
                { stakeholder: "WASA Water Authority", message: "Investigate water main on Street 12 G-10 immediately." },
                { stakeholder: "Media/Command Center", message: "Situation summary: Preliminary water emergency in G-10 and confirmed heatwave in Saddar. Response initiated." }
            ],
            heatwaveResponse: {
                location: "Saddar, Rawalpindi",
                dispatchInstructions: "Setup mobile cooling and hydration stations. Dispatch medical outreach teams.",
                publicAlerts: [
                    { language: "Urdu", message: "Shadeed garmi ki leher. Bahar nikalne se gurez karein." },
                    { language: "English", message: "Extreme heatwave alert. Stay indoors and hydrate." }
                ],
                coolingCenters: ["Saddar Community Hall", "Rawalpindi General Hospital lobby"]
            }
        };

        try {
            await admin.database().ref(`/actions/${traceKey}`).set(fallbackResult);
            await admin.database().ref(`/traces/ResponseCoordinatorAgent/${traceKey}`).set(fallbackResult);
            console.log(`[ResponseCoordinatorAgent] decision: Stored fallback actions to /actions/${traceKey} and trace to /traces/ResponseCoordinatorAgent/${traceKey}`);
        } catch (dbError) {
            console.error("[ResponseCoordinatorAgent] error: Could not store fallback trace to DB", dbError.message);
        }

        res.status(200).json(fallbackResult);
    }
});

exports.retractAlert = onRequest(async (req, res) => {
    const timestamp = new Date().toISOString();
    const traceKey = timestamp.replace(/[.#$[\]]/g, "_");
    
    console.log("[ResponseCoordinatorAgent] decision: RETRACT: flood alert for G-10 - confirmed water main burst");
    
    const retractionResult = {
        agentName: "ResponseCoordinatorAgent",
        actionType: "RETRACTION",
        timestamp: timestamp,
        statusChange: {
            location: "G-10, Islamabad",
            from: "urban_flooding",
            to: "water_main_burst"
        },
        publicAlertsRetracted: true,
        stakeholderCorrections: [
            { stakeholder: "WASA Water Authority", message: "Urgent: Confirmed water main burst at Street 12 G-10. Immediate repair required." },
            { stakeholder: "Rescue 1122", message: "Stand down flood rescue. It is a water main burst." },
            { stakeholder: "Islamabad Police", message: "Maintain traffic diversion due to water main burst." }
        ]
    };

    try {
        await admin.database().ref(`/actions/${traceKey}`).set(retractionResult);
        await admin.database().ref(`/traces/ResponseCoordinatorAgent/${traceKey}`).set(retractionResult);
        console.log(`[ResponseCoordinatorAgent] decision: Stored retraction actions to /actions/${traceKey} and trace to /traces/ResponseCoordinatorAgent/${traceKey}`);
    } catch (dbError) {
        console.error("[ResponseCoordinatorAgent] error: Could not store retraction trace to DB", dbError.message);
    }

    res.status(200).json(retractionResult);
});

exports.CiroAssistantAgent = onRequest(async (req, res) => {
    try {
        const timestamp = new Date().toISOString();
        const userQuestion = req.body.question || "What is the status?";
        
        console.log(`[CiroAssistantAgent] Received question: ${userQuestion}`);

        const geminiApiKey = process.env.GEMINI_API_KEY;

        const prompt = `
You are CIRO, an AI crisis intelligence assistant for Islamabad/Rawalpindi Pakistan.
Current active crises: 
1. G-10 Islamabad - Water emergency (flooding vs water main burst - under investigation) Severity 8/10
2. Saddar Rawalpindi - Extreme Heatwave 47C Severity 7/10
Resources deployed: 9 total across both crises.
You help emergency commanders make decisions. Answer questions about the crisis,
resource allocation, recommended actions, and response status.
Keep answers concise and actionable. Respond in the same language the user asks in.
If asked in Urdu, respond in Urdu.

User Question: "${userQuestion}"

Return EXACTLY a JSON object with this schema (and nothing else, no markdown):
{
  "agentName": "CiroAssistantAgent",
  "timestamp": "${timestamp}",
  "response": "your detailed but concise response"
}
`;

        let aiResult;
        if (geminiApiKey) {
            console.log("[CiroAssistantAgent] Calling Gemini API...");
            const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiApiKey}`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: prompt }] }],
                    generationConfig: { response_mime_type: "application/json" }
                })
            });

            if (!response.ok) {
                throw new Error(`Gemini API error: ${response.statusText}`);
            }

            const data = await response.json();
            const textResponse = data.candidates[0].content.parts[0].text;
            aiResult = JSON.parse(textResponse);
        } else {
            throw new Error("GEMINI_API_KEY not found.");
        }

        const traceKey = timestamp.replace(/[.#$[\]]/g, "_");
        await admin.database().ref(`/traces/CiroAssistantAgent/${traceKey}`).set({
            question: userQuestion,
            ...aiResult
        });

        res.status(200).json(aiResult);

    } catch (error) {
        console.error("[CiroAssistantAgent] error:", error.message);
        const fallbackResult = {
            agentName: "CiroAssistantAgent",
            timestamp: new Date().toISOString(),
            response: "I am operating in offline mock mode right now. The G-10 crisis is a water main burst with severity 8, and Saddar has a 47C heatwave. 9 resources are deployed."
        };
        res.status(200).json(fallbackResult);
    }
});

