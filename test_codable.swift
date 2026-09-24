import Foundation

struct MyStruct: Codable {
    var a: Int
    var b: Int
    
    init(a: Int, b: Int) {
        self.a = a
        self.b = b
    }
    
    enum CodingKeys: String, CodingKey {
        case a, b
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.a = try container.decode(Int.self, forKey: .a)
        self.b = try container.decodeIfPresent(Int.self, forKey: .b) ?? 2
    }
}

let m = MyStruct(a: 1, b: 2)
let encoder = JSONEncoder()
let data = try! encoder.encode(m)
print(String(data: data, encoding: .utf8)!)
