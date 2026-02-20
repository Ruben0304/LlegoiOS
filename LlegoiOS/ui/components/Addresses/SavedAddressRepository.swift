import Foundation
import Apollo
import Combine

class SavedAddressRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func addSavedAddress(jwt: String, input: LlegoAPI.SavedAddressInput) async throws -> [SavedAddress] {
        let mutation = LlegoAPI.AddSavedAddressMutation(input: input, jwt: jwt)
        let graphQLResult = try await apolloClient.perform(mutation: mutation)

        if let errors = graphQLResult.errors {
            throw graphQLError(message: errors.first?.localizedDescription ?? "Error desconocido")
        }

        guard let data = graphQLResult.data?.addSavedAddress else {
            throw graphQLError(code: -2, message: "No se recibió respuesta")
        }

        let addresses = data.savedAddresses.map { mapSavedAddress($0) }
        await updateCurrentUser(savedAddresses: addresses, defaultAddressId: data.defaultAddressId)
        return addresses
    }

    func updateSavedAddress(jwt: String, id: String, input: LlegoAPI.UpdateSavedAddressInput) async throws -> [SavedAddress] {
        _ = id
        let mutation = LlegoAPI.UpdateSavedAddressMutation(input: input, jwt: jwt)
        let graphQLResult = try await apolloClient.perform(mutation: mutation)

        if let errors = graphQLResult.errors {
            throw graphQLError(message: errors.first?.localizedDescription ?? "Error desconocido")
        }

        guard let data = graphQLResult.data?.updateSavedAddress else {
            throw graphQLError(code: -2, message: "No se recibió respuesta")
        }

        let addresses = data.savedAddresses.map { mapSavedAddress($0) }
        await updateCurrentUser(savedAddresses: addresses, defaultAddressId: data.defaultAddressId)
        return addresses
    }

    func removeSavedAddress(jwt: String, id: String) async throws -> [SavedAddress] {
        let mutation = LlegoAPI.RemoveSavedAddressMutation(addressId: id, jwt: jwt)
        let graphQLResult = try await apolloClient.perform(mutation: mutation)

        if let errors = graphQLResult.errors {
            throw graphQLError(message: errors.first?.localizedDescription ?? "Error desconocido")
        }

        guard let data = graphQLResult.data?.removeSavedAddress else {
            throw graphQLError(code: -2, message: "No se recibió respuesta")
        }

        let addresses = data.savedAddresses.map { mapSavedAddress($0) }
        await updateCurrentUser(savedAddresses: addresses, defaultAddressId: data.defaultAddressId)
        return addresses
    }

    func setDefaultAddress(jwt: String, id: String) async throws -> [SavedAddress] {
        let mutation = LlegoAPI.SetDefaultAddressMutation(addressId: id, jwt: jwt)
        let graphQLResult = try await apolloClient.perform(mutation: mutation)

        if let errors = graphQLResult.errors {
            throw graphQLError(message: errors.first?.localizedDescription ?? "Error desconocido")
        }

        guard let data = graphQLResult.data?.setDefaultAddress else {
            throw graphQLError(code: -2, message: "No se recibió respuesta")
        }

        let currentAddresses = await MainActor.run { AuthManager.shared.currentUser?.savedAddresses ?? [] }
        await updateCurrentUser(savedAddresses: currentAddresses, defaultAddressId: data.defaultAddressId)
        return currentAddresses
    }

    private func mapSavedAddress(_ addr: LlegoAPI.AddSavedAddressMutation.Data.AddSavedAddress.SavedAddress) -> SavedAddress {
        SavedAddress(
            id: addr.id,
            label: addr.label,
            street: addr.street,
            city: addr.city,
            reference: addr.reference,
            addressType: addr.addressType,
            buildingName: addr.buildingName,
            floor: addr.floor,
            apartment: addr.apartment,
            deliveryInstructions: addr.deliveryInstructions,
            latitude: addr.latitude,
            longitude: addr.longitude
        )
    }

    private func mapSavedAddress(_ addr: LlegoAPI.UpdateSavedAddressMutation.Data.UpdateSavedAddress.SavedAddress) -> SavedAddress {
        SavedAddress(
            id: addr.id,
            label: addr.label,
            street: addr.street,
            city: addr.city,
            reference: addr.reference,
            addressType: addr.addressType,
            buildingName: addr.buildingName,
            floor: addr.floor,
            apartment: addr.apartment,
            deliveryInstructions: addr.deliveryInstructions,
            latitude: addr.latitude,
            longitude: addr.longitude
        )
    }

    private func mapSavedAddress(_ addr: LlegoAPI.RemoveSavedAddressMutation.Data.RemoveSavedAddress.SavedAddress) -> SavedAddress {
        SavedAddress(
            id: addr.id,
            label: addr.label,
            street: addr.street,
            city: addr.city,
            reference: addr.reference,
            addressType: addr.addressType,
            buildingName: addr.buildingName,
            floor: addr.floor,
            apartment: addr.apartment,
            deliveryInstructions: addr.deliveryInstructions,
            latitude: addr.latitude,
            longitude: addr.longitude
        )
    }

    private func updateCurrentUser(savedAddresses: [SavedAddress], defaultAddressId: String?) async {
        await MainActor.run {
            guard let user = AuthManager.shared.currentUser else {
                return
            }

            let updatedUser = User(
                id: user.id,
                email: user.email,
                fullName: user.fullName,
                username: user.username,
                phone: user.phone,
                role: user.role,
                appleUserId: user.appleUserId,
                avatar: user.avatar,
                avatarUrl: user.avatarUrl,
                savedAddresses: savedAddresses,
                defaultAddressId: defaultAddressId
            )
            AuthManager.shared.applyCurrentUser(updatedUser)
        }
    }

    private func graphQLError(code: Int = -1, message: String) -> NSError {
        NSError(
            domain: "GraphQL",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
