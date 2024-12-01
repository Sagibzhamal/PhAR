//
//  ContentView.swift
//  PhAR
//
//  Created by Sagibzhamal on 29.11.2024.
//

import SwiftUI
import GoogleGenerativeAI
import ARKit
import SceneKit


struct ContentView: View {
    @State private var showScannerSheet = false
    @State private var texts:[ScanData] = []
    @AppStorage("shouldShowOnBoarding") var shouldShowOnboarding: Bool = true
    let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)
    @State var isLoading = false
    @State var response = ""
    
    var body: some View {
        NavigationView{
            VStack {
                if texts.count > 0{
                    List{
                        ForEach(texts){text in                            NavigationLink(destination: ProblemBreakDown(problemDescription: text.content), label: {
                                Text(text.content).lineLimit(1)
                            })
                        }
                    }
                }else{
                    Text("No scan yet").font(.title)
                }
            }
            .navigationTitle("Home")
            .navigationBarItems(trailing: Button(action: {self.showScannerSheet = true}, label: {
                Image(systemName: "doc.text.viewfinder")
                    .font(.title)
            }))
            .sheet(isPresented: $showScannerSheet, content: {
                makeScannerView()            })
        }
        .fullScreenCover(isPresented: $shouldShowOnboarding, content: {
            OnboardingView(shouldShowOnBoarding: $shouldShowOnboarding)
        })
    }
    private func makeScannerView()-> ScannerView {
        ScannerView(completion: {
            textPerPage in
            if let outputText = textPerPage?.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines){
                let newScanData = ScanData(content: outputText)
                self.texts.append(newScanData)
            }
            self.showScannerSheet = false
        })
    }
    func generateResponse(userPrompt: String){
        isLoading = true
        response = ""
        
        Task {
            do{
                let result = try await model.generateContent(userPrompt)
                isLoading = false
                response = result.text ?? "No response found"
            } catch {
                response = "Something went wrong\n\(error.localizedDescription)"
            }
        }
    }
}


// Onboarding

struct OnboardingView: View {
    @Binding var shouldShowOnBoarding: Bool
    var body: some View {
        TabView {
            PageView(title: "Learn Physics",
                     subtitle: "Learn complex physics concepts simply",
                     imageName: "atom",
                     showDismissButton: false,
                     shouldShowOnBoarding: $shouldShowOnBoarding)
            
            PageView(title: "Scan Problems",
                     subtitle: "Scan the problem and see the solution!",
                     imageName: "camera.viewfinder",
                     showDismissButton: false,
                     shouldShowOnBoarding: $shouldShowOnBoarding)
            PageView(title: "Easy explanation",
                     subtitle: "See an easy explanation",
                     imageName: "square.and.pencil",
                     showDismissButton: false,
                     shouldShowOnBoarding: $shouldShowOnBoarding)
            PageView(title: "Let's get started!",
                     subtitle: "Let's solve everything within a minute!",
                     imageName: "cloud.rainbow.half",
                     showDismissButton: true,
                     shouldShowOnBoarding: $shouldShowOnBoarding)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}


struct PageView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let showDismissButton: Bool
    @Binding var shouldShowOnBoarding: Bool
    var body: some View {
        VStack{
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .padding()
            
            Text(title)
                .font(.system(size: 32))
                .padding()
            
            Text(subtitle)
                .font(.system(size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.secondaryLabel))
                .padding()
            
            if showDismissButton {
                Button(action: {
                    shouldShowOnBoarding.toggle()
                }, label: {
                    Text("Get Started")
                        .bold()
                        .foregroundColor(Color.white)
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .cornerRadius(6)
                })
            }
        }
    }
}
#Preview {
    ContentView()
}
