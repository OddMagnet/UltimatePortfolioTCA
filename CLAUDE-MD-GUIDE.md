# Guide: Creating and Improving CLAUDE.md Files

> A reusable guide for creating CLAUDE.md files for new projects or bringing existing ones up to standard. Distilled from a research and verification process covering signal-to-noise ratio, staleness risk, content trimming, memory deduplication, and missing aspects.

---

## Guiding Principles

Apply these to every line you write or review:

1. **The mistake test**: "Would removing this cause Claude to make a specific, concrete mistake?" If not, it doesn't belong in CLAUDE.md.
2. **Prescriptive over descriptive**: State rules ("do this, not that"), not documentation ("here's how X works"). Claude can read code to learn how things work.
3. **Convention over configuration**: State the rule, not the rationale. Move "why" explanations to code comments, `docs/`. Use `.claude/rules/` for rules that apply to specific parts/files of the project.
4. **Expandable by design**: Each section follows a consistent format so adding new rules is trivial and doesn't require restructuring.
5. **No duplication**: CLAUDE.md doesn't repeat what's in memory, skills, code comments, or `.claude/rules/` files.
6. **Discovery rules over enumerations**: Instead of listing all instances ("types X, Y, Z use this pattern"), state the pattern and where to find examples ("search for `@Selection struct`"). Lists go stale; patterns don't.

---

## The 5 Aspects to Evaluate

When creating or reviewing a CLAUDE.md, evaluate it against these 5 aspects:

### 1. Signal-to-Noise Ratio

Every line should be a prescriptive instruction that prevents a mistake. Target ~90%+ prescriptive content (excluding structural lines like headers).

**Common noise patterns to eliminate:**
- Descriptions of what exists ("The app uses X for Y") — Claude can read the code
- Implementation flow narratives ("When the user taps X, the reducer does Y, which triggers Z")
- API catalogs listing every component, model, or helper
- Code snippets that duplicate what's in source files
- Rationale paragraphs explaining *why* decisions were made

**What to keep:**
- "Do X, not Y" rules
- Known pitfalls and gotchas that aren't obvious from code
- Build/test commands (not derivable)
- Conventions that differ from defaults or common expectations
- Workarounds for bugs (with removal conditions)

### 2. Staleness Risk

Content that goes stale silently is worse than missing content — it actively misleads.

**High-risk patterns to avoid:**
- **Exhaustive enumerations**: Listing all types, actions, keys, entry points, etc. Each list becomes incomplete the moment a new item is added to code.
- **Specific counts**: "Three entry points", "four features", "five models" — use "multiple" or "all" instead.
- **Version numbers**: Duplicating versions from package files. They drift with every update.
- **Code snippets**: Copied code diverges from the source. Use file pointers instead ("see `FileName.swift` for the pattern").
- **Implementation details**: Exact action names, specific type signatures, parameter values.

