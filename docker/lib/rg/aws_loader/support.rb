#
# Load Support assets into RedisGraph
#
# Each method returns an array of Cypher queries
#
class AWSLoader::Support < AwsGraphDbLoader
  def trusted_advisor_check
    node = 'AWS_TRUSTED_ADVISOR_CHECK'
    q = []

    # trusted_advisor_check node
    q.push(_upsert({ node: node, id: @name }))

    q
  end
end
