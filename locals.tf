locals {
  mappings = {
    mappings = {
      TrueFalse = {
        Yes = "True"
        No  = "False"
      }
      EnabledDisabled = {
        Yes = "ENABLED"
        No  = "DISABLED"
      }
      Services = {
        EC2  = "ec2"
        RDS  = "rds"
        Both = "ec2,rds"
      }
      Timeouts = {
        1  = "cron(0/1 * * * ? *)"
        2  = "cron(0/2 * * * ? *)"
        5  = "cron(0/5 * * * ? *)"
        10 = "cron(0/10 * * * ? *)"
        15 = "cron(0/15 * * * ? *)"
        30 = "cron(0/30 * * * ? *)"
        60 = "cron(0 0/1 * * ? *)"
      }
      Settings = {
        MetricsUrl        = "https://metrics.awssolutionsbuilder.com/generic"
        MetricsSolutionId = "S00030"
      }
      SchedulerRole = {
        Name = "Scheduler-Role"
      }
      SchedulerEventBusName = {
        Name = "scheduler-event-bus"
      }
    }
    Send = {
      AnonymousUsage = {
        Data = "Yes"
      }
      ParameterKey = {
        UniqueId = "/Solutions/instance-scheduler-on-aws/UUID/"
      }
    }
    AppRegistryForInstanceSchedulerSolution25A90F05 = {
      Data = {
        ID                         = "SO0030"
        Version                    = "v1.5.6"
        AppRegistryApplicationName = "instance-scheduler-on-aws"
        SolutionName               = "instance-scheduler-on-aws"
        ApplicationType            = "AWS-Solutions"
      }
    }
  }
  IsMemberOfOrganization = var.using_aws_organizations == "Yes"
  ScheduleEC2            = anytrue([var.scheduled_services == "EC2", var.scheduled_services == "Both"])
  ScheduleRDS            = anytrue([var.scheduled_services == "RDS", var.scheduled_services == "Both"])
  CDKMetadataAvailable   = anytrue([anytrue([data.aws_region.current.name == "af-south-1", data.aws_region.current.name == "ap-east-1", data.aws_region.current.name == "ap-northeast-1", data.aws_region.current.name == "ap-northeast-2", data.aws_region.current.name == "ap-south-1", data.aws_region.current.name == "ap-southeast-1", data.aws_region.current.name == "ap-southeast-2", data.aws_region.current.name == "ca-central-1", data.aws_region.current.name == "cn-north-1", data.aws_region.current.name == "cn-northwest-1"]), anytrue([data.aws_region.current.name == "eu-central-1", data.aws_region.current.name == "eu-north-1", data.aws_region.current.name == "eu-south-1", data.aws_region.current.name == "eu-west-1", data.aws_region.current.name == "eu-west-2", data.aws_region.current.name == "eu-west-3", data.aws_region.current.name == "il-central-1", data.aws_region.current.name == "me-central-1", data.aws_region.current.name == "me-south-1", data.aws_region.current.name == "sa-east-1"]), anytrue([data.aws_region.current.name == "us-east-1", data.aws_region.current.name == "us-east-2", data.aws_region.current.name == "us-west-1", data.aws_region.current.name == "us-west-2"])])
  stack_name             = "instance-scheduler"
  stack_id               = uuidv5("dns", "instance-scheduler")
}