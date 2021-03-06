class GCPIAMLoader < GCPLoader
  attr_reader :asset, :import_id, :db

  def initialize(asset, db, import_id)
    @asset = asset
    @db = db
    @import_id = import_id

    load
  end

  def load
    asset_name = sanitize_value(asset['name'])
    asset_type = sanitize_value(asset['asset_type'])

    # Skip non-iam-policy resources
    return if asset['iam_policy'].nil?

    iam_policy = asset['iam_policy']
    asset.delete('iam_policy')

    asset_label = get_gcp_asset_label(asset_type)
    query = """
      MERGE (a:#{asset_label} { name: \"#{asset_name}\" })
      ON CREATE SET a.asset_type = \"#{asset_type}\",
        a.last_updated = #{import_id},
        a.loader_type = \"gcp\"
      ON MATCH SET  a.asset_type = \"#{asset_type}\",
        a.last_updated = #{import_id},
        a.loader_type = \"gcp\"
    """
    graphquery(query)

    return unless iam_policy['bindings'].is_a?(Array)

    iam_policy['bindings'].each do |iam_binding|
      role = iam_binding['role']
      iam_binding['members'].each do |member|

        member_type = member.split(':').first
        member_name = member.split(':').last 

        # Create identity if it doesn't exist   
        query = """
          MERGE (i:GCP_IDENTITY { name: \"#{member}\" })
          ON CREATE SET i.member_name = \"#{member_name}\",
            i.member_type = \"#{member_type}\",
            i.last_updated = #{import_id},
            i.loader_type = \"gcp\"
          ON MATCH  SET i.member_name = \"#{member_name}\",
            i.member_type = \"#{member_type}\",
            i.last_updated = #{import_id},
            i.loader_type = \"gcp\"
        """
        graphquery(query)

        # Create relationship from Identity to Resource
        query = """
          MATCH (i:GCP_IDENTITY { name: \"#{member}\" })
          MERGE (p:#{asset_label} { name: \"#{asset_name}\" })
          MERGE (i)-[:HAS_IAMROLE {role_name: \"#{role}\", 
            last_updated: #{import_id}, loader_type: \"gcp\"}]->(p)
        """
        graphquery(query)

        # Create Role if it doesn't exist
        query = """
          MERGE (r:GCP_IAM_IAMROLE { name: \"#{role}\" })
          ON CREATE set r.type = 'gcp', r.last_updated = #{import_id}, r.loader_type = \"gcp\"
          ON MATCH set r.type = 'gcp', r.last_updated = #{import_id}, r.loader_type = \"gcp\"
        """
        graphquery(query)

        # Create relationship from Identity to Role
        query = """
          MATCH (i:GCP_IDENTITY { name: \"#{member}\" })
          MERGE (r:GCP_IAM_IAMROLE { name: \"#{role}\" })
          MERGE (i)-[:HAS_ACCESSVIA {resource: \"#{asset_name}\", 
            last_updated: #{import_id}, loader_type: \"gcp\" }]->(r)
        """
        graphquery(query)

        # Create relationship from Role to Resource
        query = """
          MATCH (i:GCP_IAM_IAMROLE { name: \"#{role}\" })
          MERGE (r:#{asset_label} { name: \"#{asset_name}\" })
          MERGE (i)-[:IS_GRANTEDTO { identity: \"#{member}\",
                                     identity_name: \"#{member_name}\",
                                     identity_type: \"#{member_type}\",
                                     last_updated: #{import_id},
                                     loader_type: \"gcp\"
                                   }]->(r)
        """
        graphquery(query)
      end
    end
  end
end
