# CLAUDE.md

## Project Operating Instructions for Claude Code

You are working on an iOS AI-powered nutrition and GLP-1 tracking application.

Follow these rules strictly.

---

## 1. CODE STYLE

• SwiftUI only (no UIKit unless necessary for scanner bridge)
• iOS 17+
• Async/await
• Clean, modular files
• Small view structs
• No massive files
• Follow MVVM strictly
• No business logic inside Views
• Repository pattern required

---

## 2. AI INTEGRATION RULES

• All Anthropic responses must decode to strict JSON schema
• Reject malformed responses
• Never trust AI nutrition values without verification
• AI suggests → user confirms → then log
• Never give medical advice

---

## 3. FOOD DATABASE RULES

• OFF is for packaged foods
• Generic foods come from internal DB
• Do not fabricate nutrients
• If nutrients missing → show partial data
• Always scale via gram base

---

## 4. MEDICATION RULES

• GLP-1 tracker is reminders only
• No dosage recommendations
• No medical optimization
• Always include safety disclaimer

---

## 5. SECURITY RULES

• Store API keys in Keychain
• No plaintext PHI
• No analytics without explicit toggle
• Support local-only mode

---

## 6. NOTIFICATIONS

• Use UserNotifications
• Request permission responsibly
• Allow granular toggles
• Never spam

---

## 7. ERROR HANDLING

• Never crash on API failure
• Provide fallbacks
• Log structured errors

---

## 8. TESTING STANDARD

• Unit tests for all nutrition math
• Test AI decoding
• Test macro calculations
• Test repository routing

---

## 9. OUTPUT EXPECTATIONS

When generating code:

• Provide file tree first
• Then core models
• Then services
• Then UI
• Then setup instructions
• Then TODO list

Do not provide partial builds.
Do not skip architecture.

This project must be App Store deployable quality.

---

END CLAUDE.md
