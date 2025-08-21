//
//  AppManager.swift
//  Probe
//
//  Created by Ramtin Mir on 7/2/25.
//

import Foundation
import SwiftUI


// receives hex string with # and returns Swift-accepted color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

struct RotatingRainbowCircle: View {
    var nextWaterTime: String
    @State private var rotation = 0.0

    var pastelColors: [Color] = [
        Color(red: 0.93, green: 0.45, blue: 0.45),  // soft red
        Color(red: 0.95, green: 0.65, blue: 0.35),  // soft orange
        Color(red: 0.95, green: 0.90, blue: 0.50),  // soft yellow
        Color(red: 0.55, green: 0.85, blue: 0.55),  // soft green
        Color(red: 0.50, green: 0.70, blue: 0.95),  // soft blue
        Color(red: 0.70, green: 0.55, blue: 0.95),  // soft purple
        Color(red: 0.93, green: 0.45, blue: 0.45)   // loop back soft red
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .shadow(color: Color.white.opacity(0.6), radius: 4, x: 0, y: 0) // subtle glow
            
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: pastelColors),
                        center: .center
                    ),
                    lineWidth: 5
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotation))
                .shadow(color: Color.white.opacity(0.8), radius: 4) // glow around border
            
            if nextWaterTime == "today" {
                Text(nextWaterTime)
                    .fontWeight(.bold)
                    .font(.subheadline)
                    .foregroundColor(.black)
            } else {
                VStack(spacing: 0) {
                    Text("\(nextWaterTime)d")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3)) {
                rotation = 360
            }
        }
    }
}

struct AnimatedPulsingCircle: View {
    let deviceStatus: String?
    public let color: Color
    
    @State private var isBlinking = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.8))
//                .stroke(color, lineWidth: 2)
                .frame(width: 30, height: 30)

            // Inner white circle with scale animation
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 30, height: 30)
                .opacity(isBlinking ? 0 : 0.5)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isBlinking)
        }
        .onAppear {
            if (deviceStatus != nil && deviceStatus != "offline") {
                isBlinking = true
            }
        }
    }
}

struct GlassButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    // Darker glass background
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.4))
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color(hex: "#008000"))
                                .blur(radius: 1)
                        )
                )
                // Reflective gradient border
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.8),
                                    Color.green.opacity(0.6),
                                    Color.green.opacity(0.3),
                                    Color.white.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.2
                        )
                )
                // Inner glow
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                        .blur(radius: 1)
                )
                .shadow(color: Color.green.opacity(0.25), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct GradientMaterialOverlay: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThickMaterial)
            .mask(
                LinearGradient(
                    gradient: Gradient(colors: [.white, .white.opacity(0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
import Foundation

struct CrockfordBase32 {
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    private static let decodeMap: [Character: UInt8] = {
        var map = [Character: UInt8]()
        let chars = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        for (i, c) in chars.enumerated() {
            map[c] = UInt8(i)
            map[Character(c.lowercased())] = UInt8(i)
        }
        // Add common substitutes
        map["O"] = map["0"]
        map["o"] = map["0"]
        map["I"] = map["1"]
        map["i"] = map["1"]
        map["L"] = map["1"]
        map["l"] = map["1"]
        return map
    }()

    static func encode(_ data: Data) -> String {
        var output = ""
        var buffer = 0
        var bitsLeft = 0

        for byte in data {
            buffer <<= 8
            buffer |= Int(byte)
            bitsLeft += 8
            while bitsLeft >= 5 {
                let index = (buffer >> (bitsLeft - 5)) & 0x1F
                bitsLeft -= 5
                output.append(alphabet[Int(index)])
            }
        }
        if bitsLeft > 0 {
            let index = (buffer << (5 - bitsLeft)) & 0x1F
            output.append(alphabet[Int(index)])
        }
        return output
    }

    static func decode(_ string: String) -> Data? {
        var buffer = 0
        var bitsLeft = 0
        var bytes = [UInt8]()

        for ch in string {
            guard let val = decodeMap[ch] else {
                return nil // invalid char
            }
            buffer = (buffer << 5) | Int(val)
            bitsLeft += 5
            if bitsLeft >= 8 {
                bitsLeft -= 8
                let byte = UInt8((buffer >> bitsLeft) & 0xFF)
                bytes.append(byte)
            }
        }
        return Data(bytes)
    }
}

// Helper extensions for hex conversion

extension Data {
    init?(hex: String) {
        var hex = hex
        var data = Data()
        while hex.count > 0 {
            let c = String(hex.prefix(2))
            hex = String(hex.dropFirst(2))
            guard let b = UInt8(c, radix: 16) else { return nil }
            data.append(b)
        }
        self = data
    }
    
    func hexEncodedString() -> String {
        self.map { String(format: "%02X", $0) }.joined()
    }
}

extension String {
    func chunked(by length: Int) -> [String] {
        stride(from: 0, to: count, by: length).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: length, limitedBy: endIndex) ?? endIndex
            return String(self[start..<end])
        }
    }
}

// Plus this chunk helper somewhere accessible
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// recersable encode/decode functions
func encodeMAC(_ mac: String) -> String? {
    let cleaned = mac.replacingOccurrences(of: ":", with: "").lowercased()
    guard let data = Data(hex: cleaned) else { return nil }
    return CrockfordBase32.encode(data)
}

func decodeMAC(_ encoded: String) -> String? {
    guard let data = CrockfordBase32.decode(encoded) else { return nil }
    let hex = data.hexEncodedString()
    return hex.chunked(by: 2).joined(separator: ":")
}


//                            HStack{
//                                Button(action: {
//                                    device.notitificationEnabled = !(device.notitificationEnabled ?? false)
//                                    updateAction("notitificationEnabled", (device.notitificationEnabled ?? false))
//                                }) {
//                                    if device.notitificationEnabled ?? false {
//                                        Image(systemName: "bell.fill")
//                                            .foregroundStyle(.green)
//                                            .imageScale(.medium)
//                                            .padding(10)
//                                            .background(Circle().fill(.green.opacity(0.1)))
//                                            .overlay(
//                                                Circle().stroke(Color.green, lineWidth: 1.5)
//                                            )
//                                    } else {
//                                        Image(systemName: "bell.slash")
//                                            .foregroundStyle(.gray)
//                                            .imageScale(.medium)
//                                            .padding(10)
//                                            .background(Circle().fill(.gray).opacity(0.1))
//                                            .overlay(
//                                                Circle().stroke(Color.gray, lineWidth: 1.5)
//                                            )
//                                    }
//                                }
//                            }
