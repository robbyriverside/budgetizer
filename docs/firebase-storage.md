# Firebase Storage Analysis for Budgetizer

This document evaluates the available Firebase storage solutions to determine the best fit for the Budgetizer application ("apps/web"), based on its architectural needs and data patterns.

## Available Options Summary

*   **Firebase Data Connect (SQL)**: Connects to PostgreSQL in Cloud SQL. Best for strictly relational data requiring full SQL support.
*   **Cloud Firestore (NoSQL)**: Flexible, scalable document database with collections and documents. Ideal for complex hierarchical data, expressive querying, and offline support.
*   **Realtime Database (NoSQL)**: Stores data as a single JSON tree. Best for simple structures and high-frequency real-time syncing (e.g., chat, presence).
*   **Cloud Storage**: For files like images, video, and audio.
*   **Remote Config**: For dynamic key-value storage to change app behavior without updates.

---

## Budgetizer Requirements Analysis

Below is an analysis of the Budgetizer app's specific needs in response to key architectural questions:

### 1. What kind of data structure does your Budgetizer app primarily need?

**Answer: Document-Based (Hybrid)**

While financial data is traditionally relational (Accounts <-> Transactions), the Budgetizer web app implementation has opted for a **Document-Oriented** approach to optimize for performance and billing.

*   **Current Architecture**: Data is aggregated into "Cycles" (e.g., `checking_1_2025-01`). A single document contains the metadata for the month *and* the entire list of transactions for that period, serialized as JSON.
*   **Why Firestore fits**: Firestore's document model allows us to retrieve an entire month's financial context in a single read operation (`get()`). This effectively mimics a "Unit of Work" pattern where a month is loaded, modified in memory, and saved back. A pure SQL approach (Data Connect) would require joining tables for every view, which is unnecessary given the "monthly bucket" access pattern. The Realtime Database's single giant JSON tree would be inefficient for querying specific months across years of history.

### 2. Do you anticipate a high volume of user-generated content like receipts or images?

**Answer: No.**

*   **Current Scope**: The application currently manages structured text and numerical data: transaction amounts, merchant names, tags, and budget limits.
*   **Future Implications**: If features like "Receipt Scanning" or "Attachment Uploading" are added in the future, **Cloud Storage for Firebase** would be the correct add-on service to handle those binaries, verifying that the main database (Firestore) continues to store only the *references* (URLs) to those files.

### 3. Are there specific real-time synchronization requirements for your app?

**Answer: Minimal / On-Demand.**

*   **Current Usage**: The application primarily uses **One-Time Reads** (`get()`) rather than real-time streams (`snapshots()`).
    *   *Reasoning*: Financial reporting generally doesn't require sub-second updates like a chat app. Users typically load the dashboard to see a snapshot of their finances.
*   **Offline Capability**: The app *does* rely on offline persistence so users can view their data without an internet connection. Firestore's SDK handles this caching automatically, even without using real-time listeners.

## Conclusion & Recommendation

**Selected Solution: [Cloud Firestore]**

Cloud Firestore is the optimal choice for the Budgetizer web app because:
1.  **Data Modeling**: It supports the "Cycle" document structure perfectly, allowing for encapsulated reads of monthly data.
2.  **Querying**: It offers sufficient querying capabilities (filtering by date, type, etc.) for generating reports.
3.  **Cost Efficiency**: The usage pattern (low read frequency, batched writes) fits the Firestore billing model well.
4.  **Offline Support**: Built-in caching is essential for a robust web/mobile experience.

**Secondary Services**:
*   **Firebase Hosting**: Recommended for serving the Flutter Web static assets.
*   **Remote Config**: Could be useful for managing feature flags (e.g., enabling/disabling "Experimental AI Tagging").

---

## Strategic Considerations

### Security & Data Protection
**Goal**: restrict access to sensitive financial data.
*   **Authentication**: Implementing Firebase Authentication (Google Sign-In) is a prerequisite.
*   **Security Rules Strategy**: Rules will be structured to check the `request.auth.uid`. If the app is single-user (personal), we can whitelist a specific UID. If multi-user, every document in `cashflow_cycles` should include an `owner_uid` field, and rules will enforce `allow read, write: if request.auth.uid == resource.data.owner_uid;`.

### Historical Data & Reporting
**Goal**: Manage long-term history without performance degradation.
*   **Strategy**: Since cycles are stored as individual documents by month (e.g., `2025-01`), history scales naturally.
*   **Querying**: To generate multi-year reports without reading hundreds of documents, we can maintain a separate `annual_summaries` collection. This collection would store aggregated totals (income, expense, savings) per year, updated via Cloud Functions whenever a cycle changes. This follows the "denormalization" pattern common in NoSQL to optimize read performance.

