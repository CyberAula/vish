# Need to create single relations before spec rollbacks
# Otherwise, they won't be cached in the class
Relation::Public.instance
Relation::Follow.instance
