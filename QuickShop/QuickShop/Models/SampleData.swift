import Foundation

enum SampleData {
    static let products: [Product] = [
        // APIs
        Product(
            id: UUID(),
            name: "GPT-4 Turbo API Credits",
            description: "1M token pack for OpenAI's GPT-4 Turbo. Includes vision and function calling.",
            price: 49.99,
            category: .apis,
            imageURL: "https://api.devshop.ai/GPT-4 Turbo API Credits",
            sfSymbol: "brain.head.profile",
            rating: 4.8,
            reviewCount: 12430
        ),
        Product(
            id: UUID(),
            name: "claude-api-token-pack",
            description: "500K tokens for Anthropic's Claude. Supports tool use and long context.",
            price: 39.99,
            category: .apis,
            imageURL: "https://api.devshop.ai/claude-api-token-pack",
            sfSymbol: "message.badge.filled.fill",
            rating: 4.9,
            reviewCount: 8920
        ),
        Product(
            id: UUID(),
            name: "Whisper Speech-to-Text Endpoint & Transcription Service",
            description: "Real-time speech recognition API. 99 languages supported. WebSocket streaming.",
            price: 29.99,
            category: .apis,
            imageURL: "https://api.devshop.ai/Whisper Speech-to-Text Endpoint & Transcription Service",
            sfSymbol: "waveform.badge.mic",
            rating: 4.5,
            reviewCount: 3456
        ),

        // Compute
        Product(
            id: UUID(),
            name: "A100 GPU Hours (On-Demand)",
            description: "NVIDIA A100 80GB instances. Perfect for training and fine-tuning. Spot pricing available.",
            price: 2.49,
            category: .compute,
            imageURL: "https://api.devshop.ai/A100 GPU Hours (On-Demand)",
            sfSymbol: "cpu.fill",
            rating: 4.7,
            reviewCount: 5678
        ),
        Product(
            id: UUID(),
            name: "edge-runtime-credits",
            description: "Serverless edge function invocations. Sub-10ms cold starts. 300+ PoPs worldwide.",
            price: 9.99,
            category: .compute,
            imageURL: "https://api.devshop.ai/edge-runtime-credits",
            sfSymbol: "globe.americas.fill",
            rating: 4.6,
            reviewCount: 2100
        ),
        Product(
            id: UUID(),
            name: "Dedicated Inference Cluster — Multi-GPU Auto-Scaling Tier",
            description: "Reserved H100 cluster with auto-scaling. 99.99% SLA. Priority queue.",
            price: 499.99,
            category: .compute,
            imageURL: "https://api.devshop.ai/Dedicated Inference Cluster — Multi-GPU Auto-Scaling Tier",
            sfSymbol: "server.rack",
            rating: 4.4,
            reviewCount: 456
        ),

        // Models
        Product(
            id: UUID(),
            name: "Fine-Tuned Code Llama 70B — Full-Stack Generation Specialist",
            description: "Code generation model fine-tuned on 2M repositories. Supports 40+ languages.",
            price: 149.99,
            category: .models,
            imageURL: "https://api.devshop.ai/Fine-Tuned Code Llama 70B — Full-Stack Generation Specialist",
            sfSymbol: "chevron.left.forwardslash.chevron.right",
            rating: 4.3,
            reviewCount: 1243
        ),
        Product(
            id: UUID(),
            name: "sdxl-weights-bundle",
            description: "Stable Diffusion XL base + refiner weights. Commercial license included.",
            price: 19.99,
            category: .models,
            imageURL: "https://api.devshop.ai/sdxl-weights-bundle",
            sfSymbol: "photo.artframe",
            rating: 4.5,
            reviewCount: 6789
        ),
        Product(
            id: UUID(),
            name: "Vector Embedding Model — Multilingual 1024-dim with HNSW Index",
            description: "State-of-the-art embeddings for RAG. 100+ languages. Matryoshka support.",
            price: 24.99,
            category: .models,
            imageURL: "https://api.devshop.ai/Vector Embedding Model — Multilingual 1024-dim with HNSW Index",
            sfSymbol: "arrow.triangle.branch",
            rating: 4.8,
            reviewCount: 4321
        ),

        // DevTools
        Product(
            id: UUID(),
            name: "gstack-pro-license",
            description: "GStack Pro: advanced AI coding framework with multi-agent orchestration.",
            price: 29.99,
            category: .devtools,
            imageURL: "https://api.devshop.ai/gstack-pro-license",
            sfSymbol: "hammer.fill",
            rating: 4.9,
            reviewCount: 15670
        ),
        Product(
            id: UUID(),
            name: "GBrain Cloud Seats — Team Knowledge Layer (5 Developers)",
            description: "Hosted GBrain for teams. Structured memory, context, and intelligence for your AI agents.",
            price: 79.99,
            category: .devtools,
            imageURL: "https://api.devshop.ai/GBrain Cloud Seats — Team Knowledge Layer (5 Developers)",
            sfSymbol: "brain",
            rating: 4.7,
            reviewCount: 3200
        ),
        Product(
            id: UUID(),
            name: "terminal-theme-pack",
            description: "50 premium terminal themes. iTerm2, Alacritty, Warp, and Kitty compatible.",
            price: 4.99,
            category: .devtools,
            imageURL: "https://api.devshop.ai/terminal-theme-pack",
            sfSymbol: "terminal.fill",
            rating: 4.2,
            reviewCount: 890
        ),
    ]

    static let sampleUser = User(
        id: UUID(),
        name: "kai_dev",
        email: "kai@hackathon.dev",
        avatarSymbol: "terminal",
        memberSince: Calendar.current.date(from: DateComponents(year: 2023, month: 3, day: 15))!,
        orderCount: 47
    )

    static let secondUser = User(
        id: UUID(),
        name: "mx_runtime",
        email: "mx@hackathon.dev",
        avatarSymbol: "terminal",
        memberSince: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 8))!,
        orderCount: 12
    )
}
