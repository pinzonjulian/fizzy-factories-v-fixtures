# Migrating from Rails Fixtures to Oaken: Learnings & Edge Cases

This document captures lessons learned while migrating the Fizzy test suite from Rails fixtures to Oaken seed-based test data.

## Key Differences from Fixtures

### 1. Callbacks Run During Seeding

Unlike fixtures which bypass ActiveRecord callbacks, Oaken seeds run through normal model lifecycle. This means:

- **after_create callbacks execute** - Records created via callbacks (entropy, join_codes, system comments) are automatically generated
- **Validations run** - Invalid data will raise errors
- **Associations are created** - `has_one` auto-creation, `all_access` board grants, etc.

**Example:** Creating an Account automatically creates its `entropy` and `join_code` via callbacks:
```ruby
# No need to manually create these - callbacks handle it
account = accounts.create :_37s, name: "37signals"
# account.entropy and account.join_code already exist

# Label them for test access instead of creating them
entropies.label _37s_account: account.entropy
account_join_codes.label _37s: account.join_code
```

### 2. Current Context Must Be Set

Many callbacks depend on `Current.account` and `Current.user`. Set these before creating records that need them:

```ruby
account = accounts.create :_37s, name: "37signals"
Current.account = account

# Set Current.user before creating cards (needed for event tracking)
Current.user = david
cards.create :logo, account: account, board: writebook, creator: david, ...
```

### 3. Event Callbacks Create System Comments

When events like `card_assigned` are created, the `SystemCommenter` callback automatically creates system comments. Don't manually seed comments that would be duplicated:

```ruby
# DON'T do this - events will create these automatically:
# comments.create :logo_1, card: logo, creator: system_user, body: "David assigned..."

# DO create only human-authored comments:
comments.create :logo_agreement_jz, card: logo, creator: jz
```

---

## Oaken-Specific Patterns

### Object Identity: Use Local Variables When Modifying

Each call to `users.david` returns a **different object instance** (same `id`, different `object_id`). This matters when modifying objects:

```ruby
# ❌ WRONG - attachment made on one instance, assertion on another
users.david.avatar.attach(io: file, filename: "avatar.jpg")
assert users.david.avatar.attached?  # May fail!

# ✅ CORRECT - same instance throughout
user = users.david
user.avatar.attach(io: file, filename: "avatar.jpg")
assert user.avatar.attached?
```

**Rule of thumb:** If you **modify** an Oaken record and then **assert on that modification**, use a local variable. Reading pre-seeded data directly is fine.

### Naming: Numeric Prefixes Need Underscore

Ruby identifiers can't start with numbers. Use underscore prefix:

```ruby
# accounts("37s") in fixtures becomes:
accounts._37s
```

### JSON Columns: Don't Double-Encode

For columns with `store_accessor` or JSON type, pass hashes directly:

```ruby
# ❌ WRONG - double-encodes the JSON
events.create :assignment, particulars: { assignee_ids: [user.id] }.to_json

# ✅ CORRECT - Rails handles serialization
events.create :assignment, particulars: { assignee_ids: [user.id] }

# For store_accessor fields, use the accessors directly:
filters.create :my_filter, indexed_by: "all", sorted_by: "newest"
```

### Labeling Auto-Created Records

When callbacks create associated records, use `label` to make them accessible in tests:

```ruby
account = accounts.create :_37s, name: "37signals"

# The entropy was auto-created by callback, label it for test access
entropies.label _37s_account: account.entropy
```

### Join Tables: Use Associations, Not Raw SQL

```ruby
# ❌ Fragile - raw SQL
ActiveRecord::Base.connection.execute(
  "INSERT INTO filters_tags (filter_id, tag_id) VALUES ('#{filter.id}', '#{tag.id}')"
)

# ✅ Better - use associations
filter.tags << tag
filter.assignees << user
```

### Accessors vs Local Variables: Cached Association Gotcha

When a model has `after_create` callbacks that create associated records (like `has_one :settings`), there's a subtle but critical difference between using local variables and Oaken accessors in seeds.

**The problem:** When you create a record with a local variable, Rails caches the callback-created association on that object. If you later create a "replacement" record using `user_settings.create(user: local_var, ...)`, Rails updates the cached association to point to the new record. But Oaken accessors (`users.david`) fetch a **fresh instance** from the database each time—with no cached association. When `users.david.settings` is called, it queries the DB and returns the **first record by ID** (usually the callback-created one with default values).

```ruby
# User model has: after_create :create_settings (creates settings with default :every_few_hours)

# ❌ WRONG - creates duplicate settings, accessor returns the wrong one
users.create(:david, name: "David", ...)  # callback creates settings with :every_few_hours
user_settings.create(:david_settings, user: users.david, bundle_email_frequency: :never)
# Now David has TWO settings records!
# users.david.settings returns the first by ID (the :every_few_hours one)

# ✅ CORRECT - update the auto-created settings instead
users.create(:david, name: "David", ...)
users.david.settings.update!(bundle_email_frequency: :never)
# Only ONE settings record, correctly set to :never
```

**Why this matters:** Other callbacks (like `Notification#after_create :bundle`) may check `user.settings.bundling_emails?`. If the accessor returns the wrong settings record, you get unexpected bundles created during seeding, causing test failures.

**Rule of thumb:** When callbacks auto-create `has_one` associations, **update** the auto-created record instead of creating a new one.

---

## Test Adjustments Required

### 1. Account for Callback Side Effects

Tests may need to account for records created by callbacks:

```ruby
# Board with all_access: true grants access to ALL active users
# Test originally expected 3 users, but now there are 4
test "index" do
  get prompts_board_users_path(@board)
  assert_select "lexxy-prompt-item", count: @board.users.count  # Dynamic, not hardcoded
end
```

### 2. Reset State Modified by Callbacks

```ruby
test "creating a comment makes the creator watch the card" do
  # Kevin auto-watches cards he creates, so unwatch first
  cards.text.unwatch_by(users.kevin)
  assert_not cards.text.watched_by?(users.kevin)
  
  # Now test that commenting creates a watch
  cards.text.comments.create!(body: "Interesting!")
  assert cards.text.watched_by?(users.kevin)
end
```

### 3. Avoid ID Collisions

Seeded records use auto-generated IDs. Tests creating records with specific IDs must avoid collisions:

```ruby
# ❌ Collides with seeded account (external_account_id: 1)
Account.create!(external_account_id: "1st", ...)  # "1st".to_i == 1

# ✅ Use IDs that won't collide
Account.create!(external_account_id: 1001, ...)
```

### 4. Revoke All Granted Access

When testing access control on `all_access` boards, revoke ALL users:

```ruby
test "revising access" do
  boards.writebook.update!(all_access: false)
  
  # Must revoke Jason too - he got access when board was all_access
  boards.writebook.accesses.revise(
    granted: [users.david, users.jz],
    revoked: [users.kevin, users.jason]
  )
  assert_equal [users.david, users.jz].to_set, boards.writebook.users.to_set
end
```

---

## Comparison: Fixtures vs Oaken

| Aspect | Fixtures | Oaken |
|--------|----------|-------|
| Callbacks | Bypassed | Execute normally |
| Validations | Bypassed | Execute normally |
| Data insertion | Bulk SQL insert | Individual creates |
| Test isolation | Fresh load per test | Fresh load per test |
| Object identity | N/A (loaded from DB) | New instance each call |
| Setup complexity | YAML files | Ruby scripts |
| Referencing | `users(:david)` | `users.david` |
| Dynamic data | ERB in YAML | Full Ruby |

---

## Benefits Gained

1. **Realistic test data** - Callbacks ensure data integrity matches production
2. **Discoverable bugs** - Found issues with callback assumptions
3. **Ruby flexibility** - Complex seed scenarios in readable Ruby
4. **Shared with development** - Same seeds for `bin/rails db:seed`
5. **Scenario-based organization** - `accounts/37s.rb`, `accounts/initech.rb`

---

## Non-Transactional Tests: Fixture Pollution

When tests disable transactional rollback (`use_transactional_tests = false`), special care is needed to avoid polluting other tests.

### The Problem

Some tests (like search tests) must disable transactions because they need to test behavior across commits. When these tests create records on **fixture/seed data** instead of isolated test data, those records persist and pollute subsequent tests.

```ruby
module SearchTestHelper
  extend ActiveSupport::Concern

  included do
    self.use_transactional_tests = false  # Changes are COMMITTED, not rolled back!
    
    setup :setup_search_test
    teardown :teardown_search_test
  end

  def setup_search_test
    # Creates isolated @account, @user, @board for this test
    @account = Account.create!(name: "Search Test", ...)
    @user = User.create!(name: "Test User", account: @account, ...)
    @board = Board.create!(name: "Test Board", account: @account, ...)
  end

  def teardown_search_test
    # Only cleans up @account - NOT fixture data!
    Account.find_by(name: "Search Test")&.destroy
  end
end
```

### ❌ WRONG - Creates Records on Fixtures

```ruby
class Filter::SearchTest < ActiveSupport::TestCase
  include SearchTestHelper

  test "deduplicate multiple results" do
    # Creates card on FIXTURE board - never cleaned up!
    card = boards.writebook.cards.create!(title: "Test", creator: users.david)
    # ...
  end
end
```

This card persists after the test because:
1. `use_transactional_tests = false` means no rollback
2. Teardown only destroys the "Search Test" account, not `boards.writebook`
3. Other tests querying `accounts._37s.cards` find unexpected records

### ✅ CORRECT - Use Instance Variables

```ruby
class Filter::SearchTest < ActiveSupport::TestCase
  include SearchTestHelper

  test "deduplicate multiple results" do
    # Creates card on ISOLATED test board - cleaned up in teardown!
    card = @board.cards.create!(title: "Test", creator: @user)
    # ...
  end
end
```

### Symptoms of Fixture Pollution

- Tests pass individually but fail when run with the full suite
- Failures depend on `--seed` value (test ordering)
- Error messages show unexpected records with titles like "Duplicate results test"
- Set comparisons fail with extra elements

### Rule of Thumb

**In non-transactional tests, NEVER reference fixtures/seeds.** Always use instance variables created in setup that will be cleaned up in teardown.

---

## Migration Checklist

- [ ] Add `oaken` gem to Gemfile
- [ ] Create `db/seeds/setup.rb` to register namespaced models
- [ ] Create seed files in `db/seeds/` organized by scenario
- [ ] Update `test/test_helper.rb` to include `Oaken.loader.test_setup`
- [ ] Convert fixture accessors: `users(:david)` → `users.david`
- [ ] Handle numeric names: `accounts("37s")` → `accounts._37s`
- [ ] Remove manually seeded records that callbacks create
- [ ] Set `Current.account` and `Current.user` where needed
- [ ] Don't `.to_json` on JSON/store_accessor columns
- [ ] Update tests that assume no callback side effects
- [ ] Use local variables when modifying + asserting on same record