### Automation with Cloud Functions
**Goal**: Automate maintenance tasks.
*   **Potential Use**:
    *   **Aggregation**: Automatically update the `annual_summaries` collection mentioned above when a `cashflow_cycle` is written (using an `onWrite` trigger).
    *   **Backups**: Periodically export data to a JSON file in Cloud Storage for archival purposes.
    *   **Sanitization**: Automatically scrub sensitive PII from descriptions if sharing data or creating sample datasets.

---
# Other considerations

### Operational Strategy

#### 1. Firebase Extensions vs. Custom Functions
**Recommendation**: **Hybrid Approach**
*   **Use Extensions for standard tasks**: We should evaluate the **"Trigger Email from Firestore"** extension to send monthly summary emails or alerts without writing custom code.
*   **Use Custom Functions for domain logic**: The aggregation of  into  is highly specific to our data schema (parsing the JSON blob in the cycle document). This requires a custom TypeScript Cloud Function.

#### 2. Data Migration & Schema Changes
**Strategy**: **Lazy Migration (Read-Time)**
*   NoSQL schemas evolve. Instead of running massive batch scripts to update every document when a field changes (e.g., adding a new tag category), we handle it in the application code.
*   **Implementation**: In the  method in Dart, we check for missing fields and provide default values. If the record is saved again, the new schema is written.
*   **Versioning**: For major breaking changes, we can add a  field to documents.

#### 3. Monitoring Performance & Costs
**Tools**:
*   **Firebase Console Usage Tab**: Monitor daily read/write counts against the free tier quotas (50k reads/day).
*   **Firestore Key Visualizer**: If traffic scales significantly, valid for spotting hotspots.
*   **Cost Alerts**: Set up a budget alert in the Google Cloud Console (e.g., alert if projected cost > $1) to prevent accidental bill shock from infinite loops.


#### 4. Handling Concurrency & Race Conditions
**Challenge**: Multiple instances attempting "lazy migration" or concurrent updates.
*   **Transactions**: Use Firestore Transactions (`runTransaction`) for operations that depend on the current value of a document (e.g., updating a balance). This ensures that if the document changes during the operation, the transaction retries.
*   **Merge Writes**: For lazy migration, use `SetOptions(merge: true)` so that unrelated fields aren't overwritten if we are just backfilling a new field.
*   **Idempotency**: Cloud Functions should be designed to be idempotent. If an event is delivered more than once, the function should handle it gracefully without corrupting data (e.g., checking `context.eventId` or verifying if the aggregation is already up-to-date).

#### 5. Testing Strategy
**Goal**: Robust validation of serverless logic.
*   **Refactoring**: Separate business logic from the Cloud Function triggers so it can be unit tested in isolation with standard testing frameworks (like Jest or Mocha).
*   **Local Emulation**: Use the **Firebase Local Emulator Suite** heavily. This allows running integration tests against a local instance of Firestore and Cloud Functions without hitting production or incurring costs.
*   **CI/CD**: Specific tests should run on every pull request to verify that new schema changes or function logic don't break existing data flows.

#### 6. Advanced Monitoring Metrics
**Beyond Costs**:
*   **Function Execution Time**: Monitor latency in Google Cloud Monitoring. Slow functions can time out or degrade user experience.
*   **Cold Starts**: Track the frequency of cold starts to decide if `minInstances` is needed for critical functions.
*   **Error Rates**: Set up alerting for any spikes in 4xx or 5xx errors from Cloud Functions, indicating handled or unhandled exceptions.
*   **Snapshot Listener Count**: If we start using real-time listeners, monitor the number of active listeners to ensure we don't hit scaling limits for a single document.

#### 7. CI/CD Integration with Emulators
**Automation**:
*   **Pipeline Setup**: Integrate the Firebase Emulator Suite into the CI/CD pipeline (e.g., GitHub Actions). Use the `firebase emulators:exec` command to start the emulators, run the test suite, and then shut down.
*   **Pre-merge Checks**: Block pull requests if the emulator-based integration tests fail. This ensures that no breaking changes are deployed to the live environment.
*   **Caching**: Cache emulator binaries in the CI pipeline to speed up build times.

#### 8. Structured Logging Strategy
**Debugging**:
*   **JSON Logging**: Use structured JSON logging (instead of plain text `console.log`) in Cloud Functions. This allows filtering logs by severity, component, or specific fields (e.g., `transactionId`) in Cloud Logging.
*   **Correlation IDs**: Pass a correlation ID through the function calls to trace a request across multiple services or function executions.
*   **Contextual Info**: Include relevant context in every log entry, such as the `userId`, `eventId`, or `documentPath` being processed.

