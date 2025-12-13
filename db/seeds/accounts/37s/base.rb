# 37signals account scenario

# Create the account (entropy and join_code are auto-created via callbacks)
account = accounts.create :_37s, name: "37signals"
Current.set(account:) do
  # Label the auto-created entropy and join_code for test access
  entropies.label _37s_account: account.entropy
  account_join_codes.label _37s: account.join_code

  # Update the join code to match fixtures
  account.join_code.update!(code: "37S0-5678-9XYZ", usage_count: 0, usage_limit: 10)

  # Create identities
  david_identity = identities.create :david, email_address: "david@37signals.com", staff: true
  jz_identity = identities.create :jz, email_address: "jz@37signals.com"
  jason_identity = identities.create :jason, email_address: "jason@37signals.com", staff: true
  kevin_identity = identities.create :kevin, email_address: "kevin@37signals.com", staff: true
  mike_identity = identities.create :mike, email_address: "mike@37signals.com"

  # Create users for 37s account
  david = users.create :david, name: "David", role: :member, identity: david_identity, account: account, verified_at: Time.current
  jz = users.create :jz, name: "JZ", role: :member, identity: jz_identity, account: account, verified_at: Time.current
  jason = users.create :jason, name: "Jason", role: :owner, identity: jason_identity, account: account, verified_at: Time.current
  kevin = users.create :kevin, name: "Kevin", role: :admin, identity: kevin_identity, account: account, verified_at: Time.current
  system_user = users.create :system, name: "System", role: :system, account: account

  # Create sessions for all identities
  sessions.create :david, identity: david_identity
  sessions.create :jz, identity: jz_identity
  sessions.create :jason, identity: jason_identity
  sessions.create :kevin, identity: kevin_identity
  sessions.create :mike, identity: mike_identity

  # User settings
  user_settings.create :david_settings, account: account, user: david, bundle_email_frequency: :never
  user_settings.create :jz_settings, account: account, user: jz, bundle_email_frequency: :never
  user_settings.create :kevin_settings, account: account, user: kevin, bundle_email_frequency: :never
  user_settings.create :system_settings, account: account, user: system_user, bundle_email_frequency: :never

  # Account exports
  account_exports.create :pending_export, account: account, user: david, status: :pending
  account_exports.create :completed_export, account: account, user: david, status: :completed, completed_at: 1.hour.ago

  # Tags
  web_tag = tags.create :web, account: account, title: "web"
  mobile_tag = tags.create :mobile, account: account, title: "mobile"

  # Writebook board (all_access) - creator (david) gets access via callback
  # When all_access: true, all account users get access via after_save_commit
  writebook = boards.create :writebook, name: "Writebook", creator: david, all_access: true, account: account

  # Entropy for writebook board (board entropy is optional, not auto-created)
  entropies.create :writebook_board, account: account, container: writebook, auto_postpone_period: 90.days.to_i

  # Columns for writebook
  writebook_triage = columns.create :writebook_triage, name: "Triage", color: "var(--color-card-4)", board: writebook, position: 0, account: account
  writebook_in_progress = columns.create :writebook_in_progress, name: "In progress", color: "var(--color-card-2)", board: writebook, position: 1, account: account
  writebook_on_hold = columns.create :writebook_on_hold, name: "On Hold", color: "var(--color-card-4)", board: writebook, position: 2, account: account
  writebook_review = columns.create :writebook_review, name: "Review", color: "var(--color-card-3)", board: writebook, position: 3, account: account

  # Private board - creator (kevin) gets access via callback
  private_board = boards.create :private, name: "Private board", creator: kevin, all_access: false, account: account
  entropies.create :private_board, account: account, container: private_board, auto_postpone_period: 30.days.to_i

  # Webhooks
  active_webhook = webhooks.create :active, account: account, board: writebook, active: true, name: "Production API",
                                   url: "https://api.example.com/webhooks", signing_secret: "p94Bx2HjempCdYB4DTyZkY1b",
                                   subscribed_actions: %w[card_published card_assigned card_closed]
  inactive_webhook = webhooks.create :inactive, account: account, board: private_board, active: false, name: "Test Webhook",
                                     url: "https://test.example.com/webhooks", signing_secret: "H8ms8ADcV92v2x17hnLEiL5m",
                                     subscribed_actions: %w[card_published card_assigned card_closed]

  # Webhook delinquency trackers
  webhook_delinquency_trackers.create :active_webhook_tracker, account: account, webhook: active_webhook,
                                      consecutive_failures_count: 1, first_failure_at: 1.hour.ago
  webhook_delinquency_trackers.create :inactive_webhook_tracker, account: account, webhook: inactive_webhook,
                                      consecutive_failures_count: 1, first_failure_at: 1.hour.ago

  # Cards for writebook - need to set Current.user for event callbacks
  Current.user = david
  logo = cards.create :logo, account: account, board: writebook, creator: david, column: writebook_triage,
                      number: 1, title: "The logo isn't big enough", due_on: 3.days.from_now,
                      created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago

  layout = cards.create :layout, account: account, board: writebook, creator: david, column: writebook_triage,
                        number: 2, title: "Layout is broken", created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago

  Current.user = kevin
  text = cards.create :text, account: account, board: writebook, creator: kevin, column: writebook_in_progress,
                      number: 3, title: "The text is too small", created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago

  shipping = cards.create :shipping, account: account, board: writebook, creator: kevin, column: writebook_triage,
                          number: 4, title: "We need to ship the app", created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago

  Current.user = david
  buy_domain = cards.create :buy_domain, account: account, board: writebook, creator: david,
                            number: 5, title: "Buy domain", created_at: 1.week.ago, status: :published, last_active_at: 1.week.ago

  # Update account cards_count
  account.update!(cards_count: 5)

  # Card engagements and goldnesses
  card_engagements.create :logo, account: account, card: logo
  card_goldnesses.create :logo, account: account, card: logo

  # Taggings
  taggings.create :logo_web, account: account, card: logo, tag: web_tag
  taggings.create :layout_web, account: account, card: layout, tag: web_tag
  taggings.create :layout_mobile, account: account, card: layout, tag: mobile_tag
  taggings.create :text_mobile, account: account, card: text, tag: mobile_tag

  # Comments
  # Note: System comments for assignments are auto-created by event callbacks (SystemCommenter)
  # Only create the human-authored comments here
  logo_agreement_jz = comments.create :logo_agreement_jz, account: account, card: logo, creator: jz, created_at: 2.days.ago
  logo_agreement_kevin = comments.create :logo_agreement_kevin, account: account, card: logo, creator: kevin, created_at: 2.hours.ago

  layout_1 = comments.create :layout_1, account: account, card: layout, creator: system_user
  layout_overflowing_david = comments.create :layout_overflowing_david, account: account, card: layout, creator: david

  text_1 = comments.create :text_1, account: account, card: text, creator: system_user
  shipping_1 = comments.create :shipping_1, account: account, card: shipping, creator: system_user

  # Rich texts for comments
  action_text_rich_texts.create account: account, record: logo_agreement_jz, name: "body", body: "I agree."
  action_text_rich_texts.create account: account, record: logo_agreement_kevin, name: "body", body: "Same, let's do it."
  action_text_rich_texts.create account: account, record: layout_overflowing_david, name: "body", body: "The text is overflowing the container."

  # Reactions
  reactions.create :kevin, account: account, content: "👍", comment: logo_agreement_jz, reacter: kevin
  reactions.create :david, account: account, content: "👍", comment: logo_agreement_jz, reacter: david

  # Assignments
  assignments.create :logo_jz, account: account, assigner: david, assignee: jz, card: logo, created_at: 1.week.ago
  assignments.create :logo_kevin, account: account, assigner: david, assignee: kevin, card: logo, created_at: 1.day.ago
  assignments.create :layout_jz, account: account, assigner: david, assignee: jz, card: layout

  # Watches
  watches.create :logo_david, account: account, card: logo, user: david, watching: true
  watches.create :logo_kevin, account: account, card: logo, user: kevin, watching: true
  watches.create :layout_david, account: account, card: layout, user: david, watching: true
  watches.create :layout_kevin, account: account, card: layout, user: kevin, watching: true
  watches.create :text_david, account: account, card: text, user: david, watching: true
  watches.create :text_jz, account: account, card: text, user: jz, watching: true
  watches.create :shipping_david, account: account, card: shipping, user: david, watching: true
  watches.create :shipping_jz, account: account, card: shipping, user: jz, watching: true
  watches.create :shipping_kevin, account: account, card: shipping, user: kevin, watching: true

  # Pins
  pins.create :logo_kevin, account: account, card: logo, user: kevin
  pins.create :shipping_kevin, account: account, card: shipping, user: kevin

  # Closures
  closures.create :shipping, account: account, card: shipping, user: kevin

  # Mentions
  logo_card_david_mention_by_jz = mentions.create :logo_card_david_mention_by_jz, account: account,
                                                  source: logo, mentioner: jz, mentionee: david
  logo_comment_david_mention_by_jz = mentions.create :logo_comment_david_mention_by_jz, account: account,
                                                     source: logo_agreement_jz, mentioner: jz, mentionee: david

  # Events
  logo_published = events.create :logo_published, account: account, creator: david, board: writebook,
                                 eventable: logo, action: :card_published, created_at: 1.week.ago

  logo_assignment_jz_event = events.create :logo_assignment_jz, account: account, creator: david, board: writebook,
                                           eventable: logo, action: :card_assigned, particulars: { assignee_ids: [jz.id] },
                                           created_at: 1.week.ago + 1.hour

  logo_assignment_david_event = events.create :logo_assignment_david, account: account, creator: david, board: writebook,
                                              eventable: logo, action: :card_assigned, particulars: { assignee_ids: [david.id] },
                                              created_at: 1.week.ago + 1.hour

  logo_assignment_km = events.create :logo_assignment_km, account: account, creator: david, board: writebook,
                                     eventable: logo, action: :card_assigned, particulars: { assignee_ids: [kevin.id] },
                                     created_at: 1.day.ago

  layout_published = events.create :layout_published, account: account, creator: david, board: writebook,
                                   eventable: layout, action: :card_published, created_at: 1.week.ago

  layout_commented = events.create :layout_commented, account: account, creator: david, board: writebook,
                                   eventable: layout_overflowing_david, action: :comment_created, created_at: 1.week.ago

  layout_assignment_jz_event = events.create :layout_assignment_jz, account: account, creator: david, board: writebook,
                                             eventable: layout, action: :card_assigned, particulars: { assignee_ids: [jz.id] },
                                             created_at: 1.hour.ago

  text_published = events.create :text_published, account: account, creator: kevin, board: writebook,
                                 eventable: text, action: :card_published, created_at: 1.week.ago

  shipping_published = events.create :shipping_published, account: account, creator: kevin, board: writebook,
                                     eventable: shipping, action: :card_published, created_at: 1.week.ago

  shipping_closed = events.create :shipping_closed, account: account, creator: kevin, board: writebook,
                                  eventable: shipping, action: :card_closed, created_at: 2.days.ago

  # Webhook deliveries
  webhook_deliveries.create :successfully_completed, account: account, webhook: active_webhook, event: logo_published,
                            state: :completed, request: { headers: {} }, response: { code: 200, headers: {} }, created_at: 1.week.ago

  webhook_deliveries.create :unsuccessfully_completed, account: account, webhook: active_webhook, event: logo_assignment_jz_event,
                            state: :completed, request: { headers: {} }, response: { code: 422, headers: {} }, created_at: 1.week.ago + 1.hour

  webhook_deliveries.create :errored, account: account, webhook: active_webhook, event: layout_published,
                            state: :errored, request: { headers: {} }, response: { error: "destination_unreachable" }, created_at: 1.week.ago

  webhook_deliveries.create :pending, account: account, webhook: active_webhook, event: shipping_closed,
                            state: :pending, request: nil, response: nil, created_at: 2.days.ago

  webhook_deliveries.create :in_progress, account: account, webhook: active_webhook, event: logo_assignment_km,
                            state: :in_progress, request: nil, response: nil, created_at: 1.day.ago

  # Notifications
  notifications.create :logo_published_kevin, account: account, user: kevin, source: logo_published,
                       creator: david, created_at: 1.week.ago
  notifications.create :logo_assignment_kevin, account: account, user: kevin, source: logo_assignment_km,
                       creator: david, created_at: 1.week.ago
  notifications.create :layout_commented_kevin, account: account, user: kevin, source: layout_commented,
                       creator: david, created_at: 1.week.ago
  notifications.create :logo_card_david_mention_by_jz, account: account, user: david, source: logo_card_david_mention_by_jz,
                       creator: david, created_at: 1.week.ago
  notifications.create :logo_comment_david_mention_by_jz, account: account, user: david, source: logo_comment_david_mention_by_jz,
                       creator: david, created_at: 1.week.ago

  # Filters
  jz_assignments = filters.create :jz_assignments, account: account, creator: david,
                                  indexed_by: "all", sorted_by: "newest",
                                  params_digest: Filter.digest_params({
                                                                        indexed_by: "all", sorted_by: "newest",
                                                                        tag_ids: [mobile_tag.id], assignee_ids: [jz.id]
                                                                      })

  # Filter associations (join tables)
  jz_assignments.tags << mobile_tag
  jz_assignments.assignees << jz
end
