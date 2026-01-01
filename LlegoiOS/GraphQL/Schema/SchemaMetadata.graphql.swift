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
      case "AiAssistantOutputType": return LlegoAPI.Objects.AiAssistantOutputType
      case "AiAssistantResponseType": return LlegoAPI.Objects.AiAssistantResponseType
      case "AuthResponse": return LlegoAPI.Objects.AuthResponse
      case "BranchType": return LlegoAPI.Objects.BranchType
      case "BusinessType": return LlegoAPI.Objects.BusinessType
      case "CoordinatesType": return LlegoAPI.Objects.CoordinatesType
      case "Mutation": return LlegoAPI.Objects.Mutation
      case "PaymentMethodType": return LlegoAPI.Objects.PaymentMethodType
      case "ProductType": return LlegoAPI.Objects.ProductType
      case "Query": return LlegoAPI.Objects.Query
      case "UserData": return LlegoAPI.Objects.UserData
      case "UserType": return LlegoAPI.Objects.UserType
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}