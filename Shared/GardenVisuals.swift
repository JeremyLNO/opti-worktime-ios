import SwiftUI

/// Outils de dessin partagés (feuille en goutte).
enum GardenDraw {
    static func leafPath(base: CGPoint, angle: Double, length: CGFloat) -> Path {
        var p = Path()
        let dx = CGFloat(cos(angle)) * length
        let dy = CGFloat(sin(angle)) * length
        let tip = CGPoint(x: base.x + dx, y: base.y + dy)
        let mid = CGPoint(x: (base.x + tip.x) / 2, y: (base.y + tip.y) / 2)
        let nx = CGFloat(cos(angle + .pi / 2))
        let ny = CGFloat(sin(angle + .pi / 2))
        let off = length * 0.36
        p.move(to: base)
        p.addQuadCurve(to: tip, control: CGPoint(x: mid.x + nx * off, y: mid.y + ny * off))
        p.addQuadCurve(to: base, control: CGPoint(x: mid.x - nx * off, y: mid.y - ny * off))
        p.closeSubpath()
        return p
    }
}

// MARK: - Tomate

struct TomatoView: View {
    var size: CGFloat = 26
    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let cx = w * 0.5
            let red = Color(red: 0.94, green: 0.28, blue: 0.22)
            let redDark = Color(red: 0.80, green: 0.20, blue: 0.16)
            let green = Color(red: 0.28, green: 0.68, blue: 0.34)
            let face = Color(red: 0.24, green: 0.09, blue: 0.07)

