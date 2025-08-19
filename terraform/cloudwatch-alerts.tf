# ============================================================================
# PRODUCTION-ONLY ALERTING CONFIGURATION
# Alerts are only created when environment = "production"
# ============================================================================

# SNS Topic for CloudWatch Alarms (Production Only)
resource "aws_sns_topic" "alerts" {
  count = var.environment == "production" ? 1 : 0
  
  name = "${var.app_name}-${var.environment}-alerts"
  
  tags = {
    Name        = "${var.app_name}-${var.environment}-alerts"
    Environment = var.environment
  }
}

# CloudWatch Alarms (Production Only)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-high-cpu-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-high-memory-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ALB target response time"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-high-response-time-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-rds-high-cpu-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"  # Adjust based on your RDS instance capacity
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-rds-high-connections-alarm"
    Environment = var.environment
  }
}

# ============================================================================
# ENHANCED ERROR LOGGING AND MONITORING
# ============================================================================

# 1. General Application Errors (Works with standard Java logging)
resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  count = var.environment == "production" ? 1 : 0
  
  name           = "${var.app_name}-${var.environment}-error-filter"
  log_group_name = aws_cloudwatch_log_group.main.name
  pattern        = "ERROR"  # Simple pattern - works with any log format containing "ERROR"

  metric_transformation {
    name      = "${var.app_name}-${var.environment}-error-count"
    namespace = "Cabinet/Application"
    value     = "1"
  }
}

# 2. Critical Errors (Works with standard Java logging)
resource "aws_cloudwatch_log_metric_filter" "critical_error_filter" {
  count = var.environment == "production" ? 1 : 0
  
  name           = "${var.app_name}-${var.environment}-critical-error-filter"
  log_group_name = aws_cloudwatch_log_group.main.name
  pattern        = "?FATAL ?CRITICAL"  # Matches logs containing "FATAL" OR "CRITICAL"

  metric_transformation {
    name      = "${var.app_name}-${var.environment}-critical-error-count"
    namespace = "Cabinet/Application"
    value     = "1"
  }
}

# 3. Database Connection Errors (Works with standard Java logging)
resource "aws_cloudwatch_log_metric_filter" "db_error_filter" {
  count = var.environment == "production" ? 1 : 0
  
  name           = "${var.app_name}-${var.environment}-db-error-filter"
  log_group_name = aws_cloudwatch_log_group.main.name
  pattern        = "ERROR ?database ?connection ?SQLException ?SQL"  # Matches ERROR logs with DB-related keywords

  metric_transformation {
    name      = "${var.app_name}-${var.environment}-db-error-count"
    namespace = "Cabinet/Database"
    value     = "1"
  }
}

# 4. HTTP 5xx Server Errors (Works with standard Java logging)
resource "aws_cloudwatch_log_metric_filter" "http_5xx_filter" {
  count = var.environment == "production" ? 1 : 0
  
  name           = "${var.app_name}-${var.environment}-http-5xx-filter"
  log_group_name = aws_cloudwatch_log_group.main.name
  pattern        = "ERROR ?500 ?502 ?503 ?504 ?\"Internal Server Error\" ?Exception"  # Matches common 5xx error patterns

  metric_transformation {
    name      = "${var.app_name}-${var.environment}-http-5xx-count"
    namespace = "Cabinet/HTTP"
    value     = "1"
  }
}

# 5. Authentication/Authorization Errors (Works with standard Java logging)
resource "aws_cloudwatch_log_metric_filter" "auth_error_filter" {
  count = var.environment == "production" ? 1 : 0
  
  name           = "${var.app_name}-${var.environment}-auth-error-filter"
  log_group_name = aws_cloudwatch_log_group.main.name
  pattern        = "ERROR ?authentication ?authorization ?unauthorized ?forbidden ?\"Access denied\" ?login"  # Matches auth-related errors

  metric_transformation {
    name      = "${var.app_name}-${var.environment}-auth-error-count"
    namespace = "Cabinet/Security"
    value     = "1"
  }
}

# 6. BLE/IoT Device Communication Errors (Works with standard Java logging)
resource "aws_cloudwatch_log_metric_filter" "iot_error_filter" {
  count = var.environment == "production" ? 1 : 0
  
  name           = "${var.app_name}-${var.environment}-iot-error-filter"
  log_group_name = aws_cloudwatch_log_group.main.name
  pattern        = "ERROR ?bluetooth ?device ?provision ?BLE ?\"device communication\" ?\"connection failed\""  # Matches IoT-related errors

  metric_transformation {
    name      = "${var.app_name}-${var.environment}-iot-error-count"
    namespace = "Cabinet/IoT"
    value     = "1"
  }
}

