# Initech account scenario

# Create the account (entropy and join_code are auto-created via callbacks)
account = accounts.create :initech, name: "Initech LLC"
Current.account = account

# Label the auto-created entropy and join_code for test access
entropies.label initech_account: account.entropy
account_join_codes.label initech: account.join_code

# Update the join code to match fixtures
account.join_code.update!(code: "INIT-5678-9XYZ", usage_count: 10, usage_limit: 10)

# User for Initech (mike_identity was created in 37s.rb since he has a session there)
mike_identity = identities.mike
mike = users.create :mike, name: "Mike", role: :admin, identity: mike_identity, account: account, verified_at: Time.current
system_user = users.create :system_initech, name: "System", role: :system, account: account

# Set current user for callbacks
Current.user = mike

# Milton's Wish List board
miltons_wish_list = boards.create :miltons_wish_list, name: "Milton's Wish List", creator: mike, all_access: true, account: account

# Entropy for board (board entropy is optional)
entropies.create :miltons_wish_list_board, account: account, container: miltons_wish_list, auto_postpone_period: 90.days.to_i

# Cards
radio = cards.create :radio, account: account, board: miltons_wish_list, creator: mike,
  number: 1, title: "I want to play my radio at a reasonable volume",
  created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago

paycheck = cards.create :paycheck, account: account, board: miltons_wish_list, creator: mike,
  number: 2, title: "I haven't received my paycheck",
  created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago
