resource "aws_servicecatalogappregistry_application" "app_registry968496_a3" {
  description = join("", ["Service Catalog application to track and manage all your resources for the solution ", local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["SolutionName"]])
  name        = join("-", [local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["AppRegistryApplicationName"], data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.stack_name])
  // CF Property(Tags) = {
  //   Solutions:ApplicationType = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["ApplicationType"]
  //   Solutions:SolutionID = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["ID"]
  //   Solutions:SolutionName = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["SolutionName"]
  //   Solutions:SolutionVersion = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["Version"]
  // }
}

resource "aws_servicecatalogappregistry_application" "app_registry_default_application_attributes15279635" {
  // CF Property(Attributes) = {
  //   applicationType = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["ApplicationType"]
  //   version = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["Version"]
  //   solutionID = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["ID"]
  //   solutionName = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["SolutionName"]
  // }
  description = "Attribute group for solution information"
  name        = join("", ["attgroup-", join("-", [data.aws_region.current.name, local.stack_name])])
  // CF Property(Tags) = {
  //   Solutions:ApplicationType = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["ApplicationType"]
  //   Solutions:SolutionID = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["ID"]
  //   Solutions:SolutionName = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["SolutionName"]
  //   Solutions:SolutionVersion = local.mappings["AppRegistryForInstanceSchedulerSolution25A90F05"]["Data"]["Version"]
  // }
}

resource "aws_cloudwatch_log_group" "scheduler_log_group" {
  name              = join("", [local.stack_name, "-logs"])
  retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "scheduler_role" {
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
    Version = "2012-10-17"
  })
  path = "/"
}

resource "aws_iam_policy" "scheduler_role_default_policy66_f774_b8" {
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:ConditionCheckItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Effect = "Allow"
        Resource = [
          aws_dynamodb_table.state_table.arn,
          null
        ]
      },
      {
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:UpdateItem"
        ]
        Effect = "Allow"
        Resource = [
          aws_dynamodb_table.config_table.arn,
          aws_dynamodb_table.maintenance_window_table.arn
        ]
      },
      {
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/Solutions/instance-scheduler-on-aws/UUID/*"
      }
    ]
    Version = "2012-10-17"
  })
  name = "SchedulerRoleDefaultPolicy66F774B8"
  // CF Property(Roles) = [
  //   aws_iam_role.scheduler_role.arn
  // ]
}

resource "aws_kms_key" "instance_scheduler_encryption_key" {
  description         = "Key for SNS"
  enable_key_rotation = true
  is_enabled          = true
  policy = jsonencode({
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = join("", ["arn:", data.aws_partition.current.partition, ":iam::", data.aws_caller_identity.current.account_id, ":root"])
        }
        Resource = "*"
        Sid      = "default"
      },
      {
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.scheduler_role.arn
        }
        Resource = "*"
        Sid      = "Allows use of key"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_kms_alias" "instance_scheduler_encryption_key_alias" {
  name          = join("", ["alias/", local.stack_name, "-instance-scheduler-encryption-key"])
  target_key_id = aws_kms_key.instance_scheduler_encryption_key.arn
}

resource "aws_sns_topic" "instance_scheduler_sns_topic" {
  kms_master_key_id = aws_kms_key.instance_scheduler_encryption_key.arn
}

resource "aws_lambda_function" "main" {

  s3_bucket = "solutions-${data.aws_region.current.name}"
  s3_key    = "instance-scheduler-on-aws/v1.5.6/c6dfee04af55f62793358aeab1af6a966518f178e103f5b369e16e056f940c1b.zip"

  description = "EC2 and RDS instance scheduler, version v1.5.6"
  environment {
    variables = {
      SCHEDULER_FREQUENCY                = var.scheduler_frequency
      LOG_GROUP                          = aws_cloudwatch_log_group.scheduler_log_group.arn
      ACCOUNT                            = data.aws_caller_identity.current.account_id
      ISSUES_TOPIC_ARN                   = aws_sns_topic.instance_scheduler_sns_topic.id
      STACK_NAME                         = local.stack_name
      SEND_METRICS                       = local.mappings["mappings"]["TrueFalse"][local.mappings["Send"]["AnonymousUsage"]["Data"]]
      SOLUTION_ID                        = local.mappings["mappings"]["Settings"]["MetricsSolutionId"]
      SOLUTION_VERSION                   = "v1.5.6"
      TRACE                              = local.mappings["mappings"]["TrueFalse"][var.trace]
      USER_AGENT_EXTRA                   = "AwsSolution/SO0030/v1.5.6"
      METRICS_URL                        = local.mappings["mappings"]["Settings"]["MetricsUrl"]
      STACK_ID                           = local.stack_id
      UUID_KEY                           = local.mappings["Send"]["ParameterKey"]["UniqueId"]
      START_EC2_BATCH_SIZE               = "5"
      SCHEDULE_TAG_KEY                   = var.tag_name
      DEFAULT_TIMEZONE                   = var.default_timezone
      ENABLE_CLOUDWATCH_METRICS          = local.mappings["mappings"]["TrueFalse"][var.use_cloud_watch_metrics]
      ENABLE_EC2_SERVICE                 = local.ScheduleEC2 ? "True" : "False"
      ENABLE_RDS_SERVICE                 = local.ScheduleRDS ? "True" : "False"
      ENABLE_RDS_CLUSTERS                = local.mappings["mappings"]["TrueFalse"][var.schedule_rds_clusters]
      ENABLE_RDS_SNAPSHOTS               = local.mappings["mappings"]["TrueFalse"][var.create_rds_snapshot]
      SCHEDULE_REGIONS                   = join(",", var.regions)
      APP_NAMESPACE                      = var.namespace
      SCHEDULER_ROLE_NAME                = local.mappings["mappings"]["SchedulerRole"]["Name"]
      ENABLE_SCHEDULE_HUB_ACCOUNT        = local.mappings["mappings"]["TrueFalse"][var.schedule_lambda_account]
      ENABLE_EC2_SSM_MAINTENANCE_WINDOWS = local.mappings["mappings"]["TrueFalse"][var.enable_ssm_maintenance_windows]
      START_TAGS                         = var.started_tags
      STOP_TAGS                          = var.stopped_tags
      ENABLE_AWS_ORGANIZATIONS           = local.mappings["mappings"]["TrueFalse"][var.using_aws_organizations]
      DDB_TABLE_NAME                     = aws_dynamodb_table.state_table.arn
      CONFIG_TABLE                       = aws_dynamodb_table.config_table.arn
      MAINTENANCE_WINDOW_TABLE           = aws_dynamodb_table.maintenance_window_table.arn
      STATE_TABLE                        = aws_dynamodb_table.state_table.arn
    }
  }
  function_name = join("", [local.stack_name, "-InstanceSchedulerMain"])
  handler       = "instance_scheduler.main.lambda_handler"
  memory_size   = var.memory_size
  role          = aws_iam_role.scheduler_role.arn
  runtime       = "python3.10"
  timeout       = 300
  tracing_config {
    mode = "Active"
  }
}

resource "aws_dynamodb_table" "state_table" {
  name = join("", [local.stack_name, "-state_table"])

  hash_key  = "service"
  range_key = "account-region"

  attribute {
    name = "service"
    type = "S"
  }

  attribute {
    name = "account-region"
    type = "S"
  }

  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }
  // CF Property(SSESpecification) = {
  //   KMSMasterKeyId = aws_kms_key.instance_scheduler_encryption_key.arn
  //   SSEEnabled = true
  //   SSEType = "KMS"
  // }
}

resource "aws_dynamodb_table" "config_table" {
  name      = join("", [local.stack_name, "-config_table"])
  hash_key  = "type"
  range_key = "name"

  attribute {
    name = "type"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }
  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }
  // CF Property(SSESpecification) = {
  //   KMSMasterKeyId = aws_kms_key.instance_scheduler_encryption_key.arn
  //   SSEEnabled = true
  //   SSEType = "KMS"
  // }
}

resource "aws_dynamodb_table" "maintenance_window_table" {
  name      = join("", [local.stack_name, "-maintenance_window_table"])
  hash_key  = "Name"
  range_key = "account-region"

  attribute {
    name = "Name"
    type = "S"
  }
  attribute {
    name = "account-region"
    type = "S"
  }

  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }
  // CF Property(SSESpecification) = {
  //   KMSMasterKeyId = aws_kms_key.instance_scheduler_encryption_key.arn
  //   SSEEnabled = true
  //   SSEType = "KMS"
  // }
}

resource "aws_cloudwatch_event_rule" "scheduler_rule" {
  description         = "Instance Scheduler - Rule to trigger instance for scheduler function version v1.5.6"
  schedule_expression = local.mappings["mappings"]["Timeouts"][var.scheduler_frequency]
  state               = local.mappings["mappings"]["EnabledDisabled"][var.scheduling_active]
  // CF Property(Targets) = [
  //   {
  //     Arn = aws_lambda_function.main.arn
  //     Id = "Target0"
  //     Input = "{"scheduled_action":"run_orchestrator"}"
  //   }
  // ]
}

resource "aws_lambda_permission" "scheduler_event_rule_allow_event_ruleinstancescheduleronawsschedulerlambda628965517101_a947" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduler_rule.arn
}

resource "aws_iam_policy" "ec2_permissions_b6_e87802" {
  policy = jsonencode({
    Statement = [
      {
        Action   = "ec2:ModifyInstanceAttribute"
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
      },
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:iam::*:role/${var.namespace}-${local.mappings["mappings"]["SchedulerRole"]["Name"]}"
      }
    ]
    Version = "2012-10-17"
  })
  name = "Ec2PermissionsB6E87802"
  // CF Property(Roles) = [
  //   aws_iam_role.scheduler_role.arn
  // ]
}

resource "aws_iam_policy" "ec2_dynamo_db_policy" {
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/*"
      },
      {
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "ec2:DescribeInstances",
          "cloudwatch:PutMetricData",
          "ssm:DescribeMaintenanceWindows",
          "tag:GetResources"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutRetentionPolicy"
        ]
        Effect = "Allow"
        Resource = [
          "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*",
          aws_cloudwatch_log_group.scheduler_log_group.arn
        ]
      }
    ]
    Version = "2012-10-17"
  })
  name = "EC2DynamoDBPolicy"
  // CF Property(Roles) = [
  //   aws_iam_role.scheduler_role.arn
  // ]
}

resource "aws_iam_policy" "scheduler_policy" {
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource",
          "rds:DescribeDBSnapshots",
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*"
      },
      {
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
      },
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = aws_sns_topic.instance_scheduler_sns_topic.id
      },
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.stack_name}-InstanceSchedulerMain"
      },
      {
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.instance_scheduler_encryption_key.arn
      }
    ]
    Version = "2012-10-17"
  })
  name = "SchedulerPolicy"
  // CF Property(Roles) = [
  //   aws_iam_role.scheduler_role.arn
  // ]
}

resource "aws_iam_policy" "scheduler_rds_policy2_e7_c328_a" {
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "rds:DeleteDBSnapshot",
          "rds:DescribeDBSnapshots",
          "rds:StopDBInstance"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:*"
      },
      {
        Action = [
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource",
          "rds:StartDBCluster",
          "rds:StopDBCluster"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*"
      }
    ]
    Version = "2012-10-17"
  })
  name = "SchedulerRDSPolicy2E7C328A"
  // CF Property(Roles) = [
  //   aws_iam_role.scheduler_role.arn
  // ]
}
