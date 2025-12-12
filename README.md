# About INDEX

INDEX is a an archival research and analysis tool that lets you systematically capture and organize primary source material for long term historical projects.



# Build Plan

### Phase One
Build an archival research app where authenticated users manage long term projects and collect primary source material. Each user maintains private projects that hold uploaded artifacts such as images, videos, PDFs, and documents stored through Active Storage on R2 with basic metadata. Provide a minimal interface that lists a user’s projects, lists a project’s files, and opens any file with a simple inline preview and download link. The focus is stability, clarity, and a dependable structure for organizing raw materials.

### Phase Two
Introduce entities that represent subjects within a project, including buildings, people, organizations, artworks, or events. Each entity has its own page, metadata, and description. Users can associate any uploaded artifact with any number of entities, allowing a single file to appear in dozens of entity contexts. Visiting an entity page should show all related uploads in a clean, filterable list. This phase creates a lightweight relational layer that maps the relationships between source material and the subjects they document.

### Phase Three
Add project level notes with Obsidian style inline linking so researchers can reference entities, uploads, and other notes directly in the text. Notes remain simple markdown or plain text, but links like [[Entity]] or ID based forms resolve to real objects in the project. Each entity and upload gains a backlinks section that shows all notes mentioning it, creating a navigable research graph. This phase gives users a flexible way to develop ideas, track insights, and build narrative or analytical threads on top of their collected materials.


# Image enhancement pipeline (Topaz-ready)

## Overview
- Any upload can spawn derived versions (e.g., Topaz upscales/restorations) while the original stays untouched.
- Derived uploads are regular uploads stored in Active Storage; each records a `parent_upload_id` back to its source plus `processing_metadata` describing the run (tool, settings, timestamps, status, errors, provider job ids, etc.).
- Entity/note relationships stay attached to the source upload; derived versions are meant as an enhancement layer, browsable from the source upload’s page.

## Data model
- `uploads.parent_upload_id` (self-referential FK) links generated versions to their source upload.
- `uploads.processing_metadata` (jsonb, default `{}`) stores:
  - `tool`: provider name (e.g., `"topaz"`).
  - `settings`: user-selected or preset options sent to the provider.
  - `status`: `queued | running | succeeded | failed`.
  - `run_at`: timestamp when the provider run started.
  - `error`: message/details on failure.
  - `provider_job_id` / `raw_response`: optional provider-specific info.
- Associations:
  - Upload `has_many :derived_uploads, foreign_key: :parent_upload_id`.
  - Upload `belongs_to :parent_upload, optional: true`.

## Flow (intended)
1) User visits an image upload page and clicks “Enhance”.
2) UI posts `provider` (currently Topaz) + `settings` to an enhancement endpoint.
3) Controller enqueues `ImageEnhancementJob` with source upload id, provider, and settings.
4) Job resolves the provider class (registry like `{ topaz: TopazEnhancer }`) and calls it.
5) Provider:
   - Generates a signed URL for the source file.
   - Calls provider API (Topaz) with settings and URL.
   - Polls or waits for completion.
   - Downloads the enhanced file to memory or temp file.
   - Creates a new Upload in the same project/user with `parent_upload_id` set and attaches the enhanced file.
   - Writes `processing_metadata` (tool, settings, status, run_at, any provider ids, errors).
6) UI surfaces derived uploads under the source upload, showing status/metadata; originals remain the canonical record.

## Background job & queue
- Job name (proposed): `ImageEnhancementJob`.
- Uses Solid Queue (already in Gemfile) to run asynchronously.
- Retries transient failures; marks status in `processing_metadata`.
- Configurable guardrails:
  - Maximum concurrent jobs per user/project (env-driven).
  - File type/size checks before enqueue.
  - Feature flag to disable enhancement if credentials are absent.

## Provider abstraction
- Light interface/contract (duck type): `call(source_upload, settings) -> Result (file_io, metadata)`.
- Registry hash to map provider symbols to classes; adds extensibility for future providers without changing job wiring.
- Metadata shape is provider-agnostic (tool, settings, status, error), with room for provider-specific fields.

## Configuration
- ENV keys (proposed):
  - `TOPAZ_API_URL`
  - `TOPAZ_API_KEY`
  - `IMAGE_ENHANCEMENT_ENABLED` (boolean to hide/show UI)
  - `IMAGE_ENHANCEMENT_MAX_CONCURRENT` (optional guardrail)
- No client gem required; use simple REST via `Net::HTTP` or `Faraday` (if added later).

## UI notes
- Source upload page: “Enhanced versions” section lists derived uploads (thumb + metadata + download).
- Action button: “Enhance with Topaz” (provider dropdown for future extensibility).
- Keep derived versions off the main project upload list; they are discoverable from the source upload.

## Testing
- Model: parent/derived associations; metadata defaults.
- Service: provider adapter happy-path, error, timeout (stub HTTP).
- Job: enqueues, updates status, creates derived upload on success, handles provider errors gracefully.
