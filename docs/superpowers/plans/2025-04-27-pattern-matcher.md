# PatternMatcher & phone? Helper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement PatternMatcher wrapper class, Patterns module with phone? helper, and integrate into the DSL system.

**Architecture:** Add PatternMatcher class that wraps Regexp and responds to match/match?/~ for use with String#gsub. Add Patterns module with noam_phone? (aliased as phone?) that returns a PatternMatcher. Integrate into Config and Substitution to handle PatternMatcher objects natively.

**Tech Stack:** Ruby, RSpec

---

### Task 1: Create PatternMatcher Class

**Files:**
- Create: `lib/dsl/pattern_matcher.rb`

- [ ] **Step 1: Write PatternMatcher class**

```ruby
module Dsl
  class PatternMatcher
    def initialize(pattern)
      @pattern = pattern.is_a?(Regexp) ? pattern : Regexp.new(Regexp.escape(pattern.to_s))
    end

    def match(str)
      @pattern.match(str)
    end

    def match?(str)
      @pattern.match?(str)
    end

    def =~(str)
      @pattern =~ str
    end

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

- [ ] **Step 2: Verify file created**

Run: `cat lib/dsl/pattern_matcher.rb`
Expected: File contents match above

- [ ] **Step 3: Commit**

```bash
git add lib/dsl/pattern_matcher.rb
git commit -m "feat: add PatternMatcher wrapper class"
```

---

### Task 2: Create Patterns Module

**Files:**
- Create: `lib/dsl/patterns.rb`

- [ ] **Step 1: Write Patterns module**

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

- [ ] **Step 2: Verify file created**

Run: `cat lib/dsl/patterns.rb`
Expected: File contents match above

- [ ] **Step 3: Commit**

```bash
git add lib/dsl/patterns.rb
git commit -m "feat: add Patterns module with noam_phone? and phone? helpers"
```

---

### Task 3: Update DSL Requires

**Files:**
- Modify: `lib/dsl.rb`

- [ ] **Step 1: Add requires for new files**

```ruby
require_relative 'dsl/loader'
require_relative 'dsl/config'
require_relative 'dsl/substitution'
require_relative 'dsl/link_substitution'
require_relative 'dsl/pattern_matcher'
require_relative 'dsl/patterns'
```

- [ ] **Step 2: Modify lib/dsl.rb**

Replace the existing content with the updated requires.

- [ ] **Step 3: Verify change**

Run: `cat lib/dsl.rb`
Expected: Contains both new require_relative lines

- [ ] **Step 4: Commit**

```bash
git add lib/dsl.rb
git commit -m "chore: require new PatternMatcher and Patterns modules"
```

---

### Task 4: Include Patterns in Config

**Files:**
- Modify: `lib/dsl/config.rb`

- [ ] **Step 1: Add include statement**

Find the class definition at line 2 and add `include Dsl::Patterns`:

```ruby
module Dsl
  class Config
    include Dsl::Patterns
    attr_reader :config_file_path
    attr_reader :vault_root, :daily_log_finder, :gsubs, :prefixes, :entry_prefix, :tool_path
```

- [ ] **Step 2: Verify change**

Run: `grep -n "include Dsl::Patterns" lib/dsl/config.rb`
Expected: Output shows the include line

- [ ] **Step 3: Commit**

```bash
git add lib/dsl/config.rb
git commit -m "feat: include Patterns module in Config"
```

---

### Task 5: Handle PatternMatcher in Substitution

**Files:**
- Modify: `lib/dsl/substitution.rb`

- [ ] **Step 1: Modify build_gsub to handle PatternMatcher**

Change from:
```ruby
def self.build_gsub(search, replace)
  search = /#{Regexp.escape(search)}/ unless search.is_a?(Regexp)
  Substitution.new(search, replace)
end
```

To:
```ruby
def self.build_gsub(search, replace)
  unless search.is_a?(Regexp) || search.is_a?(PatternMatcher)
    search = /#{Regexp.escape(search)}/
  end
  Substitution.new(search, replace)