# 7. Java Exception Stack Traces (Works with standard Java logging)
resource "aws_cloudwatch_log_metric_filter" "exception_filter" {
  count = var.environment == "production" ? 1 : 0
  
  name           = "${var.app_name}-${var.environment}-exception-filter"
  log_group_name = aws_cloudwatch_log_group.main.name
  pattern        = "Exception ?\"at \" ?\"Caused by\" ?RuntimeException ?NullPointerException"  # Matches Java exceptions and stack traces

  metric_transformation {
    name      = "${var.app_name}-${var.environment}-exception-count"
    namespace = "Cabinet/Exceptions"
    value     = "1"
    default_value = "0"
  }
}

# ============================================================================
# ENHANCED ERROR ALARMS
# ============================================================================

# General Application Errors Alarm (Enhanced)
resource "aws_cloudwatch_metric_alarm" "application_errors" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-application-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.app_name}-${var.environment}-error-count"
  namespace           = "Cabinet/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors application errors in logs"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.app_name}-${var.environment}-application-errors-alarm"
    Environment = var.environment
  }
}

# Critical Errors Alarm (Immediate notification)
resource "aws_cloudwatch_metric_alarm" "critical_errors" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-critical-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.app_name}-${var.environment}-critical-error-count"
  namespace           = "Cabinet/Application"
  period              = "60"   # Check every minute for critical errors
  statistic           = "Sum"
  threshold           = "0"    # Any critical error should alert immediately
  alarm_description   = "CRITICAL: Fatal or critical errors detected"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.app_name}-${var.environment}-critical-errors-alarm"
    Environment = var.environment
  }
}

# Database Error Alarm
resource "aws_cloudwatch_metric_alarm" "database_errors" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-database-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.app_name}-${var.environment}-db-error-count"
  namespace           = "Cabinet/Database"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Database connection or query errors detected"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.app_name}-${var.environment}-database-errors-alarm"
    Environment = var.environment
  }
}

# HTTP 5xx Errors Alarm
resource "aws_cloudwatch_metric_alarm" "http_5xx_errors" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-http-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "${var.app_name}-${var.environment}-http-5xx-count"
  namespace           = "Cabinet/HTTP"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High number of HTTP 5xx server errors"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.app_name}-${var.environment}-http-5xx-errors-alarm"
    Environment = var.environment
  }
}

# Security/Authentication Errors Alarm
resource "aws_cloudwatch_metric_alarm" "auth_errors" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-auth-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.app_name}-${var.environment}-auth-error-count"
  namespace           = "Cabinet/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Authentication or authorization errors detected"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.app_name}-${var.environment}-auth-errors-alarm"
    Environment = var.environment
  }
}

# IoT Device Communication Errors Alarm
resource "aws_cloudwatch_metric_alarm" "iot_errors" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-iot-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.app_name}-${var.environment}-iot-error-count"
  namespace           = "Cabinet/IoT"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "IoT device communication errors detected"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.app_name}-${var.environment}-iot-errors-alarm"
    Environment = var.environment
  }
}

# Error Rate Alarm (Percentage of requests that result in errors)
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${var.app_name}-${var.environment}-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  
  # This is a math expression alarm
  metric_query {
    id = "e1"
    expression = "m2/m1*100"
    label = "Error Rate"
    return_data = true
  }
  
  metric_query {
    id = "m1"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
      }
    }
  }
  
  metric_query {
    id = "m2"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB" 
      period      = 300
      stat        = "Sum"
      
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
      }
    }
  }

  threshold           = "5"  # 5% error rate
  alarm_description   = "Error rate is above 5%"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.app_name}-${var.environment}-error-rate-alarm"
    Environment = var.environment
  }
}

# AWS Chatbot for Slack integration
resource "aws_chatbot_slack_channel_configuration" "alerts" {
  count = var.environment == "production" ? 1 : 0
  
  configuration_name = "${var.app_name}-${var.environment}-slack-alerts"
  iam_role_arn       = aws_iam_role.chatbot_role[0].arn
  slack_channel_id   = var.slack_channel_id
  slack_team_id      = var.slack_team_id
  sns_topic_arns     = [aws_sns_topic.alerts[0].arn]

  tags = {
    Name        = "${var.app_name}-${var.environment}-chatbot"
    Environment = var.environment
  }
}

# IAM role for AWS Chatbot
resource "aws_iam_role" "chatbot_role" {
  count = var.environment == "production" ? 1 : 0
  
  name = "${var.app_name}-${var.environment}-chatbot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-chatbot-role"
    Environment = var.environment
  }
}

# IAM policy for AWS Chatbot
resource "aws_iam_role_policy" "chatbot_policy" {
  count = var.environment == "production" ? 1 : 0
  
  name = "${var.app_name}-${var.environment}-chatbot-policy"
  role = aws_iam_role.chatbot_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Resource = "*"
      }
    ]
  })
}