Factory.sequence :email do |n|
  "test#{n}@example.com"
end

Factory.define :user_vish, parent: :user do |u|
  u.sequence(:name) { |n| "User#{ n }" }
  u.email { Factory.next(:email) }
  u.password "testing"
  u.password_confirmation "testing"
end