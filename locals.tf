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
  ScheduleEC2            = anytrue([var.scheduled_services == "EC2", var.scheduled_services == "Both"])
  ScheduleRDS            = anytrue([var.scheduled_services == "RDS", var.scheduled_services == "Both"])
  stack_name             = "instance-scheduler"
  stack_id               = uuidv5("dns", "instance-scheduler")
}