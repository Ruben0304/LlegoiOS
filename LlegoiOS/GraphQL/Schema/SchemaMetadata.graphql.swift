// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol LlegoAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == LlegoAPI.SchemaMetadata {}

public protocol LlegoAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == LlegoAPI.SchemaMetadata {}

public protocol LlegoAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == LlegoAPI.SchemaMetadata {}

public protocol LlegoAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == LlegoAPI.SchemaMetadata {}

public extension LlegoAPI {
  typealias SelectionSet = LlegoAPI_SelectionSet

  typealias InlineFragment = LlegoAPI_InlineFragment

  typealias MutableSelectionSet = LlegoAPI_MutableSelectionSet

  typealias MutableInlineFragment = LlegoAPI_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    @_spi(Execution) public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "AiAssistantResponseType": return LlegoAPI.Objects.AiAssistantResponseType
      case "AiChatError": return LlegoAPI.Objects.AiChatError
      case "AiChatQuotaInfo": return LlegoAPI.Objects.AiChatQuotaInfo
      case "AiChatResult": return LlegoAPI.Objects.AiChatResult
      case "AiChatStreamChunk": return LlegoAPI.Objects.AiChatStreamChunk
      case "AppConfigType": return LlegoAPI.Objects.AppConfigType
      case "AuthResponse": return LlegoAPI.Objects.AuthResponse
      case "BranchConnection": return LlegoAPI.Objects.BranchConnection
      case "BranchEdge": return LlegoAPI.Objects.BranchEdge
      case "BranchLikeType": return LlegoAPI.Objects.BranchLikeType
      case "BranchSuggestionType": return LlegoAPI.Objects.BranchSuggestionType
      case "BranchSyncType": return LlegoAPI.Objects.BranchSyncType
      case "BranchType": return LlegoAPI.Objects.BranchType
      case "BusinessSyncType": return LlegoAPI.Objects.BusinessSyncType
      case "BusinessType": return LlegoAPI.Objects.BusinessType
      case "BusinessTypeConfigType": return LlegoAPI.Objects.BusinessTypeConfigType
      case "CameraConfigType": return LlegoAPI.Objects.CameraConfigType
      case "ComboModifierType": return LlegoAPI.Objects.ComboModifierType
      case "ComboOptionType": return LlegoAPI.Objects.ComboOptionType
      case "ComboSlotType": return LlegoAPI.Objects.ComboSlotType
      case "ComboType": return LlegoAPI.Objects.ComboType
      case "CoordinatesSyncType": return LlegoAPI.Objects.CoordinatesSyncType
      case "CoordinatesType": return LlegoAPI.Objects.CoordinatesType
      case "DeliveryAddressType": return LlegoAPI.Objects.DeliveryAddressType
      case "DeliveryFeeEstimateType": return LlegoAPI.Objects.DeliveryFeeEstimateType
      case "DeliveryPersonType": return LlegoAPI.Objects.DeliveryPersonType
      case "DeviceTokenType": return LlegoAPI.Objects.DeviceTokenType
      case "FavoriteCartType": return LlegoAPI.Objects.FavoriteCartType
      case "FeatureType": return LlegoAPI.Objects.FeatureType
      case "FeedProductType": return LlegoAPI.Objects.FeedProductType
      case "FeedResponse": return LlegoAPI.Objects.FeedResponse
      case "FeedSection": return LlegoAPI.Objects.FeedSection
      case "FeedSectionDiagnostic": return LlegoAPI.Objects.FeedSectionDiagnostic
      case "GradientConfigType": return LlegoAPI.Objects.GradientConfigType
      case "ImageSyncType": return LlegoAPI.Objects.ImageSyncType
      case "ImageUrlType": return LlegoAPI.Objects.ImageUrlType
      case "InitiatePaymentResult": return LlegoAPI.Objects.InitiatePaymentResult
      case "IosConfigType": return LlegoAPI.Objects.IosConfigType
      case "MaintenanceConfigType": return LlegoAPI.Objects.MaintenanceConfigType
      case "Mutation": return LlegoAPI.Objects.Mutation
      case "OrderCommentType": return LlegoAPI.Objects.OrderCommentType
      case "OrderDiscountType": return LlegoAPI.Objects.OrderDiscountType
      case "OrderItemType": return LlegoAPI.Objects.OrderItemType
      case "OrderTimelineType": return LlegoAPI.Objects.OrderTimelineType
      case "OrderTrackingType": return LlegoAPI.Objects.OrderTrackingType
      case "OrderType": return LlegoAPI.Objects.OrderType
      case "OrdersConnectionType": return LlegoAPI.Objects.OrdersConnectionType
      case "PageInfo": return LlegoAPI.Objects.PageInfo
      case "PaymentAttemptType": return LlegoAPI.Objects.PaymentAttemptType
      case "PaymentMethodType": return LlegoAPI.Objects.PaymentMethodType
      case "ProductCategoryType": return LlegoAPI.Objects.ProductCategoryType
      case "ProductConnection": return LlegoAPI.Objects.ProductConnection
      case "ProductEdge": return LlegoAPI.Objects.ProductEdge
      case "ProductRecommendationType": return LlegoAPI.Objects.ProductRecommendationType
      case "ProductRecommendationsResponseType": return LlegoAPI.Objects.ProductRecommendationsResponseType
      case "ProductSuggestionType": return LlegoAPI.Objects.ProductSuggestionType
      case "ProductSyncType": return LlegoAPI.Objects.ProductSyncType
      case "ProductType": return LlegoAPI.Objects.ProductType
      case "Query": return LlegoAPI.Objects.Query
      case "QvaPayPaymentResult": return LlegoAPI.Objects.QvaPayPaymentResult
      case "SavedAddressType": return LlegoAPI.Objects.SavedAddressType
      case "ScoredBranchType": return LlegoAPI.Objects.ScoredBranchType
      case "ScoredProductType": return LlegoAPI.Objects.ScoredProductType
      case "Subscription": return LlegoAPI.Objects.Subscription
      case "TronDealerPaymentResult": return LlegoAPI.Objects.TronDealerPaymentResult
      case "TutorialType": return LlegoAPI.Objects.TutorialType
      case "UserData": return LlegoAPI.Objects.UserData
      case "UserType": return LlegoAPI.Objects.UserType
      case "VariantListType": return LlegoAPI.Objects.VariantListType
      case "VariantOptionType": return LlegoAPI.Objects.VariantOptionType
      case "WalletBalanceType": return LlegoAPI.Objects.WalletBalanceType
      case "WalletTransactionType": return LlegoAPI.Objects.WalletTransactionType
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}