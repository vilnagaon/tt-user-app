import SwiftUI
import MapKit

struct StoreLocatorView: View {
    let stores: [TeatowerStore] = TeatowerStore.all

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Map
                    Map {
                        ForEach(stores) { store in
                            Marker(store.name, coordinate: store.coordinate)
                                .tint(.teatowerGreen)
                        }
                    }
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Store cards
                    ForEach(stores) { store in
                        StoreCard(store: store)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.teatowerBg)
            .navigationTitle("Nos Boutiques")
        }
    }
}

struct StoreCard: View {
    let store: TeatowerStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(store.color)
                    .frame(width: 10, height: 10)
                Text(store.name)
                    .font(.teatowerHeading)
                    .foregroundStyle(.teatowerGreen)
                Spacer()
            }

            Text(store.address)
                .font(.teatowerBody)
                .foregroundStyle(.secondary)

            Text(store.phone)
                .font(.teatowerBody)
                .foregroundStyle(.teatowerGreen)

            // Hours
            VStack(alignment: .leading, spacing: 4) {
                ForEach(store.hours, id: \.day) { h in
                    HStack {
                        Text(h.day)
                            .font(.system(size: 13))
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(h.highlighted ? Color.teatowerBrown : .secondary)
                        Text(h.time)
                            .font(.system(size: 13, weight: h.highlighted ? .bold : .regular))
                            .foregroundColor(h.highlighted ? Color.teatowerBrown : .primary)
                    }
                }
            }

            HStack(spacing: 12) {
                Link(destination: URL(string: "tel:\(store.phone.replacingOccurrences(of: " ", with: ""))")!) {
                    Label("Appeler", systemImage: "phone.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.teatowerGreen)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }

                Link(destination: URL(string: store.mapsURL)!) {
                    Label("Itinéraire", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundStyle(.teatowerGreen)
                        .overlay(Capsule().stroke(Color.teatowerGreen, lineWidth: 1.5))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Store Data

struct TeatowerStore: Identifiable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let coordinate: CLLocationCoordinate2D
    let color: Color
    let mapsURL: String
    let hours: [StoreHours]

    static let all: [TeatowerStore] = [
        TeatowerStore(
            id: "waterloo", name: "Teatower Waterloo",
            address: "Chaussée de Bruxelles 155, 1410 Waterloo",
            phone: "+32 2 720 36 04",
            coordinate: CLLocationCoordinate2D(latitude: 50.7148, longitude: 4.3834),
            color: .storeWaterloo,
            mapsURL: "https://maps.apple.com/?q=Teatower+Waterloo",
            hours: StoreHours.standard
        ),
        TeatowerStore(
            id: "namur", name: "Teatower Namur",
            address: "Rue du Pont 3, 5000 Namur",
            phone: "+32 81 66 30 07",
            coordinate: CLLocationCoordinate2D(latitude: 50.4649, longitude: 4.8621),
            color: .storeNamur,
            mapsURL: "https://maps.apple.com/?q=Teatower+Namur",
            hours: StoreHours.namur
        ),
        TeatowerStore(
            id: "liege", name: "Teatower Liège",
            address: "Rue Saint Paul 7, 4000 Liège",
            phone: "+32 4 XXX XX XX",
            coordinate: CLLocationCoordinate2D(latitude: 50.6326, longitude: 5.5697),
            color: .storeLiege,
            mapsURL: "https://maps.apple.com/?q=Teatower+Liege",
            hours: StoreHours.standard
        ),
    ]
}

struct StoreHours {
    let day: String
    let time: String
    let highlighted: Bool

    static let standard: [StoreHours] = [
        StoreHours(day: "Lun-Jeu", time: "10:00 – 18:00", highlighted: false),
        StoreHours(day: "Ven-Sam", time: "10:00 – 18:00", highlighted: false),
        StoreHours(day: "Dimanche", time: "Fermé", highlighted: false),
    ]

    static let namur: [StoreHours] = [
        StoreHours(day: "Lun-Jeu", time: "10:00 – 18:00", highlighted: false),
        StoreHours(day: "Ven-Sam", time: "10:00 – 19:00", highlighted: true),
        StoreHours(day: "Dimanche", time: "Fermé", highlighted: false),
    ]
}
