# CIRO — Crisis Intelligence & Response Orchestrator
# AGENTS.md — Agent Constitution for Google Antigravity

## Project Overview
This is CIRO, an agentic crisis response system for Islamabad/Rawalpindi, Pakistan.
The system detects urban crises (flooding, heatwaves, accidents) using multi-source
signal fusion and coordinates automated emergency response.

## Tech Stack
- Frontend: Flutter (mobile app)
- Backend: Firebase Realtime Database + Cloud Functions
- AI: Google Gemini API via Antigravity
- Languages: Dart (Flutter) + JavaScript (Firebase Functions)

## Four Agents
1. SignalFusionAgent
2. CrisisClassifierAgent
3. ResourceAllocatorAgent
4. ResponseCoordinatorAgent

## Rules
- Every agent returns JSON with: agentName, timestamp, reasoning, decision, confidence
- Store all traces to Firebase under /traces/{agentName}/{timestamp}
- Use Islamabad/Rawalpindi as geographic context
- Label all mock data with: // MOCK DATA
- Console.log every decision: [AgentName] decision
