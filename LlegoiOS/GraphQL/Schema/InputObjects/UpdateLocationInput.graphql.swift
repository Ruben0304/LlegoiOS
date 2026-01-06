// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct UpdateLocationInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      longitude: Double,
      latitude: Double
    ) {
      __data = InputDict([
        "longitude": longitude,
        "latitude": latitude
      ])
    }

    public var longitude: Double {
      get { __data["longitude"] }
      set { __data["longitude"] = newValue }
    }

    public var latitude: Double {
      get { __data["latitude"] }
      set { __data["latitude"] = newValue }
    }
  }

}