# 37signals account scenario

# Create the account (entropy and join_code are auto-created via callbacks)
account = accounts.create(:_37s, name: "37signals")
Current.set(account:) do
  # Label the auto-created entropy and join_code for test access
  entropies.label(_37s_account: account.entropy)
  account_join_codes.label(_37s: account.join_code)

  # Update the join code to match fixtures
  account.join_code.update!(code: "37S0-5678-9XYZ", usage_count: 0, usage_limit: 10)

  # Create identities
  identities.create(:jason, email_address: "jason@37signals.com", staff: true)
  identities.create(:david, email_address: "david@37signals.com", staff: true)
  identities.create(:kevin, email_address: "kevin@37signals.com", staff: true)
  identities.create(:jz, email_address: "jz@37signals.com")
  identities.create(:mike, email_address: "mike@37signals.com")

  # Create users for 37s account
  users.create(:jason,  name: "Jason",  role: :owner,  account:, identity: identities.jason, verified_at: Time.current)
  users.create(:kevin,  name: "Kevin",  role: :admin,  account:, identity: identities.kevin, verified_at: Time.current)
  users.create(:david,  name: "David",  role: :member, account:, identity: identities.david, verified_at: Time.current)
  users.create(:jz,     name: "JZ",     role: :member, account:, identity: identities.jz,    verified_at: Time.current)
  users.create(:system, name: "System", role: :system, account:)

  # Create sessions for all identities
  sessions.create(:david, identity: identities.david)
  sessions.create(:jz,    identity: identities.jz)
  sessions.create(:jason, identity: identities.jason)
  sessions.create(:kevin, identity: identities.kevin)
  sessions.create(:mike,  identity: identities.mike)

  # User settings - update the auto-created settings instead of creating duplicates
  # (User after_create callback creates settings with default :every_few_hours)
  users.david.settings.update!(bundle_email_frequency: :never)
  users.jz.settings.update!(bundle_email_frequency: :never)
  users.kevin.settings.update!(bundle_email_frequency: :never)
  # system user doesn't have settings (after_create callback skips for system?)

  # Account exports
  account_exports.create(:pending_export,   account:, user: users.david, status: :pending)
  account_exports.create(:completed_export, account:, user: users.david, status: :completed, completed_at: 1.hour.ago)

  # Tags
  tags.create(:web,    account:, title: "web")
  tags.create(:mobile, account:, title: "mobile")


  # Writebook board (all_access) - creator (david) gets access via callback ============================================
  boards.create(:writebook, name: "Writebook", creator: users.david, all_access: true, account:)
  entropies.create(:writebook_board, account:, container: boards.writebook, auto_postpone_period: 90.days.to_i)

  columns.create(:writebook_triage,      account:, board: boards.writebook, name: "Triage",      color: "var(--color-card-4)", position: 0)
  columns.create(:writebook_in_progress, account:, board: boards.writebook, name: "In progress", color: "var(--color-card-2)", position: 1)
  columns.create(:writebook_on_hold,     account:, board: boards.writebook, name: "On Hold",     color: "var(--color-card-4)", position: 2)
  columns.create(:writebook_review,      account:, board: boards.writebook, name: "Review",      color: "var(--color-card-3)", position: 3)
  # ====================================================================================================================


  # Private board - creator (kevin) gets access via callback ===========================================================
  boards.create(:private, name: "Private board", creator: users.kevin, all_access: false, account:)
  entropies.create(:private_board, account:, container: boards.private, auto_postpone_period: 30.days.to_i)
  # ====================================================================================================================

  # Webhooks
  webhooks.create(:active, account:, board: boards.writebook, active: true, name: "Production API",
                  url: "https://api.example.com/webhooks", signing_secret: "p94Bx2HjempCdYB4DTyZkY1b",
                  subscribed_actions: %w[card_published card_assigned card_closed])
  webhooks.create(:inactive, account:, board: boards.private, active: false, name: "Test Webhook",
                  url: "https://test.example.com/webhooks", signing_secret: "H8ms8ADcV92v2x17hnLEiL5m",
                  subscribed_actions: %w[card_published card_assigned card_closed])

  # Webhook delinquency trackers
  webhook_delinquency_trackers.create(:active_webhook_tracker, account:, webhook: webhooks.active,
                                      consecutive_failures_count: 1, first_failure_at: 1.hour.ago)
  webhook_delinquency_trackers.create(:inactive_webhook_tracker, account:, webhook: webhooks.inactive,
                                      consecutive_failures_count: 1, first_failure_at: 1.hour.ago)

  # Cards for writebook - need to set Current.user for event callbacks
  Current.set(user: users.david) do
    cards.create(:logo, account:, board: boards.writebook, column: columns.writebook_triage, number: 1, title: "The logo isn't big enough", due_on: 3.days.from_now, created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago)
    cards.create(:layout, account:, board: boards.writebook, column: columns.writebook_triage, number: 2, title: "Layout is broken", created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago)
    cards.create(:buy_domain, account:, board: boards.writebook, number: 5, title: "Buy domain", created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago)
  end

  Current.set(user: users.kevin) do
    cards.create(:text, account:, board: boards.writebook, creator: users.kevin, column: columns.writebook_in_progress, number: 3, title: "The text is too small", created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago)
    cards.create(:shipping, account:, board: boards.writebook, creator: users.kevin, column: columns.writebook_triage, number: 4, title: "We need to ship the app", created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago)
  end

  # Update Writebook account cards_count
  account.update!(cards_count: 5)

  # Card engagements and goldnesses
  card_engagements.create(:logo, account:, card: cards.logo)
  card_goldnesses.create(:logo, account:, card: cards.logo)

  # Taggings
  taggings.create(:logo_web, account:, card: cards.logo, tag: tags.web)
  taggings.create(:layout_web, account:, card: cards.layout, tag: tags.web)
  taggings.create(:layout_mobile, account:, card: cards.layout, tag: tags.mobile)
  taggings.create(:text_mobile, account:, card: cards.text, tag: tags.mobile)

  # Comments
  # Note: System comments for assignments are auto-created by event callbacks (SystemCommenter)
  # Only create the human-authored comments here
  comments.create(:logo_agreement_jz, account:, card: cards.logo, creator: users.jz, created_at: 2.days.ago)
  comments.create(:logo_agreement_kevin, account:, card: cards.logo, creator: users.kevin, created_at: 2.hours.ago)

  comments.create(:layout_1, account:, card: cards.layout, creator: users.system)
  comments.create(:layout_overflowing_david, account:, card: cards.layout, creator: users.david)

  comments.create(:text_1, account:, card: cards.text, creator: users.system)
  comments.create(:shipping_1, account:, card: cards.shipping, creator: users.system)

  # Rich texts for comments
  action_text_rich_texts.create(account:, record: comments.logo_agreement_jz, name: "body", body: "I agree.")
  action_text_rich_texts.create(account:, record: comments.logo_agreement_kevin, name: "body", body: "Same, let's do it.")
  action_text_rich_texts.create(account:, record: comments.layout_overflowing_david, name: "body", body: "The text is overflowing the container.")

  # Reactions
  reactions.create(:kevin, account:, content: "👍", comment: comments.logo_agreement_jz, reacter: users.kevin)
  reactions.create(:david, account:, content: "👍", comment: comments.logo_agreement_jz, reacter: users.david)

  # Assignments
  assignments.create(:logo_jz, account:, assigner: users.david, assignee: users.jz, card: cards.logo, created_at: 1.week.ago)
  assignments.create(:logo_kevin, account:, assigner: users.david, assignee: users.kevin, card: cards.logo, created_at: 1.day.ago)
  assignments.create(:layout_jz, account:, assigner: users.david, assignee: users.jz, card: cards.layout)

  # Watches
  watches.create(:logo_david, account:, card: cards.logo, user: users.david, watching: true)
  watches.create(:logo_kevin, account:, card: cards.logo, user: users.kevin, watching: true)

  watches.create(:layout_david, account:, card: cards.layout, user: users.david, watching: true)
  watches.create(:layout_kevin, account:, card: cards.layout, user: users.kevin, watching: true)

  watches.create(:text_david, account:, card: cards.text, user: users.david, watching: true)
  watches.create(:text_jz, account:, card: cards.text, user: users.jz, watching: true)

  watches.create(:shipping_david, account:, card: cards.shipping, user: users.david, watching: true)
  watches.create(:shipping_jz, account:, card: cards.shipping, user: users.jz, watching: true)
  watches.create(:shipping_kevin, account:, card: cards.shipping, user: users.kevin, watching: true)

  # Pins
  pins.create(:logo_kevin, account:, card: cards.logo, user: users.kevin)
  pins.create(:shipping_kevin, account:, card: cards.shipping, user: users.kevin)

  # Closures
  closures.create(:shipping, account:, card: cards.shipping, user: users.kevin)

  # Mentions
  mentions.create(:logo_card_david_mention_by_jz, account:, source: cards.logo, mentioner: users.jz, mentionee: users.david)
  mentions.create(:logo_comment_david_mention_by_jz, account:, source: comments.logo_agreement_jz, mentioner: users.jz, mentionee: users.david)

  # Events
  events.create(:logo_published, account:, creator: users.david, board: boards.writebook, eventable: cards.logo, action: :card_published, created_at: 1.week.ago)
  events.create(:logo_assignment_jz, account:, creator: users.david, board: boards.writebook, eventable: cards.logo, action: :card_assigned, particulars: { assignee_ids: [users.jz.id] }, created_at: 1.week.ago + 1.hour)
  events.create(:logo_assignment_david, account:, creator: users.david, board: boards.writebook, eventable: cards.logo, action: :card_assigned, particulars: { assignee_ids: [users.david.id] }, created_at: 1.week.ago + 1.hour)
  events.create(:logo_assignment_km, account:, creator: users.david, board: boards.writebook, eventable: cards.logo, action: :card_assigned, particulars: { assignee_ids: [users.kevin.id] }, created_at: 1.day.ago)
  events.create(:layout_published, account:, creator: users.david, board: boards.writebook, eventable: cards.layout, action: :card_published, created_at: 1.week.ago)
  events.create(:layout_commented, account:, creator: users.david, board: boards.writebook, eventable: comments.layout_overflowing_david, action: :comment_created, created_at: 1.week.ago)
  events.create(:layout_assignment_jz, account:, creator: users.david, board: boards.writebook, eventable: cards.layout, action: :card_assigned, particulars: { assignee_ids: [users.jz.id] }, created_at: 1.hour.ago)
  events.create(:text_published, account:, creator: users.kevin, board: boards.writebook, eventable: cards.text, action: :card_published, created_at: 1.week.ago)
  events.create(:shipping_published, account:, creator: users.kevin, board: boards.writebook, eventable: cards.shipping, action: :card_published, created_at: 1.week.ago)
  events.create(:shipping_closed, account:, creator: users.kevin, board: boards.writebook, eventable: cards.shipping, action: :card_closed, created_at: 2.days.ago)

  # Webhook deliveries
  webhook_deliveries.create(:successfully_completed, account:, webhook: webhooks.active, event: events.logo_published, state: :completed, request: { headers: {} }, response: { code: 200, headers: {} }, created_at: 1.week.ago)
  webhook_deliveries.create(:unsuccessfully_completed, account:, webhook: webhooks.active, event: events.logo_assignment_jz, state: :completed, request: { headers: {} }, response: { code: 422, headers: {} }, created_at: 1.week.ago + 1.hour)
  webhook_deliveries.create(:errored, account:, webhook: webhooks.active, event: events.layout_published, state: :errored, request: { headers: {} }, response: { error: "destination_unreachable" }, created_at: 1.week.ago)
  webhook_deliveries.create(:pending, account:, webhook: webhooks.active, event: events.shipping_closed, state: :pending, request: nil, response: nil, created_at: 2.days.ago)
  webhook_deliveries.create(:in_progress, account:, webhook: webhooks.active, event: events.logo_assignment_km, state: :in_progress, request: nil, response: nil, created_at: 1.day.ago)

  # Notifications
  notifications.create(:logo_published_kevin, account:, user: users.kevin, source: events.logo_published, creator: users.david, created_at: 1.week.ago)
  notifications.create(:logo_assignment_kevin, account:, user: users.kevin, source: events.logo_assignment_km, creator: users.david, created_at: 1.week.ago)
  notifications.create(:layout_commented_kevin, account:, user: users.kevin, source: events.layout_commented, creator: users.david, created_at: 1.week.ago)
  notifications.create(:logo_card_david_mention_by_jz, account:, user: users.david, source: mentions.logo_card_david_mention_by_jz, creator: users.david, created_at: 1.week.ago)
  notifications.create(:logo_comment_david_mention_by_jz, account:, user: users.david, source: mentions.logo_comment_david_mention_by_jz, creator: users.david, created_at: 1.week.ago)

  # Filters
  filters.create(:jz_assignments, account:, creator: users.david, indexed_by: "all", sorted_by: "newest", params_digest: Filter.digest_params({ indexed_by: "all", sorted_by: "newest", tag_ids: [tags.mobile.id], assignee_ids: [users.jz.id] }))

  # Filter associations (join tables)
  filters.jz_assignments.tags << tags.mobile
  filters.jz_assignments.assignees << users.jz
end
