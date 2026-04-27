# PatternMatcher & noam_phone? Helper Design

## Overview

Replace multiple overlapping phone number regexes in user configuration with a single `noam_phone?` helper that matches North American phone numbers in common formats. Introduce a `PatternMatcher` wrapper class to allow regex-like objects to work seamlessly with `add_gsub`.

## Motivation

The current phone number configuration uses two regexes (`/\d{3}-\d{3}-\d{4}/` and `/\d{3}-\d{4}/`) that run sequentially, causing the 7-digit regex to incorrectly match inside the already-formatted 10-digit markdown link output. This produces nested markdown like:

```
📞 [123-📞 [456-7890](tel:4567890)](tel:1234567890)
```

## Goals

1. Eliminate overlapping pattern issues by using a single comprehensive phone regex
2. Simplify user configuration - one `add_gsub` block instead of multiple
3. Support common North American phone formats: `123-456-7890`, `(123) 456-7890`, `123.456.7890`, `1234567890`
4. Maintain full backward compatibility with existing `add_gsub` string and regex patterns
5. Provide a reusable pattern for future specialized matchers

## Non-Goals

- International phone number support (E.164)
- Country code handling (`+1`, `1-` prefixes) - can be added later
- Full regex API compatibility - only methods actually used by the codebase

## Design

### 1. PatternMatcher Class

Create `lib/dsl/pattern_matcher.rb`:

```ruby
module Dsl
  class PatternMatcher
    def initialize(pattern)
      @pattern = pattern.is_a?(Regexp) ? pattern : Regexp.new(Regexp.escape(pattern.to_s))
    end

    # Interface for String#gsub
    def match(str)
      @pattern.match(str)
    end

    def match?(str)
      @pattern.match?(str)
    end

    def =~(str)
      @pattern =~ str
    end

    # Hash key support
    def ==(other)
      other.is_a?(PatternMatcher) && @pattern == other.instance_variable_get(:@pattern)
    end
    alias eql? ==

    def hash
      @pattern.hash
    end

    def inspect
      "PatternMatcher(#{@pattern.inspect})"
    end
  end
end
```

### 2. Patterns Module

Create `lib/dsl/patterns.rb`:

```ruby
module Dsl
  module Patterns
    def noam_phone?
      @noam_phone ||= PatternMatcher.new(
        /\b(?:\d{3}-\d{3}-\d{4}|\(\d{3}\)\s*\d{3}-\d{4}|\d{3}\.\d{3}\.\d{4}|\d{10})\b/x
      )
    end
    alias phone? noam_phone?
  end
end
```

### 3. Core Integration Changes

**In `lib/dsl.rb`:**

Add requires for new files:

```ruby
require_relative 'dsl/loader'
require_relative 'dsl/config'
require_relative 'dsl/substitution'
require_relative 'dsl/link_substitution'
require_relative 'dsl/pattern_matcher'
require_relative 'dsl/patterns'
```

**In `lib/dsl/config.rb`:**

Include the Patterns module:

```ruby
module Dsl
  class Config
    include Dsl::Patterns
    # ... rest of class
    
    def add_gsub(search, replace=nil, &block)
      # No auto-wrap! Regexp objects pass through unchanged
      assert_gsub_not_present!(search)
      
      if block_given?
        raise "You can not specify a replace value AND a block" unless replace.nil?
        actual_params = block.parameters
        raise "Invalid gsub block signature, it should just be `|entry, match|` Got: #{actual_params}" unless actual_params.count == 2
        
        replace = block
      end
      
      @gsubs[search] = Substitution.build_gsub(search, replace)
    end
    
    # ... rest of class
  end
end
```

**In `lib/dsl/substitution.rb`:**

Handle PatternMatcher objects directly:

```ruby
def self.build_gsub(search, replace)
  unless search.is_a?(Regexp) || search.is_a?(PatternMatcher)
    search = /#{Regexp.escape(search)}/
  end
  Substitution.new(search, replace)
end
```

The `run` method already uses `entry.gsub(search_rx)` which works with PatternMatcher since it responds to `match`.

### 4. User Configuration

**Before (current):**

