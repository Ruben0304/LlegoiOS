// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

public extension LlegoAPI {
  enum AiChatErrorCode: String, EnumType {
    case aiMessageTooLong = "AI_MESSAGE_TOO_LONG"
    case aiDeviceIdRequired = "AI_DEVICE_ID_REQUIRED"
    case aiDailyDeviceQuotaExceeded = "AI_DAILY_DEVICE_QUOTA_EXCEEDED"
    case aiQuotaExceeded = "AI_QUOTA_EXCEEDED"
    case aiFreeQuotaExceeded = "AI_FREE_QUOTA_EXCEEDED"
    case aiServiceError = "AI_SERVICE_ERROR"
    case aiRateLimitExceeded = "AI_RATE_LIMIT_EXCEEDED"
    case aiInvalidRequest = "AI_INVALID_REQUEST"
    case aiInternalError = "AI_INTERNAL_ERROR"
  }

}