**Mitigation strategies:**
- Replace enumerations with **discovery rules**: "search for `@Selection struct`" instead of listing all selection types.
- Replace code snippets with **file pointers**: "see `BaseTestSuite` in `TestFile.swift`".
- Mark **workarounds with explicit removal conditions**: "WORKAROUND for X bug since version Y. REMOVAL: test after each update of Z; revert when fixed."
- Use **`.claude/rules/` files** for detailed reference material (scoped to relevant paths, allowed to be more specific since they're co-located with the code they describe).

### 3. What to Keep vs. Trim

Apply this decision framework to every section:

| Content Type | Action | Example |
|---|---|---|
| "Do X, not Y" rules | **KEEP** in CLAUDE.md | "Use delegate actions, not `@Dependency(\.dismiss)`" |
| Known pitfalls | **KEEP** in CLAUDE.md | "Do NOT set `modified` from Swift code" |
| Build/test commands | **KEEP** in CLAUDE.md | `xcodebuild` invocations, MCP server notes |
| Workflow checklists | **KEEP** in CLAUDE.md | "New Feature" steps, "Pre-Commit Review" steps |
| Conventions differing from defaults | **KEEP** in CLAUDE.md | "nonisolated default — mark @MainActor explicitly" |
| Architecture descriptions | **MOVE** to `.claude/rules/` | Navigation flow, state management patterns |
| Component/API catalogs | **MOVE** to `.claude/rules/` | List of shared UI components, model descriptions |
| Implementation details | **MOVE** to `.claude/rules/` | Trigger specifics, query helper catalog |
| Things obvious from code | **REMOVE** entirely | "All features use ViewAction protocol" (visible in every file) |
| Things covered by skills/tools | **REMOVE** entirely | Patterns that installed skills already teach |

### 4. Overlap with Memory

CLAUDE.md and auto-memory serve different purposes. Clear ownership prevents duplication:

| Source | Owns | Litmus Test |
|---|---|---|
| **CLAUDE.md** | Team-wide rules checked into git | "Would a new contributor make mistakes without this?" |
| **Memory** | Personal preferences, debugging lessons, session-learned context | "Is this something Claude learned from working with *me*?" |
| **`.claude/rules/`** | Path-scoped reference material | "Does Claude need this every session, or only when working on specific files?" |
| **Skills** | Library API guidance and best practices | "Does a skill already cover this pattern?" |

**Before adding to CLAUDE.md, check**: Is it already in an installed skill? Is it a personal preference that belongs in memory? Is it detailed reference material that should be in `.claude/rules/`?

**Before adding to memory, check**: Is it a team rule that should be in CLAUDE.md? Is it something that can be derived from code?

### 5. Missing Aspects

Common sections that high-quality CLAUDE.md files include:

**Essential (include in every project):**
- Project overview (1-2 lines: what it is, what stack, where the project file is)
- Build & test commands
- Coding standards (prescriptive rules only)
- Restrictions (NEVER/ALWAYS binary rules)

**Recommended:**
- Naming conventions (table format)
- Error handling patterns
- File naming/placement conventions
- Workflows (named checklists for common tasks)
- Skills invocation rules (if skills are installed)
- Testing conventions
- Commit conventions
- Debugging directives

**Nice to have:**
- Decision autonomy guidelines (when to ask vs. proceed)
- Meta-workflow for expanding CLAUDE.md itself
- Preview conventions
- Concurrency rules (if non-default isolation)

---

## Recommended Structure

Sections ordered by frequency of use. Every line must pass the mistake test.

```
# CLAUDE.md

## Project Overview
One-sentence summary: what, stack, project file location.

## Build & Test Commands
Exact shell commands. MCP server notes if applicable.

## Coding Standards
Grouped subsections of prescriptive rules:
- Architecture rules
- Naming conventions (table format)
- Action naming conventions
- Database/persistence rules (pitfalls only)
- Language/compiler settings (non-obvious ones only)
- Localization/accessibility rules
- Error handling patterns
- File placement conventions

## Restrictions
NEVER:
- Binary list of things to never do
ALWAYS:
- Binary list of things to always do

## Skills (if applicable)
Behavioral rules for skill invocation. Individual skills handle their own cross-references.

## Testing
Conventions, base suite pattern (file pointer, not code), key rules.

## Commits & Code Quality
Commit message format, linting/formatting tools, pre-commit hooks.

## Debugging
Behavioral directives for how to approach problems.

## Workflows
Named checklists for common task types:
- New Feature
- Bug Fix / Schema Change / etc. (project-specific)
- Pre-Commit Review
- Expanding CLAUDE.md (meta-workflow)
```

---

## Using `.claude/rules/` Files

For content that fails the "every session" test but is valuable when working in specific areas:

```yaml
---
paths: ["src/features/**"]
---

# Feature Architecture Reference
Detailed patterns, navigation flows, state management descriptions...
```

**Guidelines:**
- Use `paths` frontmatter to scope to relevant directories
- These files are allowed to be descriptive (reference material)
- Prescriptive rules should be in CLAUDE.md, not here
- Keep these co-located with the code they describe (helps with maintenance)
- Apply the same staleness rules (discovery rules over enumerations)

---

## Process for New Projects

1. **Start minimal.** Write only the essential sections (overview, build commands, 3-5 key rules). You can always add more.
2. **Add rules as mistakes happen.** When Claude makes a mistake that a rule would have prevented, add that rule. This naturally builds a high-signal file.
3. **Review after 5-10 sessions.** Check what's accumulated. Apply the 5 aspects. Trim noise, promote patterns, extract reference material to `.claude/rules/`.
4. **Check installed skills.** Before adding a rule, verify it's not already covered by a skill. Don't duplicate skill content.

## Process for Improving Existing CLAUDE.md Files

1. **Measure the baseline.** Read every line and classify as prescriptive vs. descriptive. Calculate the signal-to-noise ratio.
2. **Apply the mistake test.** For each line: "Would removing this cause Claude to make a specific mistake?" Mark lines that fail.
3. **Check for staleness.** Look for version numbers, exhaustive enumerations, code snippets, specific counts. Verify claims against the actual codebase.
4. **Check for overlap.** Compare against memory files and installed skills. Remove duplicates.
5. **Identify gaps.** Compare against the recommended structure. Add missing sections that would prevent real mistakes.
6. **Extract reference material.** Move descriptive content to `.claude/rules/` files with appropriate path scoping.
7. **Clean up memory.** Remove memory items that are now covered by the updated CLAUDE.md.
8. **Verify.** Re-read the final result against all 5 aspects. Every line should pass the mistake test.

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Fix |
|---|---|---|
| Architecture documentation in CLAUDE.md | Goes stale, Claude can read code | Move to `.claude/rules/` or remove |
| Listing every model/component/helper | Goes stale when items are added | Use discovery rules or remove |
| Code snippets copied from source | Diverges from actual code | Use file pointers |
| Rationale paragraphs ("we chose X because Y") | Noise — Claude needs the rule, not the history | State the rule; put rationale in code comments |
| Version numbers duplicated from package files | Already stale by the time you commit | Reference the package file |
| "Here's how feature X works" narratives | Claude can read the implementation | Remove or move to `.claude/rules/` |
| Duplicating content from installed skills | Wasted space, risks contradicting the skill | Check skills first, remove duplicates |
| Personal preferences in CLAUDE.md | Belongs in memory, not team rules | Move to memory |
| Rules without the "not" side | "Use delegate actions" is weaker than "Use delegate actions, not dismiss" | State what to do AND what to avoid |

---

## Checklist: Is Your CLAUDE.md Ready?

- [ ] Every line passes the mistake test
- [ ] No descriptive content that Claude could derive from reading code
- [ ] No exhaustive enumerations — using discovery rules instead
- [ ] No version numbers duplicated from package/project files
- [ ] No code snippets — using file pointers instead
- [ ] Workarounds have explicit removal conditions
- [ ] No overlap with installed skills
- [ ] No overlap with memory
- [ ] NEVER/ALWAYS restrictions section exists
- [ ] Naming conventions in table format
- [ ] Workflows for common task types
- [ ] `.claude/rules/` files for detailed reference material (with path scoping)
- [ ] Build & test commands present
- [ ] Error handling patterns documented
- [ ] File placement conventions documented