#### 9. Incident Response & Remediation
**Reliability**:
*   **Circuit Breakers**: Implement client-side circuit breakers. If the app detects repeated failures (e.g., Firestore unavailable), it should switch to offline-only mode or degrade gracefully instead of retrying indefinitely.
*   **Kill Switch**: Use Remote Config to implement a "kill switch" for specific features or background jobs. If a Cloud Function is causing a loop or data corruption, it can be disabled instantly without a code deploy.
*   **Rollback Plan**: Have a clear rollback strategy for Cloud Functions (using `firebase deploy` to a previous version) and database schema changes (using backups).

#### 10. Environment Management
**Configuration**:
*   **Projects**: Maintain strictly separate Firebase projects for Development, Staging, and Production. Never test code against the production database.
*   **Aliases**: Use `firebase use <alias>` to switch between environments easily.
*   **Config Files**: Use `.env` files (e.g., `.env.production`, `.env.staging`) loaded at build time to inject environment-specific variables like API endpoints or feature flags.

#### 11. Secrets Management
**Security**:
*   **Google Cloud Secret Manager**: Store sensitive keys (e.g., SendGrid API key, Plaid Client Secret) in Google Cloud Secret Manager, not in environment variables or code.
*   **Access Control**: Grant the Cloud Function service account access only to the specific secrets it needs.
*   **Runtime Access**: Access secrets at runtime within the Cloud Function using the Firebase `defineSecret` parameter to safely mount them as environment variables.

#### 12. Chaos Engineering
**Resilience**:
*   **Fault Injection**: In the staging environment, intentionally inject faults (e.g., increased latency, dropped packets, function timeouts) to test if the "Circuit Breaker" and retry logic work as expected.
*   **Fire Drills**: Conduct periodic manual tests where a "database outage" is simulated (by changing security rules to deny all) to verify that the app handles the failure gracefully (e.g., showing cached data and an offline banner).

#### 13. Privacy & Compliance (GDPR/CCPA)
**Data Governance**:
*   **Export/Delete**: Implement Cloud Functions triggered by Firebase Auth events (`beforeUserDeleted` or custom callable) to automatically wipe all user data from Firestore collections (`cashflow_cycles`, `annual_summaries`) and Storage buckets upon account deletion.
*   **Data Export**: Provide a mechanism for users to download a full JSON or CSV export of their financial history, fulfilling the "Right to Portability".
*   **TTL (Time-To-Live)**: Use Firestore TTL policies to automatically delete temporary logs or debug data after a set period (e.g., 30 days) to minimize data liability.

#### 14. A/B Testing & Rollouts
**Feature Management**:
*   **Remote Config**: Use Firebase Remote Config with "Conditions" to target random percentiles of users (e.g., "5% User Rollout") for new features like "AI Receipt Scanning".
*   **Analytics Integration**: Link Remote Config with Google Analytics to compare engagement metrics (e.g., "Transactions Logged per Session") between the Control and Variant groups.
*   **Feature Flags**: Wrap new UI components in `FutureBuilder`s that listen to feature flag values, ensuring features can be turned off instantly without app updates if bugs are found.

#### 15. Data Retention & Archival
**Lifecycle Management**:
*   **Cold Storage**: For data older than 7 years (standard financial retention), automate a job to move Firestore documents to "Coldline" or "Archive" classes in Google Cloud Storage to save costs.
*   **Immutable Logs**: If audit trails are required (e.g., "who changed this transaction"), write these logs to an immutable append-only storage (like detailed Cloud Logging) rather than keeping them in the hot Firestore database.
*   **Snapshots**: Maintain daily backups of the Firestore database in Cloud Storage with a retention policy of 30 days for disaster recovery, separate from the long-term data archival strategy.

#### 16. Automating Data Portability
**Tools**:
*   **Cloud Functions**: Create a Callable Cloud Function that accepts a user request, queries all relevant collections (`cashflow_cycles`, `annual_summaries`), and streams the data to a temporary JSON file in Cloud Storage.
*   **Signed URLs**: Generate a short-lived Signed URL for the file in Cloud Storage and return it to the client, allowing the user to download their data securely without exposing public read access.

#### 17. Monitoring TTL Health
**Observability**:
*   **Metric Tracking**: Use Google Cloud Monitoring to track the metric `firestore.googleapis.com/ttl/deleted_count` to verify that deletions are occurring.
*   **Alerting**: Set up an alert if the deleted count drops to zero for an extended period (indicating a potential policy misconfiguration or stalled job).

#### 18. User Communication Strategy
**Transparency**:
*   **In-App Messaging**: Use Firebase In-App Messaging to display minimal, non-intrusive banners explaining new features when a user first encounters them (e.g., "New: Try our AI Receipt Scanner").
*   **Change Logs**: Maintain a visible "What's New" section in the app settings, populated dynamically from a remote JSON file or Remote Config, so users can see active experiments or rollouts impacting them.
*   **Beta Opt-In**: Provide a toggle in user settings to allow power users to explicitly opt-in to "Beta Features," overriding the random A/B test assignment.
