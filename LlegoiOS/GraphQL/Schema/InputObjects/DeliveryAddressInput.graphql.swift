// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct DeliveryAddressInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      street: String,
      latitude: Double,
      longitude: Double,
      city: GraphQLNullable<String> = nil,
      reference: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "street": street,
        "latitude": latitude,
        "longitude": longitude,
        "city": city,
        "reference": reference
      ])
    }

    public var street: String {
      get { __data["street"] }
      set { __data["street"] = newValue }
    }

    public var latitude: Double {
      get { __data["latitude"] }
      set { __data["latitude"] = newValue }
    }

    public var longitude: Double {
      get { __data["longitude"] }
      set { __data["longitude"] = newValue }
    }

    public var city: GraphQLNullable<String> {
      get { __data["city"] }
      set { __data["city"] = newValue }
    }

    public var reference: GraphQLNullable<String> {
      get { __data["reference"] }
      set { __data["reference"] = newValue }
    }
  }

}