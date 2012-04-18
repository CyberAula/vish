# Need to create single relations before spec rollbacks
# Otherwise, they won't be cached in the class
%w( Follow Public Reject ).each do |r|
  "Relation::#{ r }".constantize.instance
end
