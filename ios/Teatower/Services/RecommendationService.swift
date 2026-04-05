import Foundation

/// Generates personalized tea recommendations using Claude API
/// based on the customer's purchase history and tea profile.
@Observable
final class RecommendationService {
    static let shared = RecommendationService()

    private let apiKey: String
    private let model = "claude-sonnet-4-20250514"
    private let endpoint = "https://api.anthropic.com/v1/messages"

    private(set) var recommendations: [TeaRecommendation] = []
    private(set) var isLoading = false
    private(set) var personalMessage: String?

    private init() {
        apiKey = Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""
    }

    struct TeaRecommendation: Identifiable, Codable {
        let id: String
        let productName: String
        let sku: String
        let reason: String
        let matchScore: Int // 1-100
        let category: String // "pour vous", "à découvrir", "saison"
        let emoji: String
    }

    func generateRecommendations(
        member: AudienceMember,
        purchases: [Purchase],
        tags: [String]
    ) async {
        guard !apiKey.isEmpty else {
            recommendations = fallbackRecommendations(member: member)
            return
        }

        isLoading = true
        defer { isLoading = false }

        let prompt = buildPrompt(member: member, purchases: purchases, tags: tags)

        do {
            let response = try await callClaude(prompt: prompt)
            let parsed = parseResponse(response)
            recommendations = parsed.recommendations
            personalMessage = parsed.message
        } catch {
            print("Claude API error: \(error)")
            recommendations = fallbackRecommendations(member: member)
        }
    }

    // MARK: - Prompt

    private func buildPrompt(
        member: AudienceMember,
        purchases: [Purchase],
        tags: [String]
    ) -> String {
        let profile = member.teaProfile
        let favoriteTypes = profile.favoriteTypes?.joined(separator: ", ") ?? "non renseigné"
        let method = profile.brewingMethod ?? "non renseigné"
        let frequency = profile.frequency ?? "non renseigné"

        // Build purchase summary
        var productCounts: [String: Int] = [:]
        for purchase in purchases {
            for item in purchase.items {
                productCounts[item.name, default: 0] += Int(item.qty)
            }
        }
        let topProducts = productCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { "\($0.key) (x\($0.value))" }
            .joined(separator: "\n  - ")

        let taste = profile.taste.map { t in
            "Sucré: \(t.sweet ?? 0)/5, Amer: \(t.bitter ?? 0)/5, Floral: \(t.floral ?? 0)/5, Épicé: \(t.spicy ?? 0)/5, Fruité: \(t.fruity ?? 0)/5"
        } ?? "non renseigné"

        let storeInfo = member.preferredStore?.displayName ?? "non renseigné"
        let ltv = NSDecimalNumber(decimal: member.lifetimeValue).doubleValue

        return """
        Tu es Trevor, sommelier de thé chez Teatower, maison de thé artisanale belge.

        Voici le profil d'un client. Recommande-lui 5 thés/infusions de notre catalogue.

        ## Profil client
        - Prénom: \(member.firstName ?? "Client")
        - Boutique préférée: \(storeInfo)
        - Achats totaux: \(member.totalOrders) commandes, \(String(format: "%.0f", ltv))€
        - Types préférés: \(favoriteTypes)
        - Méthode d'infusion: \(method)
        - Fréquence: \(frequency)
        - Profil gustatif: \(taste)
        - Tags: \(tags.joined(separator: ", "))

        ## Historique d'achats (top 10)
          - \(topProducts.isEmpty ? "Pas encore d'historique" : topProducts)

        ## Catalogue Teatower (catégories disponibles)
        Thé vert, Thé noir, Infusions de fruits, Infusions de plantes, Rooibos,
        Matcha (Japonais, Biscuit, Passion), Détox, BIO, Thés glacés (été).
        Accessoires: fouet matcha, théières, tasses, coffrets cadeaux.

        ## Consignes
        - Recommande 5 produits: 3 "pour vous" (basés sur l'historique), 1 "à découvrir" (hors zone de confort), 1 "saison" (avril = printemps)
        - Pour chaque produit: nom, SKU si connu, raison personnalisée (1 phrase), score de match (1-100), emoji
        - Ajoute un message personnel court (1-2 phrases) pour \(member.firstName ?? "ce client")
        - Ton: chaleureux, expert mais accessible, comme un ami qui connaît bien le thé

        Réponds en JSON uniquement, format:
        {
          "message": "Message personnel...",
          "recommendations": [
            {"id": "1", "productName": "...", "sku": "V0895", "reason": "...", "matchScore": 92, "category": "pour vous", "emoji": "🍵"}
          ]
        }
        """
    }

    // MARK: - API Call

    private func callClaude(prompt: String) async throws -> String {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = (json?["content"] as? [[String: Any]])?.first
        return content?["text"] as? String ?? ""
    }

    // MARK: - Parse

    private func parseResponse(_ text: String) -> (message: String?, recommendations: [TeaRecommendation]) {
        // Extract JSON from response (Claude might wrap it in markdown)
        let jsonString: String
        if let start = text.range(of: "{"), let end = text.range(of: "}", options: .backwards) {
            jsonString = String(text[start.lowerBound...end.upperBound])
        } else {
            return (nil, fallbackRecommendations(member: nil))
        }

        guard let data = jsonString.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (nil, fallbackRecommendations(member: nil))
        }

        let message = parsed["message"] as? String

        guard let recsArray = parsed["recommendations"] as? [[String: Any]] else {
            return (message, fallbackRecommendations(member: nil))
        }

        let recs = recsArray.compactMap { dict -> TeaRecommendation? in
            guard let name = dict["productName"] as? String,
                  let reason = dict["reason"] as? String else { return nil }
            return TeaRecommendation(
                id: dict["id"] as? String ?? UUID().uuidString,
                productName: name,
                sku: dict["sku"] as? String ?? "",
                reason: reason,
                matchScore: dict["matchScore"] as? Int ?? 75,
                category: dict["category"] as? String ?? "pour vous",
                emoji: dict["emoji"] as? String ?? "🍵"
            )
        }

        return (message, recs)
    }

    // MARK: - Fallback

    private func fallbackRecommendations(member: AudienceMember?) -> [TeaRecommendation] {
        [
            TeaRecommendation(id: "f1", productName: "Matcha Japonais", sku: "V0895",
                reason: "Notre bestseller — énergie douce et concentration", matchScore: 90,
                category: "pour vous", emoji: "🍵"),
            TeaRecommendation(id: "f2", productName: "Le panier de grand maman", sku: "V0279",
                reason: "L'infusion fruitée préférée de nos clients", matchScore: 85,
                category: "pour vous", emoji: "🍓"),
            TeaRecommendation(id: "f3", productName: "Sérénité BIO", sku: "V0638",
                reason: "Verveine, mélisse, tilleul — parfait le soir", matchScore: 80,
                category: "pour vous", emoji: "😌"),
            TeaRecommendation(id: "f4", productName: "Masala Chai", sku: "V0863",
                reason: "Épicé et réconfortant — sortez de votre zone de confort", matchScore: 70,
                category: "à découvrir", emoji: "🌶️"),
            TeaRecommendation(id: "f5", productName: "Infusion du Printemps 2026", sku: "V0914",
                reason: "Édition saisonnière — disponible uniquement au printemps", matchScore: 88,
                category: "saison", emoji: "🌸"),
        ]
    }
}
