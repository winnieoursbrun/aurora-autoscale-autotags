require 'aws-sdk-rds'

# When a RDS instance is created, check if it is a Aurora Autoscaling Instance
# If it is, then copy paste the tags from the Aurora Cluster to the RDS Instance
# This is needed because Aurora Autoscaling does not copy tags from the Cluster to the Instance
def main(event:, context:)
  # Get the RDS Instance ARN
  rds_instance_arn = event['detail']['responseElements']['dBInstanceArn']

  # Get the RDS Instance Cluster ARN
  rds_cluster_identifier = event['detail']['responseElements']['dBClusterIdentifier']

  # Get the RDS Cluster ARN
  rds_cluster_arn = get_rds_cluster_arn(rds_cluster_identifier)

  # Get the RDS Cluster Tags
  rds_cluster_tags = get_rds_cluster_tags(rds_cluster_arn)

  # If the RDS Cluster has tags, then copy them to the RDS Instance
  if rds_cluster_tags
    copy_tags(rds_instance_arn, rds_cluster_tags)
  end
end

# Get the RDS Cluster ARN
def get_rds_cluster_arn(rds_cluster_identifier)
  # Get the RDS Cluster ARN
  rds_client = Aws::RDS::Client.new
  rds_cluster = rds_client.describe_db_clusters({
    db_cluster_identifier: rds_cluster_identifier
  })

  # Return the RDS Cluster ARN
  return rds_cluster.db_clusters[0].db_cluster_arn
end


# Get the RDS Cluster Tags
def get_rds_cluster_tags(rds_cluster_arn)
  # Get the RDS Cluster Tags
  rds_client = Aws::RDS::Client.new
  rds_cluster_tags = rds_client.list_tags_for_resource({
    resource_name: rds_cluster_arn
  })

  # If there are no tags, return nil
  if rds_cluster_tags.tag_list.empty?
    return nil
  end

  # Return the RDS Cluster Tags
  return rds_cluster_tags.tag_list
end

# Copy the RDS Cluster Tags to the RDS Instance
def copy_tags(rds_instance_arn, rds_cluster_tags)
  # Get the RDS Instance Tags
  rds_client = Aws::RDS::Client.new
  rds_client.add_tags_to_resource({
    resource_name: rds_instance_arn,
    tags: rds_cluster_tags
  })
end