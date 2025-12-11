# About INDEX

INDEX is a an archival research and analysis tool that lets you systematically capture and organize primary source material for long term historical projects.



# Build Plan

### Phase One
Build an archival research app where authenticated users manage long term projects and collect primary source material. Each user maintains private projects that hold uploaded artifacts such as images, videos, PDFs, and documents stored through Active Storage on R2 with basic metadata. Provide a minimal interface that lists a user’s projects, lists a project’s files, and opens any file with a simple inline preview and download link. The focus is stability, clarity, and a dependable structure for organizing raw materials.

### Phase Two
Introduce entities that represent subjects within a project, including buildings, people, organizations, artworks, or events. Each entity has its own page, metadata, and description. Users can associate any uploaded artifact with any number of entities, allowing a single file to appear in dozens of entity contexts. Visiting an entity page should show all related uploads in a clean, filterable list. This phase creates a lightweight relational layer that maps the relationships between source material and the subjects they document.

### Phase Three
Add project level notes with Obsidian style inline linking so researchers can reference entities, uploads, and other notes directly in the text. Notes remain simple markdown or plain text, but links like [[Entity]] or ID based forms resolve to real objects in the project. Each entity and upload gains a backlinks section that shows all notes mentioning it, creating a navigable research graph. This phase gives users a flexible way to develop ideas, track insights, and build narrative or analytical threads on top of their collected materials.
