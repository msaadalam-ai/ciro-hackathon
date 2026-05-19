const Module = require('module');
const originalRequire = Module.prototype.require;

// 2. Mock Firebase Admin to avoid real credentials / DB writes
Module.prototype.require = function() {
    if (arguments[0] === 'firebase-admin') {
        return {
            initializeApp: () => console.log("[Mock] admin.initializeApp() bypassed"),
            database: () => ({
                ref: (path) => ({
                    set: async (data) => {
                        console.log(`[Mock] Blocked write to RTDB path: ${path}`);
                        return Promise.resolve();
                    }
                })
            })
        };
    }
    return originalRequire.apply(this, arguments);
};

// 1. Load all agents from index.js
const { SignalFusionAgent, CrisisClassifierAgent, ResourceAllocatorAgent, ResponseCoordinatorAgent, retractAlert } = require('./index.js');

// Helper to mock responses and capture JSON output
function createMockRes(agentIndex, agentName, resolve) {
    return {
        statusCode: 200,
        status: function(code) {
            this.statusCode = code;
            return this;
        },
        json: function(data) {
            console.log(`\n====== AGENT ${agentIndex}: ${agentName} OUTPUT ======`);
            console.log(`Status Code: ${this.statusCode}`);
            console.log(JSON.stringify(data, null, 2));
            console.log("================================");
            resolve(data);
        },
        send: function(data) {
            console.log(`\nResponse sent (Status ${this.statusCode}):`, data);
            resolve(data);
        }
    };
}

async function runTest() {
    console.log("Starting test run for Agent Chain...");
    if (!process.env.GEMINI_API_KEY) {
        console.warn("WARNING: GEMINI_API_KEY is not set. The agents will run with fallback simulated logic.");
    }
    
    // 1. Run SignalFusionAgent first and capture its JSON output
    const req1 = { method: 'POST', headers: {}, body: {} };
    const fusionOutput = await new Promise(async (resolve) => {
        const res1 = createMockRes(1, 'SignalFusionAgent', resolve);
        await SignalFusionAgent(req1, res1);
    });

    // 2. Pass that output as the request body to CrisisClassifierAgent
    console.log("\nRunning CrisisClassifierAgent using SignalFusionAgent output...");
    const req2 = { method: 'POST', headers: {}, body: fusionOutput };
    const classifierOutput = await new Promise(async (resolve) => {
        const res2 = createMockRes(2, 'CrisisClassifierAgent', resolve);
        await CrisisClassifierAgent(req2, res2);
    });

    // 3. Pass that output as the request body to ResourceAllocatorAgent
    console.log("\nRunning ResourceAllocatorAgent using CrisisClassifierAgent output...");
    const req3 = { method: 'POST', headers: {}, body: classifierOutput };
    const allocatorOutput = await new Promise(async (resolve) => {
        const res3 = createMockRes(3, 'ResourceAllocatorAgent', resolve);
        await ResourceAllocatorAgent(req3, res3);
    });

    // 4. Pass that output as the request body to ResponseCoordinatorAgent
    console.log("\nRunning ResponseCoordinatorAgent using ResourceAllocatorAgent output...");
    const req4 = { method: 'POST', headers: {}, body: allocatorOutput };
    await new Promise(async (resolve) => {
        const res4 = createMockRes(4, 'ResponseCoordinatorAgent', resolve);
        await ResponseCoordinatorAgent(req4, res4);
    });

    // 5. Run the False Alarm Retraction Scenario
    console.log("\n====== FALSE ALARM RETRACTION SCENARIO ======");
    const reqRetract = { method: 'POST', headers: {}, body: {} };
    await new Promise(async (resolve) => {
        const resRetract = createMockRes('RETRACT', 'retractAlert', resolve);
        await retractAlert(reqRetract, resRetract);
    });

    // At the end print chain complete
    console.log("\n====== COMPLETE CIRO PIPELINE ======");
}

runTest();
