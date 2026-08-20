# dlog contributor guide

## Start here

`dlog` is a local command-line tool that appends formatted, timestamped text to an existing daily Markdown document. Its current implementation uses a small configuration DSL, a document normalizer, an optional fixup watcher, and optional helper integrations.

The behavioral contract is maintained in these documents:

- [Specification](docs/specification.md): normative behavior, interfaces, compatibility details, and deployment assumptions.
- [Conformance suite](docs/conformance.md): executable-style acceptance scenarios and edge cases.

Read the relevant specification section before changing behavior. The specification is deliberately implementation-language-neutral; keep it that way.

## Source map

| Area | Primary locations | Responsibility |
| --- | --- | --- |
| CLI and application flow | `bin/dlog`, `dlog.rb`, `lib/init.rb` | Read input, locate configuration, process one entry, append it, and print the rendered entry. |
| Configuration and substitutions | `lib/dsl/` | Load configuration, register ordered substitutions, process timestamp overrides, invoke callbacks and external tools. |
| Daily-document access | `lib/vault.rb` | Validate the vault and resolve today's existing document. |
| Markdown writer | `lib/parser/markdown_log.rb` | Locate the first `# Log` section, filter/normalize its entries, sort/deduplicate, and rewrite the document. |
| Fixup watcher | `bin/dlog-fixup` | One-shot or polling normalization with debounce, configuration caching, and watchdog behavior. |
| Optional integrations | `tools/spotify-song.rb`, `tools/docker-entrypoint.sh`, `tools/raycast-command.sh`, `tools/bin_wrapper.sh` | Current-track lookup, container entrypoint, launcher, and local runtime wrapper. |
| Tests | `spec/dlog_spec.rb`, `spec/dsl/config_spec.rb`, `spec/parser/markdown_log_spec.rb` | Entry processing, DSL, and document-writer coverage. |

## Behavioral invariants

Preserve these unless the requested change explicitly changes the product contract:

- Configuration lookup prioritizes `DLOG_CONFIG`, then `~/.config/dlog/vault.rb`, then `./vault_config.rb`.
- A daily document must already exist and contain a first exact `# Log` heading; the application does not create either.
- Entry processing order is timestamp-prefix extraction, ordered prefix substitutions, ordered global/link substitutions, trim, then optional entry-prefix formatting.
- The Markdown writer retains only the standard timestamped-entry shape in the log section. It sorts lowercase whole lines, removes exact duplicates, and rewrites the document in place.
- `dlog-fixup` is one-shot by default. `--watch` enables monitoring; without an explicit `--delay`, watch mode still uses a zero-second delay.

The specification contains the exact grammar, normalization algorithm, digest behavior, serialization details, and external-tool semantics. Do not restate those implementation details elsewhere when a link to the specification is sufficient.

## Keeping the specification current

Treat a behavioral change as incomplete until the relevant specification and conformance scenarios change in the same patch.

| Change type | Required documentation update |
| --- | --- |
| CLI input, output, errors, exit status, config discovery, or date selection | `docs/specification.md` command/configuration sections and affected `CFG-*` or `CLI-*` cases. |
| Substitution, timestamp, link, callback, or external-tool behavior | Specification configuration/entry-processing sections and affected `ENT-*`, `TIME-*`, `TOOL-*`, or phone-helper cases. |
| Daily-document parsing, filtering, sorting, deduplication, digesting, or serialization | Specification daily-document section and affected `DLOG-*` cases. |
| Watcher options, polling/debounce, configuration reload, or watchdog behavior | Specification watcher section and affected `FIX-*` cases. |
| Spotify, launcher, wrapper, container, mount, or environment behavior | Specification integration/deployment section and affected `SPOT-*` case or a new conformance case. |

For every changed observable contract:

1. Update the implementation and its focused automated test.
2. Update the specification with the new normative rule, including error and edge behavior where relevant.
3. Add or revise a stable, deterministic conformance scenario that would fail under the previous behavior.
4. Remove superseded wording and scenarios so the documents have one source of truth.

When a source change reveals behavior that is not documented, add it to the specification before treating the work as complete. If a proposed change intentionally differs from the specification, change the specification and conformance suite in the same change set rather than leaving an undocumented divergence.

## Validation

Use the narrowest test that covers the changed contract, then run the full suite for cross-cutting work:

```bash
bundle exec rspec spec/dlog_spec.rb
bundle exec rspec spec/dsl/config_spec.rb
bundle exec rspec spec/parser/markdown_log_spec.rb
bundle exec rspec
```

The current baseline has one known parser-test inconsistency: the end-of-file test expects a terminal newline, but the writer strips the final newline. `DLOG-08` in the conformance suite records the running behavior. If changing the parser or this test, reconcile the implementation, test, specification, and conformance case together; do not report the full suite as green until they agree.

For a change involving a real vault or external utility, also smoke-test the affected command against an isolated temporary document or mocked boundary. Do not use a personal vault, clipboard, Spotify credentials, or a long-running watcher as a default test fixture.

## Change discipline

- Keep configuration loading and dynamic callbacks as explicit trust boundaries. External-tool calls execute a configured local executable and may be shell-sensitive.
- Use temporary files for document-writer tests. Assert final document bytes for formatting-sensitive behavior, especially terminal-newline and section-spacing changes.
- Preserve user-authored configuration and daily documents during development. Test destructive normalization only in isolated fixtures.
- Keep README examples and operational instructions aligned when a user-facing command or installation/deployment contract changes.
