import SwiftUI
import MapKit

struct AddressFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var label: String = ""
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var reference: String = ""
    @State private var addressType: String = LlegoAPI.AddressTypeEnum.house.rawValue
    @State private var buildingName: String = ""
    @State private var floor: String = ""
    @State private var apartment: String = ""
    @State private var deliveryInstructions: String = ""
    @State private var isDefault: Bool = false
    @State private var isSaving: Bool = false
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    let onSave: (LlegoAPI.SavedAddressInput, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información Principal")) {
                    TextField("Etiqueta (ej. Casa, Trabajo)", text: $label)
                    TextField("Calle y número", text: $street)
                    TextField("Ciudad", text: $city)
                    TextField("Referencia (ej. Cerca del parque)", text: $reference)
                }

                Section(header: Text("Detalles del Edificio")) {
                    Picker("Tipo de Propiedad", selection: $addressType) {
                        Text("Casa").tag(LlegoAPI.AddressTypeEnum.house.rawValue)
                        Text("Edificio").tag(LlegoAPI.AddressTypeEnum.apartment.rawValue)
                        Text("Oficina").tag(LlegoAPI.AddressTypeEnum.office.rawValue)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if addressType != LlegoAPI.AddressTypeEnum.house.rawValue {
                        TextField("Nombre del Edificio", text: $buildingName)
                        TextField("Piso", text: $floor)
                        TextField("Apartamento", text: $apartment)
                    }
                }

                Section(header: Text("Instrucciones de Entrega")) {
                    TextEditor(text: $deliveryInstructions)
                        .frame(height: 80)
                }

                Section(header: Text("Ubicación en el Mapa")) {
                    VStack(alignment: .leading, spacing: 8) {
                        MapReader { proxy in
                            Map(position: $mapPosition) {
                                if let coordinate = selectedCoordinate {
                                    Annotation("", coordinate: coordinate) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 34))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .mapStyle(.standard(pointsOfInterest: .excludingAll))
                            .onTapGesture { position in
                                if let coordinate = proxy.convert(position, from: .local) {
                                    selectedCoordinate = coordinate
                                    region.center = coordinate
                                }
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(12)

                        Text("Toca el mapa para seleccionar la ubicación exacta")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Toggle("Convertir en dirección por defecto", isOn: $isDefault)
                }
            }
            .navigationTitle("Nueva Dirección")
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() },
                trailing: Button("Guardar") {
                    let input = LlegoAPI.SavedAddressInput(
                        label: label.isEmpty ? "Nueva Dirección" : label,
                        street: street,
                        latitude: region.center.latitude,
                        longitude: region.center.longitude,
                        city: city.isEmpty ? .none : .some(city),
                        reference: reference.isEmpty ? .none : .some(reference),
                        addressType: (LlegoAPI.AddressTypeEnum(rawValue: addressType) ?? .other).rawValue,
                        buildingName: buildingName.isEmpty ? .none : .some(buildingName),
                        floor: floor.isEmpty ? .none : .some(floor),
                        apartment: apartment.isEmpty ? .none : .some(apartment),
                        deliveryInstructions: deliveryInstructions.isEmpty ? .none : .some(deliveryInstructions),
                        setAsDefault: isDefault
                    )
                    onSave(input, isDefault)
                    dismiss()
                }
                .disabled(street.isEmpty)
            )
        }
    }
}
