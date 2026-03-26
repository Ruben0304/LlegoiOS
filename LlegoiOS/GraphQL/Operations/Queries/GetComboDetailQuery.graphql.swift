// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetComboDetailQuery: GraphQLQuery {
    public static let operationName: String = "GetComboDetail"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetComboDetail($comboId: String!) { combo(comboId: $comboId) { __typename id branchId name description imageUrl currency availability discountType discountValue finalPrice savings startingFinalPrice startingSavings representativeProducts { __typename id name imageUrl } slots { __typename id name description minSelections maxSelections isFree displayOrder options { __typename productId isDefault priceAdjustment product { __typename id name imageUrl price currency } availableModifiers { __typename name priceAdjustment } } } giftOptions { __typename productId product { __typename id name imageUrl } } branch { __typename id name avatarUrl } createdAt } }"#
      ))

    public var comboId: String

    public init(comboId: String) {
      self.comboId = comboId
    }

    @_spi(Unsafe) public var __variables: Variables? { ["comboId": comboId] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("combo", Combo?.self, arguments: ["comboId": .variable("comboId")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetComboDetailQuery.Data.self
      ] }

      /// Obtener un combo por ID
      public var combo: Combo? { __data["combo"] }

      /// Combo
      ///
      /// Parent Type: `ComboType`
      public struct Combo: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ComboType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("branchId", String.self),
          .field("name", String.self),
          .field("description", String.self),
          .field("imageUrl", String?.self),
          .field("currency", String.self),
          .field("availability", Bool.self),
          .field("discountType", GraphQLEnum<LlegoAPI.DiscountType>.self),
          .field("discountValue", Double.self),
          .field("finalPrice", Double.self),
          .field("savings", Double.self),
          .field("startingFinalPrice", Double.self),
          .field("startingSavings", Double.self),
          .field("representativeProducts", [RepresentativeProduct].self),
          .field("slots", [Slot].self),
          .field("giftOptions", [GiftOption].self),
          .field("branch", Branch?.self),
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetComboDetailQuery.Data.Combo.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        /// Presigned URL for combo image (optional)
        public var imageUrl: String? { __data["imageUrl"] }
        public var currency: String { __data["currency"] }
        public var availability: Bool { __data["availability"] }
        public var discountType: GraphQLEnum<LlegoAPI.DiscountType> { __data["discountType"] }
        public var discountValue: Double { __data["discountValue"] }
        /// Final price with discount applied
        public var finalPrice: Double { __data["finalPrice"] }
        /// Amount saved with discount
        public var savings: Double { __data["savings"] }
        /// Minimum valid final price after discount (for catalog 'From $X' display)
        public var startingFinalPrice: Double { __data["startingFinalPrice"] }
        /// Minimum savings amount (minimum base total - startingFinalPrice)
        public var startingSavings: Double { __data["startingSavings"] }
        /// Representative products for frontend composition (max 4 products)
        public var representativeProducts: [RepresentativeProduct] { __data["representativeProducts"] }
        public var slots: [Slot] { __data["slots"] }
        public var giftOptions: [GiftOption] { __data["giftOptions"] }
        /// Branch associated with this combo
        public var branch: Branch? { __data["branch"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }

        /// Combo.RepresentativeProduct
        ///
        /// Parent Type: `ProductType`
        public struct RepresentativeProduct: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("imageUrl", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetComboDetailQuery.Data.Combo.RepresentativeProduct.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          /// Presigned URL for the product image
          public var imageUrl: String { __data["imageUrl"] }
        }

        /// Combo.Slot
        ///
        /// Parent Type: `ComboSlotType`
        public struct Slot: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ComboSlotType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("description", String?.self),
            .field("minSelections", Int.self),
            .field("maxSelections", Int.self),
            .field("isFree", Bool.self),
            .field("displayOrder", Int.self),
            .field("options", [Option].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetComboDetailQuery.Data.Combo.Slot.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          public var description: String? { __data["description"] }
          public var minSelections: Int { __data["minSelections"] }
          public var maxSelections: Int { __data["maxSelections"] }
          public var isFree: Bool { __data["isFree"] }
          public var displayOrder: Int { __data["displayOrder"] }
          public var options: [Option] { __data["options"] }

          /// Combo.Slot.Option
          ///
          /// Parent Type: `ComboOptionType`
          public struct Option: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ComboOptionType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("productId", String.self),
              .field("isDefault", Bool.self),
              .field("priceAdjustment", Double.self),
              .field("product", Product?.self),
              .field("availableModifiers", [AvailableModifier].self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetComboDetailQuery.Data.Combo.Slot.Option.self
            ] }

            public var productId: String { __data["productId"] }
            public var isDefault: Bool { __data["isDefault"] }
            public var priceAdjustment: Double { __data["priceAdjustment"] }
            /// Product details
            public var product: Product? { __data["product"] }
            public var availableModifiers: [AvailableModifier] { __data["availableModifiers"] }

            /// Combo.Slot.Option.Product
            ///
            /// Parent Type: `ProductType`
            public struct Product: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", String.self),
                .field("name", String.self),
                .field("imageUrl", String.self),
                .field("price", Double.self),
                .field("currency", String.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetComboDetailQuery.Data.Combo.Slot.Option.Product.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              /// Presigned URL for the product image
              public var imageUrl: String { __data["imageUrl"] }
              public var price: Double { __data["price"] }
              public var currency: String { __data["currency"] }
            }

            /// Combo.Slot.Option.AvailableModifier
            ///
            /// Parent Type: `ComboModifierType`
            public struct AvailableModifier: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ComboModifierType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("name", String.self),
                .field("priceAdjustment", Double.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetComboDetailQuery.Data.Combo.Slot.Option.AvailableModifier.self
              ] }

              public var name: String { __data["name"] }
              public var priceAdjustment: Double { __data["priceAdjustment"] }
            }
          }
        }

        /// Combo.GiftOption
        ///
        /// Parent Type: `ComboGiftOptionType`
        public struct GiftOption: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ComboGiftOptionType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("productId", String.self),
            .field("product", Product?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetComboDetailQuery.Data.Combo.GiftOption.self
          ] }

          public var productId: String { __data["productId"] }
          /// Gift product details
          public var product: Product? { __data["product"] }

          /// Combo.GiftOption.Product
          ///
          /// Parent Type: `ProductType`
          public struct Product: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
              .field("name", String.self),
              .field("imageUrl", String.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetComboDetailQuery.Data.Combo.GiftOption.Product.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            /// Presigned URL for the product image
            public var imageUrl: String { __data["imageUrl"] }
          }
        }

        /// Combo.Branch
        ///
        /// Parent Type: `BranchType`
        public struct Branch: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("avatarUrl", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetComboDetailQuery.Data.Combo.Branch.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          /// Presigned URL for the branch avatar (inherits from business if not set)
          public var avatarUrl: String? { __data["avatarUrl"] }
        }
      }
    }
  }

}