// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetBranchesQuery: GraphQLQuery {
    public static let operationName: String = "GetBranches"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetBranches($first: Int! = 20, $after: String, $businessId: String, $tipo: BranchTipo, $radiusKm: Float, $productCategoryId: String, $jwt: String, $productsLimit: Int = 2) { branches( first: $first after: $after businessId: $businessId tipo: $tipo radiusKm: $radiusKm productCategoryId: $productCategoryId jwt: $jwt ) { __typename edges { __typename node { __typename id businessId name acceptsQvapay acceptsZelle qvapayUsername zelleEmail address coordinates { __typename type coordinates } phone status avatarUrl avatarUrlBaja avatarUrlAlta coverUrl coverUrlBaja coverUrlAlta deliveryRadius schedule { __typename days { __typename day isOpen hours { __typename open close } } temporaryStatus { __typename temporallyClosed temporallyOpen reason } } createdAt score distanceKm products(limit: $productsLimit, availableOnly: false) { __typename id name price currency imageUrlBaja } } cursor } pageInfo { __typename hasNextPage hasPreviousPage startCursor endCursor totalCount } } }"#
      ))

    public var first: Int32
    public var after: GraphQLNullable<String>
    public var businessId: GraphQLNullable<String>
    public var tipo: GraphQLNullable<GraphQLEnum<BranchTipo>>
    public var radiusKm: GraphQLNullable<Double>
    public var productCategoryId: GraphQLNullable<String>
    public var jwt: GraphQLNullable<String>
    public var productsLimit: GraphQLNullable<Int32>

    public init(
      first: Int32 = 20,
      after: GraphQLNullable<String>,
      businessId: GraphQLNullable<String>,
      tipo: GraphQLNullable<GraphQLEnum<BranchTipo>>,
      radiusKm: GraphQLNullable<Double>,
      productCategoryId: GraphQLNullable<String>,
      jwt: GraphQLNullable<String>,
      productsLimit: GraphQLNullable<Int32> = 2
    ) {
      self.first = first
      self.after = after
      self.businessId = businessId
      self.tipo = tipo
      self.radiusKm = radiusKm
      self.productCategoryId = productCategoryId
      self.jwt = jwt
      self.productsLimit = productsLimit
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "first": first,
      "after": after,
      "businessId": businessId,
      "tipo": tipo,
      "radiusKm": radiusKm,
      "productCategoryId": productCategoryId,
      "jwt": jwt,
      "productsLimit": productsLimit
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("branches", Branches.self, arguments: [
          "first": .variable("first"),
          "after": .variable("after"),
          "businessId": .variable("businessId"),
          "tipo": .variable("tipo"),
          "radiusKm": .variable("radiusKm"),
          "productCategoryId": .variable("productCategoryId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetBranchesQuery.Data.self
      ] }

      /// Lista de sucursales con scoring por cercanía (paginado)
      public var branches: Branches { __data["branches"] }

      /// Branches
      ///
      /// Parent Type: `BranchConnection`
      public struct Branches: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchConnection }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
          .field("pageInfo", PageInfo.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetBranchesQuery.Data.Branches.self
        ] }

        public var edges: [Edge] { __data["edges"] }
        public var pageInfo: PageInfo { __data["pageInfo"] }

        /// Branches.Edge
        ///
        /// Parent Type: `BranchEdge`
        public struct Edge: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchEdge }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
            .field("cursor", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetBranchesQuery.Data.Branches.Edge.self
          ] }

          public var node: Node { __data["node"] }
          public var cursor: String { __data["cursor"] }

          /// Branches.Edge.Node
          ///
          /// Parent Type: `ScoredBranchType`
          public struct Node: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ScoredBranchType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
              .field("businessId", String.self),
              .field("name", String.self),
              .field("acceptsQvapay", Bool.self),
              .field("acceptsZelle", Bool.self),
              .field("qvapayUsername", String?.self),
              .field("zelleEmail", String?.self),
              .field("address", String?.self),
              .field("coordinates", Coordinates.self),
              .field("phone", String.self),
              .field("status", String?.self),
              .field("avatarUrl", String?.self),
              .field("avatarUrlBaja", String?.self),
              .field("avatarUrlAlta", String?.self),
              .field("coverUrl", String?.self),
              .field("coverUrlBaja", String?.self),
              .field("coverUrlAlta", String?.self),
              .field("deliveryRadius", Double?.self),
              .field("schedule", Schedule.self),
              .field("createdAt", LlegoAPI.DateTime.self),
              .field("score", Double.self),
              .field("distanceKm", Double?.self),
              .field("products", [Product].self, arguments: [
                "limit": .variable("productsLimit"),
                "availableOnly": false
              ]),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetBranchesQuery.Data.Branches.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var businessId: String { __data["businessId"] }
            public var name: String { __data["name"] }
            public var acceptsQvapay: Bool { __data["acceptsQvapay"] }
            public var acceptsZelle: Bool { __data["acceptsZelle"] }
            public var qvapayUsername: String? { __data["qvapayUsername"] }
            public var zelleEmail: String? { __data["zelleEmail"] }
            public var address: String? { __data["address"] }
            public var coordinates: Coordinates { __data["coordinates"] }
            public var phone: String { __data["phone"] }
            public var status: String? { __data["status"] }
            /// Presigned URL for the branch avatar (inherits from business if not set)
            public var avatarUrl: String? { __data["avatarUrl"] }
            /// Presigned URL for low quality branch avatar (inherits business avatar and falls back to original)
            public var avatarUrlBaja: String? { __data["avatarUrlBaja"] }
            /// Presigned URL for high quality branch avatar (inherits business avatar and falls back to original)
            public var avatarUrlAlta: String? { __data["avatarUrlAlta"] }
            /// Presigned URL for the branch cover image
            public var coverUrl: String? { __data["coverUrl"] }
            /// Presigned URL for low quality branch cover (with fallback to original)
            public var coverUrlBaja: String? { __data["coverUrlBaja"] }
            /// Presigned URL for high quality branch cover (with fallback to original)
            public var coverUrlAlta: String? { __data["coverUrlAlta"] }
            public var deliveryRadius: Double? { __data["deliveryRadius"] }
            public var schedule: Schedule { __data["schedule"] }
            public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
            public var score: Double { __data["score"] }
            /// Distance in kilometers from user
            public var distanceKm: Double? { __data["distanceKm"] }
            /// Products from this branch
            public var products: [Product] { __data["products"] }

            /// Branches.Edge.Node.Schedule
            ///
            /// Parent Type: `BranchScheduleType`
            public struct Schedule: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchScheduleType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("days", [Day].self),
                .field("temporaryStatus", TemporaryStatus?.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetBranchesQuery.Data.Branches.Edge.Node.Schedule.self
              ] }

              public var days: [Day] { __data["days"] }
              public var temporaryStatus: TemporaryStatus? { __data["temporaryStatus"] }

              public struct Day: LlegoAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

                @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.DayScheduleType }
                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                  .field("__typename", String.self),
                  .field("day", Int.self),
                  .field("isOpen", Bool.self),
                  .field("hours", [Hour].self),
                ] }
                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  GetBranchesQuery.Data.Branches.Edge.Node.Schedule.Day.self
                ] }

                public var day: Int { __data["day"] }
                public var isOpen: Bool { __data["isOpen"] }
                public var hours: [Hour] { __data["hours"] }

                public struct Hour: LlegoAPI.SelectionSet {
                  @_spi(Unsafe) public let __data: DataDict
                  @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

                  @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.TimeRangeType }
                  @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("open", String.self),
                    .field("close", String.self),
                  ] }
                  @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                    GetBranchesQuery.Data.Branches.Edge.Node.Schedule.Day.Hour.self
                  ] }

                  public var open: String { __data["open"] }
                  public var close: String { __data["close"] }
                }
              }

              public struct TemporaryStatus: LlegoAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

                @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.TemporaryStatusType }
                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                  .field("__typename", String.self),
                  .field("temporallyClosed", Bool.self),
                  .field("temporallyOpen", Bool.self),
                  .field("reason", String?.self),
                ] }
                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  GetBranchesQuery.Data.Branches.Edge.Node.Schedule.TemporaryStatus.self
                ] }

                public var temporallyClosed: Bool { __data["temporallyClosed"] }
                public var temporallyOpen: Bool { __data["temporallyOpen"] }
                public var reason: String? { __data["reason"] }
              }
            }

            /// Branches.Edge.Node.Coordinates
            ///
            /// Parent Type: `CoordinatesType`
            public struct Coordinates: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("type", String.self),
                .field("coordinates", [Double].self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetBranchesQuery.Data.Branches.Edge.Node.Coordinates.self
              ] }

              public var type: String { __data["type"] }
              public var coordinates: [Double] { __data["coordinates"] }
            }

            /// Branches.Edge.Node.Product
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
                .field("price", Double.self),
                .field("currency", String.self),
                .field("imageUrlBaja", String.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetBranchesQuery.Data.Branches.Edge.Node.Product.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              public var price: Double { __data["price"] }
              public var currency: String { __data["currency"] }
              /// Presigned URL for the low quality product image (720x540)
              public var imageUrlBaja: String { __data["imageUrlBaja"] }
            }
          }
        }

        /// Branches.PageInfo
        ///
        /// Parent Type: `PageInfo`
        public struct PageInfo: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PageInfo }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("hasNextPage", Bool.self),
            .field("hasPreviousPage", Bool.self),
            .field("startCursor", String?.self),
            .field("endCursor", String?.self),
            .field("totalCount", Int.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetBranchesQuery.Data.Branches.PageInfo.self
          ] }

          public var hasNextPage: Bool { __data["hasNextPage"] }
          public var hasPreviousPage: Bool { __data["hasPreviousPage"] }
          public var startCursor: String? { __data["startCursor"] }
          public var endCursor: String? { __data["endCursor"] }
          public var totalCount: Int { __data["totalCount"] }
        }
      }
    }
  }

}