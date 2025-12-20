# Initech account scenario

# Create the account (entropy and join_code are auto-created via callbacks)
accounts.create :initech, name: "Initech LLC"
Current.account = accounts.initech

# Label the auto-created entropy and join_code for test access
entropies.label initech_account: accounts.initech.entropy
account_join_codes.label initech: accounts.initech.join_code

# Update the join code to match fixtures
accounts.initech.join_code.update!(code: "INIT-5678-9XYZ", usage_count: 10, usage_limit: 10)

# User for Initech (mike_identity was created in 37s.rb since he has a session there)
users.create :mike, name: "Mike", role: :admin, identity: identities.mike, account: accounts.initech, verified_at: Time.current
users.create :system_initech, name: "System", role: :system, account: accounts.initech

# Set current user for callbacks
Current.user = users.mike

# Milton's Wish List board
boards.create :miltons_wish_list, name: "Milton's Wish List", creator: users.mike, all_access: true, account: accounts.initech

# Entropy for board (board entropy is optional)
entropies.create :miltons_wish_list_board, account: accounts.initech, container: boards.miltons_wish_list, auto_postpone_period: 90.days.to_i

# Cards
cards.create :radio, account: accounts.initech, board: boards.miltons_wish_list, creator: users.mike,
  number: 1, title: "I want to play my radio at a reasonable volume",
  created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago

cards.create :paycheck, account: accounts.initech, board: boards.miltons_wish_list, creator: users.mike,
  number: 2, title: "I haven't received my paycheck",
  created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago
