# Oaken setup: register namespaced models and define defaults/helpers

loader.register Account::Export
loader.register Account::JoinCode
loader.register Card::Engagement
loader.register Card::Goldness
loader.register User::Settings
loader.register Webhook::DelinquencyTracker
loader.register Webhook::Delivery
loader.register ActionText::RichText

def identities.create_labeled(label, email_address: "#{label}@example.com", **)
  create(label, email_address:, **)
end

def users.create_labeled(label, name: label.to_s.titleize, identity: nil, **)
  create(label, name:, identity:, verified_at: Time.current, **)
end
