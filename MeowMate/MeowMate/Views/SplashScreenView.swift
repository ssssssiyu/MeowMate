import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        if isActive {
            HomeView()
        } else {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack {
                    VStack(spacing: 10) {
                        Image("SplashIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .offset(y: yOffset)
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    yOffset = -20
                                }
                            }
                        
                        Text("MeowMate")
                            .font(.custom("Chalkboard SE", size: 40))
                            .foregroundColor(Color(red: 64/255, green: 198/255, blue: 194/255))
                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2)) {
                            self.size = 0.9
                            self.opacity = 1.0
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
} 