```ruby
[
  /\d{3}-\d{3}-\d{4}/,
  /\d{3}-\d{4}/,
].each do |phone_rx|
  add_gsub phone_rx do |entry, match|
    set_tool_path '~/.raycast-cmds/markdown-tool.sh'
    next unless has_tool?
    run_tool :with_args, match
    if tool_error?
      next "❌ MDT-ERROR: #{entry}"
    end
    tool_output
  end
end
```

**After:**

```ruby
add_gsub phone? do |entry, match|
  set_tool_path '~/.raycast-cmds/markdown-tool.sh'
  next unless has_tool?
  run_tool :with_args, match
  if tool_error?
    next "❌ MDT-ERROR: #{entry}"
  end
  tool_output
end
```

### 5. Backward Compatibility

The changes must not affect existing configurations:

- `add_gsub 'STRING', 'replace'` → Works exactly as before (string converted to regex in build_gsub)
- `add_gsub /regex/, 'replace'` → Works exactly as before (regex passes through)
- `add_gsub /regex/ { |entry, match| ... }` → Works exactly as before
- `add_link_gsub 'TEXT', ...` → Uses separate code path, unaffected

### 6. Test Coverage

New tests to add to `spec/dsl/config_spec.rb`:

```ruby
context "PatternMatcher" do
  it "wraps regex patterns" do
    pm = Dsl::PatternMatcher.new(/\d+/)
    expect(pm).to be_a(Dsl::PatternMatcher)
    expect(pm.match?("abc123")).to be true
    expect(pm.match?("abc")).to be false
  end
  
  it "responds to =~" do
    pm = Dsl::PatternMatcher.new(/\d+/)
    expect(pm =~ "abc123").to eq(3)
    expect(pm =~ "abc").to be_nil
  end
end

context "noam_phone? helper" do
  let(:cfg) do
    loader.build do |cfg|
      cfg.add_gsub cfg.phone? do |entry, match|
        "[#{match}]"
      end
    end
  end
  
  it "matches 10-digit with dashes" do
    expect(cfg.process_entry_text("Call 123-456-7890"))
      .to eq "Call [123-456-7890]"
  end
  
  it "matches with parentheses" do
    expect(cfg.process_entry_text("Call (123) 456-7890"))
      .to eq "Call [(123) 456-7890]"
  end
  
  it "matches with dots" do
    expect(cfg.process_entry_text("Call 123.456.7890"))
      .to eq "Call [123.456.7890]"
  end
  
  it "matches plain digits" do
    expect(cfg.process_entry_text("Call 1234567890"))
      .to eq "Call [1234567890]"
  end
  
  it "does not match 7-digit numbers" do
    expect(cfg.process_entry_text("Call 456-7890"))
      .to eq "Call 456-7890"
  end
  
  it "handles multiple phone numbers" do
    expect(cfg.process_entry_text("Call 123-456-7890 or 987-654-3210"))
      .to eq "Call [123-456-7890] or [987-654-3210]"
  end
end
```

## Files to Create/Modify

### New Files
- `lib/dsl/pattern_matcher.rb` - PatternMatcher class
- `lib/dsl/patterns.rb` - Patterns module with noam_phone? and phone?

### Modified Files
- `lib/dsl.rb` - Require new pattern_matcher and patterns files
- `lib/dsl/config.rb` - Include Dsl::Patterns module
- `lib/dsl/substitution.rb` - Handle PatternMatcher in build_gsub
- `spec/dsl/config_spec.rb` - Add tests for PatternMatcher and phone?

## Future Extensibility

The `PatternMatcher` pattern enables future helpers like:

```ruby
# Email matcher
add_gsub email_matcher? do |entry, match|
  "[#{match}](mailto:#{match})"
end

# URL matcher  
add_gsub url_matcher? do |entry, match|
  "[#{match}](#{match})"
end
```

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Breaking existing configs | Comprehensive test coverage, backward compatibility design |
| Performance impact of PatternMatcher | Minimal - only adds one method call indirection |
| 7-digit numbers no longer matched | By design - NANP standard is 10-digit; users can add separate pattern if needed |

## Success Criteria

- [ ] All existing tests pass without modification
- [ ] New PatternMatcher tests pass
- [ ] New phone? tests pass
- [ ] Phone numbers in all 4 formats are correctly matched
- [ ] No nested markdown link bugs occur
- [ ] User configuration is simplified to single `add_gsub` block
