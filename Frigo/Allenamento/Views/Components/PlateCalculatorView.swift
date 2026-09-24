import SwiftUI

struct PlateCalculatorView: View {
    let targetWeight: Double
    let barWeight: Double = 20.0 // Standard olympic bar
    
    // We calculate plates for ONE side of the bar
    var plates: [Double] {
        let weightPerSide = (targetWeight - barWeight) / 2
        var remaining = weightPerSide
        var result: [Double] = []
        
        // Available standard plates in Kg
        let availablePlates: [Double] = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25]
        
        for plate in availablePlates {
            while remaining >= plate - 0.01 { // -0.01 for floating point safety
                result.append(plate)
                remaining -= plate
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calcolatore Dischi")
                .font(.caption)
                .foregroundColor(.gray)
                .bold()
            
            if targetWeight <= barWeight {
                Text("Solo bilanciere (\(barWeight, specifier: "%.0f")kg)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            } else {
                HStack(spacing: 4) {
                    // Bar end
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 20, height: 10)
                        
                    // Plates
                    ForEach(0..<plates.count, id: \.self) { index in
                        let plate = plates[index]
                        ZStack {
                            Rectangle()
                                .fill(colorForPlate(plate))
                                .frame(width: widthForPlate(plate), height: heightForPlate(plate))
                                .cornerRadius(2)
                            
                            Text(String(format: "%g", plate))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(height: 50)
                
                Text(plates.map { String(format: "%g", $0) }.joined(separator: " + ") + " per lato")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func colorForPlate(_ weight: Double) -> Color {
        switch weight {
        case 25.0: return .red
        case 20.0: return .blue
        case 15.0: return .yellow
        case 10.0: return .green
        case 5.0: return .white
        case 2.5: return .black
        case 1.25: return .gray
        default: return .primary
        }
    }
    
    private func heightForPlate(_ weight: Double) -> CGFloat {
        if weight >= 15.0 { return 45 }
        if weight == 10.0 { return 35 }
        if weight == 5.0 { return 25 }
        return 20
    }
    
    private func widthForPlate(_ weight: Double) -> CGFloat {
        if weight >= 20.0 { return 18 }
        if weight >= 10.0 { return 14 }
        if weight == 5.0 { return 10 }
        return 8
    }
}

#Preview {
    VStack(spacing: 20) {
        PlateCalculatorView(targetWeight: 102.5)
        PlateCalculatorView(targetWeight: 60)
        PlateCalculatorView(targetWeight: 20)
    }
    .padding()
}
