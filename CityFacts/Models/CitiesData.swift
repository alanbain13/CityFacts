import Foundation

extension CityStore {
    static let citiesData: [City] = [
        // Asia
        City(
            id: UUID(),
            name: "Tokyo",
            country: "Japan",
            continent: .asia,
            population: 37_400_068,
            description: "Tokyo is Japan's capital and the world's largest metropolitan economy.",
            landmarks: [
                Landmark(name: "Tokyo Skytree", description: "The world's tallest tower at 634 meters", imageURL: "tokyo_skytree"),
                Landmark(name: "Senso-ji Temple", description: "Ancient Buddhist temple in Asakusa", imageURL: "sensoji")
            ],
            coordinates: City.Coordinates(latitude: 35.6762, longitude: 139.6503),
            timezone: "Asia/Tokyo",
            imageURLs: ["https://images.unsplash.com/photo-1540959733332-eab4deabeeaf"],
            facts: [
                "Tokyo was formerly known as Edo",
                "Home to the world's busiest pedestrian crossing",
                "Has the most Michelin-starred restaurants of any city"
            ]
        ),
        City(
            id: UUID(),
            name: "Delhi",
            country: "India",
            continent: .asia,
            population: 32_941_000,
            description: "Delhi is the capital of India and a major global cultural center.",
            landmarks: [
                Landmark(name: "India Gate", description: "War memorial dedicated to Indian soldiers", imageURL: "india_gate"),
                Landmark(name: "Red Fort", description: "Historic fortress built in the Mughal era", imageURL: "red_fort")
            ],
            coordinates: City.Coordinates(latitude: 28.6139, longitude: 77.2090),
            timezone: "Asia/Kolkata",
            imageURLs: ["https://images.unsplash.com/photo-1587474260584-136574528ed5"],
            facts: [
                "Delhi was designed by British architects",
                "It has the largest comprehensive metro system in India",
                "Home to numerous historical monuments"
            ]
        ),
        City(
            id: UUID(),
            name: "Shanghai",
            country: "China",
            continent: .asia,
            population: 27_796_000,
            description: "Shanghai is the largest city in China and a global financial center.",
            landmarks: [
                Landmark(name: "The Bund", description: "Famous waterfront area with historic buildings", imageURL: "the_bund"),
                Landmark(name: "Oriental Pearl Tower", description: "Iconic TV tower with observation decks", imageURL: "pearl_tower")
            ],
            coordinates: City.Coordinates(latitude: 31.2304, longitude: 121.4737),
            timezone: "Asia/Shanghai",
            imageURLs: ["https://images.unsplash.com/photo-1548919973-5cef591cdbc9"],
            facts: [
                "Shanghai is the world's largest city proper by population",
                "Home to the world's second-tallest building",
                "Has the world's first commercial maglev system"
            ]
        ),
        City(
            id: UUID(),
            name: "São Paulo",
            country: "Brazil",
            continent: .southAmerica,
            population: 22_429_800,
            description: "São Paulo is the largest city in Brazil and the Southern Hemisphere.",
            landmarks: [
                Landmark(name: "Paulista Avenue", description: "Major financial center with cultural institutions", imageURL: "paulista"),
                Landmark(name: "Ibirapuera Park", description: "Urban park with museums and concert halls", imageURL: "ibirapuera")
            ],
            coordinates: City.Coordinates(latitude: -23.5505, longitude: -46.6333),
            timezone: "America/Sao_Paulo",
            imageURLs: ["https://images.unsplash.com/photo-1543059080-f9b1272213d5"],
            facts: [
                "Largest city in the Southern Hemisphere",
                "Has the largest Japanese population outside Japan",
                "Known for its diverse architecture and cultural scene"
            ]
        ),
        City(
            id: UUID(),
            name: "Mexico City",
            country: "Mexico",
            continent: .northAmerica,
            population: 22_085_140,
            description: "Mexico City is the capital of Mexico and the most populous city in North America.",
            landmarks: [
                Landmark(name: "Zócalo", description: "Main square and heart of the historic center", imageURL: "zocalo"),
                Landmark(name: "Metropolitan Cathedral", description: "Largest cathedral in the Americas", imageURL: "cathedral")
            ],
            coordinates: City.Coordinates(latitude: 19.4326, longitude: -99.1332),
            timezone: "America/Mexico_City",
            imageURLs: ["https://images.unsplash.com/photo-1518105779142-d424fb227ae3"],
            facts: [
                "Built on the ruins of the Aztec capital Tenochtitlan",
                "Has the largest number of museums in the world",
                "Home to the oldest university in North America"
            ]
        ),
        City(
            id: UUID(),
            name: "Cairo",
            country: "Egypt",
            continent: .africa,
            population: 21_750_000,
            description: "Cairo is the capital of Egypt and the largest city in the Arab world.",
            landmarks: [
                Landmark(name: "Pyramids of Giza", description: "Ancient Egyptian pyramids and the Great Sphinx", imageURL: "pyramids"),
                Landmark(name: "Egyptian Museum", description: "Home to the world's largest collection of ancient Egyptian antiquities", imageURL: "museum")
            ],
            coordinates: City.Coordinates(latitude: 30.0444, longitude: 31.2357),
            timezone: "Africa/Cairo",
            imageURLs: ["https://images.unsplash.com/photo-1572252009286-268acec5ca0a"],
            facts: [
                "Oldest Islamic city in Africa",
                "Home to the oldest and largest film industry in the Arab world",
                "Contains the only remaining ancient wonder of the world"
            ]
        ),
        City(
            id: UUID(),
            name: "Dhaka",
            country: "Bangladesh",
            continent: .asia,
            population: 21_741_000,
            description: "Dhaka is the capital and largest city of Bangladesh.",
            landmarks: [
                Landmark(name: "Lalbagh Fort", description: "17th-century Mughal fort complex", imageURL: "lalbagh"),
                Landmark(name: "Ahsan Manzil", description: "Pink Palace and historic museum", imageURL: "ahsan_manzil")
            ],
            coordinates: City.Coordinates(latitude: 23.8103, longitude: 90.4125),
            timezone: "Asia/Dhaka",
            imageURLs: ["https://images.unsplash.com/photo-1583422409516-2895a77efded"],
            facts: [
                "One of the most densely populated cities in the world",
                "Known as the City of Mosques",
                "Major center for Bengali culture and literature"
            ]
        ),
        City(
            id: UUID(),
            name: "Jakarta",
            country: "Indonesia",
            continent: .asia,
            population: 19_500_000,
            description: "Jakarta is the capital of Indonesia and the largest city in Southeast Asia.",
            landmarks: [
                Landmark(name: "National Monument", description: "Tower symbolizing Indonesian independence", imageURL: "monas"),
                Landmark(name: "Istiqlal Mosque", description: "Largest mosque in Southeast Asia", imageURL: "istiqlal")
            ],
            coordinates: City.Coordinates(latitude: -6.2088, longitude: 106.8456),
            timezone: "Asia/Jakarta",
            imageURLs: ["https://images.unsplash.com/photo-1555899434-94d1368aa7af"],
            facts: [
                "Built on swampland in the 17th century",
                "Home to the world's largest urban park",
                "Known for its diverse cultural heritage"
            ]
        ),
        City(
            id: UUID(),
            name: "Manila",
            country: "Philippines",
            continent: .asia,
            population: 14_406_059,
            description: "Manila is the capital of the Philippines and a major cultural and economic center.",
            landmarks: [
                Landmark(name: "Intramuros", description: "Historic walled area from Spanish colonial period", imageURL: "intramuros"),
                Landmark(name: "Rizal Park", description: "Historical urban park", imageURL: "rizal_park")
            ],
            coordinates: City.Coordinates(latitude: 14.5995, longitude: 120.9842),
            timezone: "Asia/Manila",
            imageURLs: ["https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86"],
            facts: [
                "One of the most densely populated cities in the world",
                "First established as a fortress city",
                "Home to the world's oldest Chinatown"
            ]
        ),
        City(
            id: UUID(),
            name: "Seoul",
            country: "South Korea",
            continent: .asia,
            population: 9_776_000,
            description: "Seoul is the capital of South Korea and a leading global technology hub.",
            landmarks: [
                Landmark(name: "Gyeongbokgung Palace", description: "Main royal palace of the Joseon dynasty", imageURL: "gyeongbokgung"),
                Landmark(name: "N Seoul Tower", description: "Communication and observation tower", imageURL: "n_seoul_tower")
            ],
            coordinates: City.Coordinates(latitude: 37.5665, longitude: 126.9780),
            timezone: "Asia/Seoul",
            imageURLs: ["https://images.unsplash.com/photo-1538669715315-155098f0fb1d"],
            facts: [
                "One of the world's leading digital cities",
                "Has the world's fastest internet speeds",
                "Home to numerous UNESCO World Heritage sites"
            ]
        ),
        City(
            id: UUID(),
            name: "Moscow",
            country: "Russia",
            continent: .europe,
            population: 12_506_468,
            description: "Moscow is the capital of Russia and the largest city in Europe.",
            landmarks: [
                Landmark(name: "Red Square", description: "City square in the heart of Moscow", imageURL: "red_square"),
                Landmark(name: "Saint Basil's Cathedral", description: "Iconic Orthodox church with colorful domes", imageURL: "saint_basils")
            ],
            coordinates: City.Coordinates(latitude: 55.7558, longitude: 37.6173),
            timezone: "Europe/Moscow",
            imageURLs: ["https://images.unsplash.com/photo-1513326738677-b964603b136d"],
            facts: [
                "Home to the world's most used metro system",
                "Has the most billionaire residents of any city",
                "Contains the largest medieval fortress in the world"
            ]
        ),
        City(
            id: UUID(),
            name: "London",
            country: "United Kingdom",
            continent: .europe,
            population: 9_002_488,
            description: "London is the capital of the United Kingdom and a leading global city.",
            landmarks: [
                Landmark(name: "Big Ben", description: "Iconic clock tower at the Houses of Parliament", imageURL: "big_ben"),
                Landmark(name: "Tower Bridge", description: "Combined bascule and suspension bridge", imageURL: "tower_bridge")
            ],
            coordinates: City.Coordinates(latitude: 51.5074, longitude: -0.1278),
            timezone: "Europe/London",
            imageURLs: ["https://images.unsplash.com/photo-1513635269975-59663e0ac1ad"],
            facts: [
                "Has been a major settlement for two millennia",
                "Home to four World Heritage Sites",
                "The world's oldest underground railway system"
            ]
        ),
        City(
            id: UUID(),
            name: "Paris",
            country: "France",
            continent: .europe,
            population: 2_148_271,
            description: "Paris is the capital of France and a global center for art, fashion, and culture.",
            landmarks: [
                Landmark(name: "Eiffel Tower", description: "Iconic iron lattice tower", imageURL: "eiffel_tower"),
                Landmark(name: "Louvre Museum", description: "World's largest art museum", imageURL: "louvre")
            ],
            coordinates: City.Coordinates(latitude: 48.8566, longitude: 2.3522),
            timezone: "Europe/Paris",
            imageURLs: ["https://images.unsplash.com/photo-1502602898657-3e91760cbb34"],
            facts: [
                "Most visited city in the world",
                "Home to world's largest art museum",
                "Known as the City of Light"
            ]
        ),
        City(
            id: UUID(),
            name: "Berlin",
            country: "Germany",
            continent: .europe,
            population: 3_669_495,
            description: "Berlin is the capital of Germany and a major cultural and historical center.",
            landmarks: [
                Landmark(name: "Brandenburg Gate", description: "18th-century neoclassical monument", imageURL: "brandenburg_gate"),
                Landmark(name: "East Side Gallery", description: "Longest remaining section of the Berlin Wall", imageURL: "east_side_gallery")
            ],
            coordinates: City.Coordinates(latitude: 52.5200, longitude: 13.4050),
            timezone: "Europe/Berlin",
            imageURLs: ["https://images.unsplash.com/photo-1560969184-10fe8719e047"],
            facts: [
                "Nine times the size of Paris",
                "More bridges than Venice",
                "Home to the world's largest open-air gallery"
            ]
        ),
        City(
            id: UUID(),
            name: "Rome",
            country: "Italy",
            continent: .europe,
            population: 4_342_212,
            description: "Rome is the capital of Italy and the center of the ancient Roman Empire.",
            landmarks: [
                Landmark(name: "Colosseum", description: "Ancient amphitheater and iconic symbol of Rome", imageURL: "colosseum"),
                Landmark(name: "Vatican City", description: "Independent city-state and headquarters of the Roman Catholic Church", imageURL: "vatican")
            ],
            coordinates: City.Coordinates(latitude: 41.9028, longitude: 12.4964),
            timezone: "Europe/Rome",
            imageURLs: ["https://images.unsplash.com/photo-1552832230-c0197dd311b5"],
            facts: [
                "Known as the Eternal City",
                "Contains the world's smallest country",
                "Has more than 2000 fountains"
            ]
        ),
        City(
            id: UUID(),
            name: "Madrid",
            country: "Spain",
            continent: .europe,
            population: 3_223_334,
            description: "Madrid is the capital of Spain and its largest city.",
            landmarks: [
                Landmark(name: "Royal Palace", description: "Official residence of the Spanish Royal Family", imageURL: "royal_palace"),
                Landmark(name: "Prado Museum", description: "National art museum of Spain", imageURL: "prado")
            ],
            coordinates: City.Coordinates(latitude: 40.4168, longitude: -3.7038),
            timezone: "Europe/Madrid",
            imageURLs: ["https://images.unsplash.com/photo-1543783207-ec64e4d95325"],
            facts: [
                "Highest capital city in Europe",
                "Home to the world's oldest restaurant",
                "Center of Spanish art and culture"
            ]
        ),
        City(
            id: UUID(),
            name: "Washington, D.C.",
            country: "United States",
            continent: .northAmerica,
            population: 689_545,
            description: "Washington, D.C. is the capital of the United States and seat of federal government.",
            landmarks: [
                Landmark(name: "White House", description: "Official residence and workplace of the U.S. President", imageURL: "white_house"),
                Landmark(name: "Capitol Building", description: "Meeting place of the U.S. Congress", imageURL: "capitol")
            ],
            coordinates: City.Coordinates(latitude: 38.9072, longitude: -77.0369),
            timezone: "America/New_York",
            imageURLs: ["https://images.unsplash.com/photo-1501466044931-62695aada8e9"],
            facts: [
                "Planned by French architect Pierre Charles L'Enfant",
                "Not part of any U.S. state",
                "Home to all three branches of U.S. government"
            ]
        ),
        City(
            id: UUID(),
            name: "Ottawa",
            country: "Canada",
            continent: .northAmerica,
            population: 994_837,
            description: "Ottawa is the capital city of Canada and a major technology center.",
            landmarks: [
                Landmark(name: "Parliament Hill", description: "Gothic revival suite of buildings", imageURL: "parliament_hill"),
                Landmark(name: "Rideau Canal", description: "UNESCO World Heritage Site", imageURL: "rideau_canal")
            ],
            coordinates: City.Coordinates(latitude: 45.4215, longitude: -75.6972),
            timezone: "America/Toronto",
            imageURLs: ["https://images.unsplash.com/photo-1503883705143-45bc45fa0c43"],
            facts: [
                "Most educated city in Canada",
                "World's largest naturally frozen skating rink",
                "Most bilingual city in Canada"
            ]
        ),
        City(
            id: UUID(),
            name: "Buenos Aires",
            country: "Argentina",
            continent: .southAmerica,
            population: 3_075_646,
            description: "Buenos Aires is the capital of Argentina and largest city in the country.",
            landmarks: [
                Landmark(name: "Casa Rosada", description: "Pink House - seat of Argentine government", imageURL: "casa_rosada"),
                Landmark(name: "Teatro Colón", description: "Main opera house known for acoustics", imageURL: "teatro_colon")
            ],
            coordinates: City.Coordinates(latitude: -34.6037, longitude: -58.3816),
            timezone: "America/Argentina/Buenos_Aires",
            imageURLs: ["https://images.unsplash.com/photo-1589909202802-8f4aadce1849"],
            facts: [
                "Known as the Paris of South America",
                "Has the highest concentration of theatres in the world",
                "Birthplace of tango"
            ]
        ),
        City(
            id: UUID(),
            name: "Lima",
            country: "Peru",
            continent: .southAmerica,
            population: 10_719_000,
            description: "Lima is the capital and largest city of Peru.",
            landmarks: [
                Landmark(name: "Plaza Mayor", description: "Historic center of Lima", imageURL: "plaza_mayor"),
                Landmark(name: "Huaca Pucllana", description: "Ancient pyramid in modern city", imageURL: "huaca_pucllana")
            ],
            coordinates: City.Coordinates(latitude: -12.0464, longitude: -77.0428),
            timezone: "America/Lima",
            imageURLs: ["https://images.unsplash.com/photo-1531968455001-5c5272a41129"],
            facts: [
                "Founded by Spanish conquistador Francisco Pizarro",
                "Known as the Gastronomical Capital of the Americas",
                "Home to the oldest university in the Americas"
            ]
        ),
        City(
            id: UUID(),
            name: "Sydney",
            country: "Australia",
            continent: .oceania,
            population: 5_367_206,
            description: "Sydney is Australia's largest city and economic center.",
            landmarks: [
                Landmark(name: "Sydney Opera House", description: "UNESCO World Heritage site and architectural icon", imageURL: "opera_house"),
                Landmark(name: "Sydney Harbour Bridge", description: "Steel through arch bridge across the harbor", imageURL: "harbour_bridge")
            ],
            coordinates: City.Coordinates(latitude: -33.8688, longitude: 151.2093),
            timezone: "Australia/Sydney",
            imageURLs: ["https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9"],
            facts: [
                "Oldest city in Australia",
                "Built on the world's largest natural harbor",
                "Home to two of the world's most iconic structures"
            ]
        ),
        City(
            id: UUID(),
            name: "Bangkok",
            country: "Thailand",
            continent: .asia,
            population: 8_280_925,
            description: "Bangkok is the capital and most populous city of Thailand.",
            landmarks: [
                Landmark(name: "Grand Palace", description: "Former residence of Thai kings", imageURL: "grand_palace"),
                Landmark(name: "Wat Arun", description: "Buddhist temple on Chao Phraya River", imageURL: "wat_arun")
            ],
            coordinates: City.Coordinates(latitude: 13.7563, longitude: 100.5018),
            timezone: "Asia/Bangkok",
            imageURLs: ["https://images.unsplash.com/photo-1508009603885-50cf7c579365"],
            facts: [
                "Full ceremonial name is the longest place name in the world",
                "Known as the City of Angels",
                "Home to the world's largest Chinatown outside China"
            ]
        ),
        City(
            id: UUID(),
            name: "Vienna",
            country: "Austria",
            continent: .europe,
            population: 1_897_491,
            description: "Vienna is the capital of Austria and a major cultural center.",
            landmarks: [
                Landmark(name: "Schönbrunn Palace", description: "Summer residence of Habsburg rulers", imageURL: "schonbrunn"),
                Landmark(name: "St. Stephen's Cathedral", description: "Gothic cathedral and city symbol", imageURL: "stephansdom")
            ],
            coordinates: City.Coordinates(latitude: 48.2082, longitude: 16.3738),
            timezone: "Europe/Vienna",
            imageURLs: ["https://images.unsplash.com/photo-1516550893923-42d28e5677af"],
            facts: [
                "Consistently ranked as the world's most liveable city",
                "Classical music capital of the world",
                "Home to the world's oldest zoo"
            ]
        ),
        City(
            id: UUID(),
            name: "Copenhagen",
            country: "Denmark",
            continent: .europe,
            population: 794_128,
            description: "Copenhagen is the capital of Denmark and a leader in sustainability.",
            landmarks: [
                Landmark(name: "Little Mermaid", description: "Bronze statue inspired by Hans Christian Andersen", imageURL: "little_mermaid"),
                Landmark(name: "Tivoli Gardens", description: "Historic amusement park and pleasure garden", imageURL: "tivoli")
            ],
            coordinates: City.Coordinates(latitude: 55.6761, longitude: 12.5683),
            timezone: "Europe/Copenhagen",
            imageURLs: ["https://images.unsplash.com/photo-1513622470522-26c3c8a854bc"],
            facts: [
                "One of the most bicycle-friendly cities in the world",
                "Home to the two oldest amusement parks in the world",
                "Pioneer in sustainable urban development"
            ]
        ),
        City(
            id: UUID(),
            name: "Stockholm",
            country: "Sweden",
            continent: .europe,
            population: 975_551,
            description: "Stockholm is the capital of Sweden, built on 14 islands.",
            landmarks: [
                Landmark(name: "Vasa Museum", description: "Maritime museum with 17th-century warship", imageURL: "vasa"),
                Landmark(name: "Royal Palace", description: "Official residence of Swedish monarchy", imageURL: "stockholm_palace")
            ],
            coordinates: City.Coordinates(latitude: 59.3293, longitude: 18.0686),
            timezone: "Europe/Stockholm",
            imageURLs: ["https://images.unsplash.com/photo-1509356843151-3e7d96241e34"],
            facts: [
                "Built on 14 islands connected by 57 bridges",
                "First city to have an environmental program",
                "Home to the Nobel Prize ceremonies"
            ]
        ),
        City(
            id: UUID(),
            name: "Wellington",
            country: "New Zealand",
            continent: .oceania,
            population: 212_700,
            description: "Wellington is the capital of New Zealand, known for its arts and culture.",
            landmarks: [
                Landmark(name: "Parliament Buildings", description: "Including the distinctive Beehive", imageURL: "beehive"),
                Landmark(name: "Te Papa Museum", description: "National Museum of New Zealand", imageURL: "te_papa")
            ],
            coordinates: City.Coordinates(latitude: -41.2866, longitude: 174.7756),
            timezone: "Pacific/Auckland",
            imageURLs: ["https://images.unsplash.com/photo-1589871973318-9ca1258faa5d"],
            facts: [
                "Windiest city in the world",
                "More cafes per capita than New York City",
                "Known as 'Wellywood' for its film industry"
            ]
        )
    ]
}

extension CityStore {
    func loadCities() async {
        cities = Self.citiesData.sorted { $0.population > $1.population }
    }
} 