end
```

- [ ] **Step 2: Verify change**

Run: `grep -A2 "def self.build_gsub" lib/dsl/substitution.rb`
Expected: Shows the updated condition with PatternMatcher check

- [ ] **Step 3: Commit**

```bash
git add lib/dsl/substitution.rb
git commit -m "feat: support PatternMatcher objects in Substitution"
```

---

### Task 6: Write Tests for PatternMatcher

**Files:**
- Modify: `spec/dsl/config_spec.rb`

- [ ] **Step 1: Add PatternMatcher tests**

Add before the existing `context "add_prefix"` block:

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
  
  it "can be used with String#gsub" do
    pm = Dsl::PatternMatcher.new(/\d+/)
    result = "abc123".gsub(pm) { |m| "[#{m}]" }
    expect(result).to eq "abc[123]"
  end
end
```

- [ ] **Step 2: Run tests**

Run: `bundle exec rspec spec/dsl/config_spec.rb -e "PatternMatcher"`
Expected: All 3 tests PASS

- [ ] **Step 3: Commit**

```bash
git add spec/dsl/config_spec.rb
git commit -m "test: add PatternMatcher tests"
```

---

### Task 7: Write Tests for phone? Helper

**Files:**
- Modify: `spec/dsl/config_spec.rb`

- [ ] **Step 1: Add phone? tests**

Add after the PatternMatcher tests:

```ruby
context "phone? helper" do
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

- [ ] **Step 2: Run tests**

Run: `bundle exec rspec spec/dsl/config_spec.rb -e "phone? helper"`
Expected: All 6 tests PASS

- [ ] **Step 3: Commit**

```bash
git add spec/dsl/config_spec.rb
git commit -m "test: add phone? helper tests"
```

---

### Task 8: Run Full Test Suite

**Files:**
- None (verification step)

- [ ] **Step 1: Run all tests**

Run: `bundle exec rspec`
Expected: All tests pass, including new ones

- [ ] **Step 2: Verify no regressions**

Run: `bundle exec rspec spec/dsl/`
Expected: All DSL tests pass

Run: `bundle exec rspec spec/parser/`
Expected: All parser tests pass

- [ ] **Step 3: Commit if all pass**

If all tests pass, commit any remaining changes:
```bash
git add -A
git commit -m "test: verify all tests pass with PatternMatcher integration" || echo "Nothing to commit"
```

---

### Task 9: Integration Test with Real Config

**Files:**
- None (manual verification)

- [ ] **Step 1: Test with real config**

Run:
```bash
ruby -e '
require_relative "lib/dsl"

config = Dsl::Config.new("/Users/andrew.burns/.config/dlog/vault.rb")
config.instance_eval(File.read("/Users/andrew.burns/.config/dlog/vault.rb"), "/Users/andrew.burns/.config/dlog/vault.rb", 1)

result = config.process_entry_line("CALL J. Doe 123-456-7890")
puts "Result: #{result}"
'
```

Expected: `☎ J. Doe 📞 [123-456-7890](tel:1234567890)` (no nested links)

- [ ] **Step 2: Test with parentheses format**

Run the same script with input `"CALL J. Doe (123) 456-7890"`
Expected: Properly formatted phone link

- [ ] **Step 3: Test with dots format**

Run with input `"CALL J. Doe 123.456.7890"`
Expected: Properly formatted phone link

---

## Self-Review

**1. Spec coverage:**
- ✅ PatternMatcher class created
- ✅ Patterns module with noam_phone? and phone? alias
- ✅ Config includes Patterns module
- ✅ Substitution handles PatternMatcher
- ✅ Backward compatibility maintained (string and regex patterns still work)
- ✅ Tests for PatternMatcher behavior
- ✅ Tests for phone? helper matching all formats
- ✅ Full test suite verification
- ✅ Integration test with real config

**2. Placeholder scan:**
- ✅ No TBDs or TODOs
- ✅ All code shown in full
- ✅ Exact file paths specified
- ✅ Test commands included

**3. Type consistency:**
- ✅ PatternMatcher used consistently
- ✅ phone? alias refers to noam_phone? everywhere
- ✅ PatternMatcher responds to match/match?/~ for gsub compatibility

---

**Plan complete!** Ready for execution.
