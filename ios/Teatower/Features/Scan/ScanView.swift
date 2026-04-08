import SwiftUI
import AVFoundation
import AudioToolbox

struct ScanView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var scannedCode: String?
    @State private var product: Product?
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showManualSearch = false
    @State private var isFavorite = false
    @State private var showCamera = true

    var body: some View {
        NavigationStack {
            ZStack {
                if showCamera && product == nil {
                    // Camera scanner
                    BarcodeScannerView(scannedCode: $scannedCode)
                        .ignoresSafeArea()

                    // Overlay
                    VStack {
                        Spacer()

                        // Scan frame
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 260, height: 160)
                            .background(Color.white.opacity(0.05))

                        Spacer()

                        // Bottom controls
                        VStack(spacing: 16) {
                            Text("Scannez un produit Teatower")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)

                            Button { showManualSearch = true } label: {
                                Label("Rechercher manuellement", systemImage: "magnifyingglass")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.bottom, 40)
                    }
                } else if let product {
                    // Product found
                    ProductDetailView(product: product, isFavorite: $isFavorite) {
                        self.product = nil
                        self.scannedCode = nil
                        self.showCamera = true
                    }
                } else {
                    // Fallback
                    manualSearchView
                }
            }
            .onChange(of: scannedCode) { _, code in
                if let code { Task { await lookupProduct(barcode: code) } }
            }
            .sheet(isPresented: $showManualSearch) {
                manualSearchSheet
            }
        }
    }

    // MARK: - Manual Search

    private var manualSearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.teatowerMuted)
            Text("Scannez ou recherchez un produit")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)
            Button { showManualSearch = true } label: {
                Label("Rechercher", systemImage: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.teatowerGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private var manualSearchSheet: some View {
        NavigationStack {
            List {
                TextField("Nom du thé ou SKU...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if isSearching {
                    ProgressView()
                }
            }
            .navigationTitle("Rechercher un produit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { showManualSearch = false }
                }
            }
        }
    }

    // MARK: - Lookup

    private func lookupProduct(barcode: String) async {
        isSearching = true
        do {
            let results: [Product] = try await supabase.client
                .from("products")
                .select()
                .eq("barcode", value: barcode)
                .limit(1)
                .execute()
                .value

            if let found = results.first {
                product = found
                showCamera = false
                // Check if favorite
                let favs: [Favorite] = try await supabase.client
                    .from("favorites")
                    .select()
                    .eq("sku", value: found.sku)
                    .limit(1)
                    .execute()
                    .value
                isFavorite = !favs.isEmpty
            }
        } catch {
            print("Product lookup failed: \(error)")
        }
        isSearching = false
    }
}

// MARK: - Product Detail

struct ProductDetailView: View {
    let product: Product
    @Binding var isFavorite: Bool
    let onDismiss: () -> Void
    @Environment(SupabaseManager.self) private var supabase

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.teatowerBg)
                        .frame(height: 200)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.teatowerGreen.opacity(0.3))
                }

                VStack(spacing: 8) {
                    Text(product.name)
                        .font(.teatowerTitle)
                        .foregroundStyle(.teatowerGreen)
                        .multilineTextAlignment(.center)

                    if let cat = product.category {
                        Text(cat)
                            .font(.teatowerCaption)
                            .foregroundStyle(.teatowerBrown)
                    }

                    Text(product.sku)
                        .font(.system(size: 12))
                        .foregroundStyle(.teatowerMuted)

                    if let price = product.priceEur {
                        Text("\(NSDecimalNumber(decimal: price).doubleValue, specifier: "%.2f")€")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.teatowerGreen)
                    }
                }

                // Actions
                HStack(spacing: 12) {
                    Button {
                        Task { await toggleFavorite() }
                    } label: {
                        Label(isFavorite ? "Favori" : "Ajouter aux favoris",
                              systemImage: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isFavorite ? Color.red.opacity(0.1) : Color.teatowerBg)
                            .foregroundColor(isFavorite ? .red : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Link(destination: URL(string: "https://teatower.com/search?q=\(product.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                        Label("Commander", systemImage: "cart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.teatowerGreen)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Scan another
                Button(action: onDismiss) {
                    Label("Scanner un autre produit", systemImage: "barcode.viewfinder")
                        .font(.system(size: 14))
                        .foregroundStyle(.teatowerBrown)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color.teatowerBg)
    }

    private func toggleFavorite() async {
        guard let email = supabase.currentEmail else { return }
        if isFavorite {
            try? await supabase.client.from("favorites")
                .delete().eq("email", value: email).eq("sku", value: product.sku)
                .execute()
        } else {
            try? await supabase.client.from("favorites")
                .insert(Favorite(email: email, sku: product.sku, addedAt: nil))
                .execute()
        }
        isFavorite.toggle()
    }
}

// MARK: - Barcode Scanner (AVFoundation wrapper)

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCodeScanned = { code in scannedCode = code }
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onCodeScanned: ((String) -> Void)?
        private let session = AVCaptureSession()
        private var hasScanned = false

        override func viewDidLoad() {
            super.viewDidLoad()
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }

            session.addInput(input)
            let output = AVCaptureMetadataOutput()
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean13, .ean8, .qr, .code128]

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.frame = view.bounds
            preview.videoGravity = .resizeAspectFill
            view.layer.addSublayer(preview)

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = object.stringValue else { return }
            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onCodeScanned?(code)
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            session.stopRunning()
        }
    }
}
