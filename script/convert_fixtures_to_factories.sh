#!/bin/bash

# Script to convert all test files from fixtures to factories using amp

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DONE_FILE="$SCRIPT_DIR/fixtures_to_factories_done.txt"

# If a file is passed as argument, use it; otherwise find all test files excluding already done ones
if [ -n "$1" ]; then
  TEST_FILES="$1"
else
  # Find all test files, exclude ones already in the done list
  TEST_FILES=$(find test -name "*_test.rb" | sort | while read -r file; do
    basename=$(basename "$file")
    if ! grep -qx "$basename" "$DONE_FILE" 2>/dev/null; then
      echo "$file"
    fi
  done)
fi

PROMPT='Convert this test file from using fixtures to using FactoryBot factories.

## Rules:
1. Replace all fixture references like `cards(:layout)` with `create(:card, :layout)`
2. Replace all fixture references like `users(:kevin)` with `create(:user, :kevin)`
3. This codebase includes FactoryBot::Syntax::Methods, so use `create()`, `build()`, etc. directly without the `FactoryBot.` prefix
4. Store factory-created objects in local variables at the start of each test to avoid creating duplicates
5. Make sure associated objects share the same account/board/etc when needed
6. The factories are in test/factories/ - check them to understand available traits
7. Keep the test logic and assertions the same, only change how objects are created
8. IMPORTANT: Replace `accounts(:\"37s\")` or `accounts(\"37s\")` with `Current.account` - do NOT create a factory for the account

## Example conversion:

BEFORE (using fixtures):
```ruby
require "test_helper"

class Card::AssignableTest < ActiveSupport::TestCase
  test "assigning a user makes them watch the card" do
    assert_not cards(:layout).assigned_to?(users(:kevin))
    cards(:layout).unwatch_by users(:kevin)

    with_current_user(:jz) do
      cards(:layout).toggle_assignment(users(:kevin))
    end

    assert cards(:layout).assigned_to?(users(:kevin))
    assert cards(:layout).watched_by?(users(:kevin))
  end
end
```

AFTER (using factories):
```ruby
require "test_helper"

class Card::AssignableTest < ActiveSupport::TestCase
  test "assigning a user makes them watch the card" do
    account = Current.account
    board = create(:board, :writebook, account: account)
    column = create(:column, :writebook_triage, board: board, account: account)
    kevin = create(:user, :kevin, account: account)
    jz = create(:user, :jz, account: account)
    card = create(:card, :layout, board: board, column: column, account: account)

    assert_not card.assigned_to?(kevin)
    card.unwatch_by kevin

    with_current_user(jz) do
      card.toggle_assignment(kevin)
    end

    assert card.assigned_to?(kevin)
    assert card.watched_by?(kevin)
  end
end
```

Convert all tests in this file following this pattern. Check the factories in test/factories/ to understand available traits and associations.'

# Counter for progress
TOTAL=$(echo "$TEST_FILES" | wc -l | tr -d ' ')
CURRENT=0

for file in $TEST_FILES; do
  CURRENT=$((CURRENT + 1))
  echo "[$CURRENT/$TOTAL] Processing: $file"
  amp --dangerously-allow-all -x "$PROMPT

Now convert this file: $file" < /dev/null
  # Append the basename to the done file
  basename "$file" >> "$DONE_FILE"
  echo "  -> Done (added to done list)"
done

echo ""
echo "Conversion complete! Review changes with: git diff"
