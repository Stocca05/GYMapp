import Foundation

struct OptModel: Codable {
    var a: String
    var b: String?
}

let json = """
{"a": "hello"}
""".data(using: .utf8)!

let dec = try! JSONDecoder().decode(OptModel.self, from: json)
print("a: \(dec.a), b: \(String(describing: dec.b))")