            ctx.fill(Path(ellipseIn: CGRect(x: w*0.08, y: h*0.34, width: w*0.84, height: h*0.62)), with: .color(red))
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.30, y: h*0.74, width: w*0.40, height: h*0.20)), with: .color(redDark.opacity(0.5)))
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.24, y: h*0.44, width: w*0.18, height: h*0.13)), with: .color(.white.opacity(0.30)))

            let base = CGPoint(x: cx, y: h*0.42)
            for deg in [-150.0, -114, -90, -66, -30] {
                ctx.fill(GardenDraw.leafPath(base: base, angle: deg * .pi / 180, length: w*0.24), with: .color(green))
            }
            ctx.fill(Path(roundedRect: CGRect(x: cx-1.3, y: h*0.16, width: 2.6, height: h*0.12), cornerRadius: 1.3), with: .color(green))

            let er = w*0.055
            ctx.fill(Path(ellipseIn: CGRect(x: cx - w*0.15 - er, y: h*0.60, width: er*2, height: er*2)), with: .color(face))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + w*0.15 - er, y: h*0.60, width: er*2, height: er*2)), with: .color(face))
            var smile = Path()
            smile.move(to: CGPoint(x: cx - w*0.10, y: h*0.74))
            smile.addQuadCurve(to: CGPoint(x: cx + w*0.10, y: h*0.74), control: CGPoint(x: cx, y: h*0.83))
            ctx.stroke(smile, with: .color(face), style: StrokeStyle(lineWidth: max(1, w*0.03), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Plante qui pousse

struct PlantView: View {
    var growth: Double
    var species: PlantSpecies
    var swaying: Bool = true
    var wilting: Bool = false
    @State private var sway = false

    var body: some View {
        PlantCanvas(growth: wilting ? max(growth, 0.3) : growth, species: species, wilting: wilting)
            .rotationEffect(.degrees(wilting ? 24 : (sway ? 2.5 : -2.5)), anchor: .bottom)
            .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: sway)
            .animation(.easeIn(duration: 0.7), value: wilting)
            .onAppear { if swaying { sway = true } }
    }
}

struct PlantCanvas: View {
    var growth: Double
    var species: PlantSpecies
    var wilting: Bool

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let cx = w * 0.5
            let baseY = h * 0.92
            let maxStem = h * 0.72
            let g = max(0, min(1, growth))
            let stemTopY = baseY - CGFloat(g) * maxStem

            var soil = Path()
            soil.move(to: CGPoint(x: cx - w*0.27, y: baseY))
            soil.addQuadCurve(to: CGPoint(x: cx + w*0.27, y: baseY), control: CGPoint(x: cx, y: baseY - h*0.08))
            soil.addLine(to: CGPoint(x: cx + w*0.27, y: baseY + h*0.06))
            soil.addLine(to: CGPoint(x: cx - w*0.27, y: baseY + h*0.06))
            soil.closeSubpath()
            ctx.fill(soil, with: .color(Palette.soil.opacity(0.92)))

            guard g > 0.03 else {
                ctx.fill(Path(ellipseIn: CGRect(x: cx - 3, y: baseY - 7, width: 6, height: 8)), with: .color(Palette.soil))
                return
            }

            let foliage = wilting ? Color(red: 0.56, green: 0.50, blue: 0.22) : Color(red: 0.30, green: 0.66, blue: 0.34)
            var stem = Path()
            stem.move(to: CGPoint(x: cx, y: baseY))
            stem.addQuadCurve(to: CGPoint(x: cx, y: stemTopY), control: CGPoint(x: cx + w*0.05, y: (baseY + stemTopY) / 2))
            ctx.stroke(stem, with: .color(foliage), style: StrokeStyle(lineWidth: max(2, w*0.045), lineCap: .round))

            if g > 0.28 {
                let by = baseY - CGFloat(min(g, 0.5)) * maxStem * 0.7
                ctx.fill(GardenDraw.leafPath(base: CGPoint(x: cx, y: by), angle: .pi*1.2, length: w*0.26*CGFloat(min(1, g*1.4))), with: .color(foliage))
            }
            if g > 0.46 {
                let by = baseY - CGFloat(min(g, 0.7)) * maxStem * 0.5
                ctx.fill(GardenDraw.leafPath(base: CGPoint(x: cx, y: by), angle: -.pi*0.18, length: w*0.28*CGFloat(min(1, g))), with: .color(foliage))
            }

            if g > 0.6 {
                let s = (g - 0.6) / 0.4
                let r = w * 0.13 * CGFloat(min(1, s + 0.25))
                let center = CGPoint(x: cx, y: stemTopY)
                let bloom = species.bloomColor.opacity(wilting ? 0.5 : 1)
                if species.petals == 0 {
                    ctx.fill(Path(ellipseIn: CGRect(x: center.x - r*0.7, y: center.y - r, width: r*1.4, height: r*1.7)), with: .color(bloom))
                } else {
                    for i in 0..<species.petals {
                        let a = Double(i) / Double(species.petals) * 2 * .pi
                        let pc = CGPoint(x: center.x + CGFloat(cos(a))*r*0.7, y: center.y + CGFloat(sin(a))*r*0.7)
                        ctx.fill(Path(ellipseIn: CGRect(x: pc.x - r*0.42, y: pc.y - r*0.42, width: r*0.84, height: r*0.84)), with: .color(bloom))
                    }
                    ctx.fill(Path(ellipseIn: CGRect(x: center.x - r*0.4, y: center.y - r*0.4, width: r*0.8, height: r*0.8)), with: .color(Color(red: 0.99, green: 0.85, blue: 0.40)))
                }
            }
        }
    }
}

// MARK: - Barre de progression à tomate rebondissante

struct TomatoProgressBar: View {
    var progress: Double
    var color: Color
    @State private var bounce = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let p = max(0, min(1, progress))
            let x = p * w
            let barY = geo.size.height - 9
            let tomatoX = min(max(15, x), w - 15)
            ZStack(alignment: .topLeading) {
                Capsule().fill(Color.white.opacity(0.16)).frame(width: w, height: 9).position(x: w/2, y: barY)
                Capsule().fill(color).frame(width: max(2, x), height: 9).position(x: x/2, y: barY)
                    .shadow(color: color.opacity(0.5), radius: 4).animation(.linear(duration: 0.25), value: p)
                TomatoView(size: 30).offset(y: bounce ? -8 : 0).position(x: tomatoX, y: barY - 18)
                    .animation(.linear(duration: 0.25), value: tomatoX)
            }
        }
        .frame(height: 46)
        .onAppear { withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { bounce = true } }
    }
}
