// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct UpdateSavedAddressInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      addressId: String,
      label: GraphQLNullable<String> = nil,
      street: GraphQLNullable<String> = nil,
      latitude: GraphQLNullable<Double> = nil,
      longitude: GraphQLNullable<Double> = nil,
      city: GraphQLNullable<String> = nil,
      reference: GraphQLNullable<String> = nil,
      addressType: GraphQLNullable<String> = nil,
      buildingName: GraphQLNullable<String> = nil,
      floor: GraphQLNullable<String> = nil,
      apartment: GraphQLNullable<String> = nil,
      deliveryInstructions: GraphQLNullable<String> = nil,
      setAsDefault: GraphQLNullable<Bool> = nil
    ) {
      __data = InputDict([
        "addressId": addressId,
        "label": label,
        "street": street,
        "latitude": latitude,
        "longitude": longitude,
        "city": city,
        "reference": reference,
        "addressType": addressType,
        "buildingName": buildingName,
        "floor": floor,
        "apartment": apartment,
        "deliveryInstructions": deliveryInstructions,
        "setAsDefault": setAsDefault
      ])
    }

    public var addressId: String {
      get { __data["addressId"] }
      set { __data["addressId"] = newValue }
    }

    public var label: GraphQLNullable<String> {
      get { __data["label"] }
      set { __data["label"] = newValue }
    }

    public var street: GraphQLNullable<String> {
      get { __data["street"] }
      set { __data["street"] = newValue }
    }

    public var latitude: GraphQLNullable<Double> {
      get { __data["latitude"] }
      set { __data["latitude"] = newValue }
    }

    public var longitude: GraphQLNullable<Double> {
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

    public var addressType: GraphQLNullable<String> {
      get { __data["addressType"] }
      set { __data["addressType"] = newValue }
    }

    public var buildingName: GraphQLNullable<String> {
      get { __data["buildingName"] }
      set { __data["buildingName"] = newValue }
    }

    public var floor: GraphQLNullable<String> {
      get { __data["floor"] }
      set { __data["floor"] = newValue }
    }

    public var apartment: GraphQLNullable<String> {
      get { __data["apartment"] }
      set { __data["apartment"] = newValue }
    }

    public var deliveryInstructions: GraphQLNullable<String> {
      get { __data["deliveryInstructions"] }
      set { __data["deliveryInstructions"] = newValue }
    }

    public var setAsDefault: GraphQLNullable<Bool> {
      get { __data["setAsDefault"] }
      set { __data["setAsDefault"] = newValue }
    }
  }

}