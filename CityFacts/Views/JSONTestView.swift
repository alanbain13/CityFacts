// MARK: - JSONTestView
// Description: Simple test view to verify JSON file accessibility.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import SwiftUI

struct JSONTestView: View {
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationView {
            VStack {
                Text("JSON File Test")
                    .font(.title)
                    .padding()
                
                Button("Test JSON Files") {
                    testJSONFiles()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(testResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .navigationTitle("JSON Test")
        }
    }
    
    private func testJSONFiles() {
        testResults.removeAll()
        
        let files = ["cities", "attractions", "hotels", "venues"]
        
        for filename in files {
            if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let jsonString = String(data: data, encoding: .utf8) ?? "Could not decode"
                    testResults.append("✅ \(filename).json found (\(data.count) bytes)")
                    testResults.append("📄 First 200 chars: \(String(jsonString.prefix(200)))")
                } catch {
                    testResults.append("❌ Error reading \(filename).json: \(error)")
                }
            } else {
                testResults.append("❌ \(filename).json not found in bundle")
            }
        }
    }
}

#Preview {
    JSONTestView()
} 