import SwiftUI
import RealityKit
import GoogleGenerativeAI

struct ProblemBreakDown: View {
    let problemDescription: String // Input problem description
    @State private var problemType: String = ""
    @State private var detectedVariables: [(variable: String, value: String)] = []
    @State private var detectedTarget: String = ""
    @State private var fall = false
    @State private var animateCar = false // State for animation
    @State private var carPosition: CGFloat = -200  // Initial position (off-screen)
    @State private var accelerationFactor: CGFloat = 0
    @State private var carMoving = false
    @State private var startAnimation = false
    @State var answer: Double = 0.0
    @State var isLoading = false
    let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)
    @State var response = ""
    @State var modelSolution: String = ""
        @State private var timeElapsed: Double = 0.0 // Keeps track of time for the projectile motion
        
        // Physics constants
        let initialVelocity: Double = 100.0 // Initial velocity (m/s)
        let angle: Double = 45.0 // Launch angle in degrees
        let gravity: Double = 9.8 // Acceleration due to gravity (m/s^2)
    let scalingFactor: Double = 5.0
    
    let carWidth: CGFloat = 100
    let carHeight: CGFloat = 50
    
    var body: some View {
        VStack {
            // Problem Description
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Problem Description:")
                        .font(.headline)
                    Text(problemDescription)
                        .font(.body)
                        .padding(.bottom)
                    
                    Text("Problem Type:")
                        .font(.headline)
                    Text(problemType.isEmpty ? "Analyzing..." : problemType)
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(.bottom)
                    
                    Text("Detected Variables:")
                        .font(.headline)
                    if detectedVariables.isEmpty {
                        Text("No variables detected yet.")
                            .font(.body)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(detectedVariables, id: \.variable) { variableData in
                            Text("- \(variableData.variable): \(variableData.value)")
                                .font(.body)
                        }
                    }
                    Text("Target:")
                        .font(.headline)
                    if detectedTarget.isEmpty {
                        Text("No target detected yet.")
                            .font(.body)
                            .foregroundColor(.gray)
                    }else {
                        Text(detectedTarget)
                    }
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .indigo))
                    }
                    let response = try await model.generateContent(problemDescription)
                    Text(response.text ?? "")
                }
                .padding()
            }
            
            // Animation Section
            if problemType == "Uniform Motion" {
                uniformMotionAnimation()
            }else if problemType == "Free Fall" {
                freeFallAnimation()
            }else if problemType == "Acceleration" {
                accelerationMovement()
            }else if problemType == "Projectile Motion" {
                projectileMotionAnimation()
            }
        }
        .onAppear {
            analyzeProblem()
        }
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
    /// Function to analyze the problem and extract variables
    func analyzeProblem() {
        // Keywords for problem types
        let freeFallKeywords = ["free fall", "gravity", "falling object", "g ="]
        let uniformMotionKeywords = ["speed", "constant velocity", "uniform motion"]
        let accelerationKeywords = ["acceleration"]
        let projectileMotionKeywords = ["angle", "projection", "projectile", "initial velocity", "trajectory", "height", "velocity"]
        
        // Detect the type of problem
        if freeFallKeywords.contains(where: { problemDescription.lowercased().contains($0) }) {
            problemType = "Free Fall"
        } else if uniformMotionKeywords.contains(where: { problemDescription.lowercased().contains($0) }) {
            problemType = "Uniform Motion"
        } else if accelerationKeywords.contains(where: { problemDescription.lowercased().contains($0) }) {
            problemType = "Acceleration"
        } else if projectileMotionKeywords.contains(where: { problemDescription.lowercased().contains($0) }) {
            problemType = "Projectile Motion"
        } else {
            problemType = "Unknown"
        }
        
        // Extract variables and their values
        detectedVariables = extractVariables(from: problemDescription)
        detectedTarget = detectTarget(from: problemDescription)
    }
    
    /// Function to extract variables and their values using regular expressions
    func extractVariables(from text: String) -> [(variable: String, value: String)] {
            var variables: [(String, String)] = []

            // Define patterns for each type of motion
            let patterns: [String: String] = [
                // Acceleration (non-uniform motion)
                "acceleration": #"\b(?:acceleration|a)\b.*?(\d+\.?\d*)\s?(m/s²)"#,
                "final velocity": #"\b(?:final velocity|v)\b.*?(\d+\.?\d*)\s?(m/s|km/h)"#,
                "initial velocity": #"\b(?:initial velocity|v₀)\b.*?(\d+\.?\d*)\s?(m/s|km/h)"#,
                "distance (acceleration)": #"\b(?:distance|d)\b.*?(\d+\.?\d*)\s?(m|km)"#,
                "time (acceleration)": #"\b(?:time|t)\b.*?(\d+\.?\d*)\s?(s|seconds?)"#,

                // Uniform Motion (constant velocity)
                "speed (uniform)": #"\b(?:speed|velocity)\b.*?(\d+\.?\d*)\s?(m/s|km/h)"#,
                "distance (uniform)": #"\b(?:distance|d)\b.*?(\d+\.?\d*)\s?(m|km)"#,
                "time (uniform)": #"\b(?:time|t)\b.*?(\d+\.?\d*)\s?(s|minutes?|hours?)"#,

                // Free Fall
                "free fall velocity": #"\b(?:velocity in free fall|v)\b.*?(\d+\.?\d*)\s?(m/s)"#,
                "acceleration due to gravity": #"\b(?:g|acceleration due to gravity)\b.*?(\d+\.?\d*)\s?(m/s²)"#,
                "time (free fall)": #"\b(?:time in free fall|t)\b.*?(\d+\.?\d*)\s?(s|seconds?)"#,
                "distance (free fall)": #"\b(?:distance in free fall|d)\b.*?(\d+\.?\d*)\s?(m)"#,

                // Projectile Motion
                "initial velocity (projectile)": #"\b(?:initial velocity|v₀)\b.*?(\d+\.?\d*)\s?(m/s|km/h)"#,
                "angle of projection": #"\b(?:angle of projection|θ)\b.*?(\d+\.?\d*)\s?(°|degrees?)"#,
                "time of flight": #"\b(?:time of flight|tₓ)\b.*?(\d+\.?\d*)\s?(s|seconds?)"#,
                "range (projectile)": #"\b(?:range|horizontal distance)\b.*?(\d+\.?\d*)\s?(m|km)"#,
                "maximum height": #"\b(?:maximum height|h)\b.*?(\d+\.?\d*)\s?(m)"#
            ]
            
            // Iterate through each pattern and extract variables
            for (variable, pattern) in patterns {
                let regex = try! NSRegularExpression(pattern: pattern, options: [])
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if match.numberOfRanges == 3 { // Expecting 2 capturing groups
                        let valueRange = Range(match.range(at: 1), in: text)!
                        let unitRange = Range(match.range(at: 2), in: text)!
                        
                        let value = String(text[valueRange]) + " " + String(text[unitRange])
                        variables.append((variable, value))
                    }
                }
            }
            
            return variables
        }
    func detectTarget(from text: String) -> String {
        // Define patterns to detect target variable
        let targetPatterns: [String: String] = [
            "acceleration": #"\b(?:find|calculate|determine).{0,20}?\b(?:acceleration|a)\b"#,
            "final velocity": #"\b(?:find|calculate|determine).{0,20}?\b(?:final velocity|v)\b"#,
            "initial velocity": #"\b(?:find|calculate|determine).{0,20}?\b(?:initial velocity|v₀)\b"#,
            "distance": #"\b(?:find|calculate|determine).{0,20}?\b(?:distance|d)\b"#,
            "time": #"\b(?:find|calculate|determine).{0,20}?\b(?:time|t)\b"#,
            "free fall velocity": #"\b(?:find|calculate|determine).{0,20}?\b(?:velocity in free fall|v)\b"#,
            "angle of projection": #"\b(?:find|calculate|determine).{0,20}?\b(?:angle of projection|θ)\b"#,
            "range": #"\b(?:find|calculate|determine).{0,20}?\b(?:range|horizontal distance)\b"#,
            "maximum height": #"\b(?:find|calculate|determine).{0,20}?\b(?:maximum height|h)\b"#
        ]
        
        // Iterate through patterns to find the target
        for (variable, pattern) in targetPatterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            if regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil {
                return variable
            }
        }
        
        return "No target found yet" // No target detected
    }



    
    
    /// Animation for Uniform Motion (Moving Car)
    @ViewBuilder
    func uniformMotionAnimation() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.gray)
                .frame(height: 50)
                .offset(y: 100)
            
            HStack {
                Image(systemName: "car.fill")
                    .resizable()
                    .frame(width: 80, height: 40)
                    .foregroundColor(.blue)
                    .offset(x: animateCar ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width)
                    .animation(
                        Animation.linear(duration: 5).repeatForever(autoreverses: false),
                        value: animateCar
                    )
            }
            
            // Display variables above the car
            VStack {
                if let speed = detectedVariables.first(where: { $0.variable == "speed" })?.value {
                    Text("Speed: \(speed)")
                        .font(.caption)
                        .foregroundColor(.black)
                }
                if let time = detectedVariables.first(where: { $0.variable == "time" })?.value {
                    Text("Time: \(time)")
                        .font(.caption)
                        .foregroundColor(.black)
                }
                if let distance = detectedVariables.first(where: { $0.variable == "distance" })?.value {
                    Text("Distance: \(distance)")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
            .offset(y: -40) // Position the labels above the car
        }
        .onAppear {
            animateCar = true
        }
    }
    func freeFallAnimation() -> some View {
        VStack {
            Spacer()
            
            // The object to fall (circle in this case)
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .offset(y: fall ? 400 : 0) // Control the Y-offset to simulate falling
                .animation(.easeIn(duration: 2), value: fall)
            
            Spacer()
            
            // Button to trigger the fall animation
            Button("Start Fall") {
                fall.toggle()
            }
            .padding()
        }
        .padding()
    }
    func accelerationMovement() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.gray)
                .frame(height: 50)
                .offset(y: 100)
            
            HStack {
                Image(systemName: "car.fill")
                    .frame(width: carWidth, height: carHeight)
                    .foregroundColor(.blue)
                    .offset(x: carPosition)
                    .animation(.interpolatingSpring(stiffness: 50, damping: 5).speed(2), value: carPosition)
                Button("Start Accelerating Car") {
                    carMoving.toggle()
                    startAcceleratingCar()
                }
            }
        }
    }
    func startAcceleratingCar() {
        // Use a timer to simulate the car's acceleration
        withAnimation(.linear(duration: 5)) {
            carPosition += 1000 // Move the car across the screen
        }
        
        // Gradually increase the acceleration
        let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
        var counter = 0
        
        timer.receive(on: DispatchQueue.main).sink { _ in
            if carMoving && counter < 500 {
                // Accelerate the car by adjusting its speed incrementally
                accelerationFactor += 5
                carPosition += accelerationFactor
                counter += 1
            }
        }
    }
    func projectileMotionAnimation() -> some View {
        VStack {
                    Spacer()
                    
                    // The projectile (circle representing the body)
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                        .offset(x: xOffset, y: -yOffset) // Position of the projectile
                        .animation(startAnimation ? .linear(duration: 5) : .default, value: timeElapsed)
                    
                    Spacer()
                    
                    // Button to start the animation
                    Button("Launch Projectile") {
                        startAnimation.toggle()
                        startProjectileMotion()
                    }
                    .padding()
                }
    }
    var xOffset: CGFloat {
            let time = timeElapsed
            let x = initialVelocity * cos(angleInRadians) * time // Horizontal displacement formula
            return CGFloat(x * scalingFactor)
        }
        
        // Y position (vertical displacement)
        var yOffset: CGFloat {
            let time = timeElapsed
            let y = (initialVelocity * sin(angleInRadians) * time) - (0.5 * gravity * time * time) // Vertical displacement formula
            return CGFloat(y * scalingFactor)
        }
        
        // Convert angle to radians
        var angleInRadians: Double {
            angle * .pi / 180
        }
        
        // Simulate projectile motion by updating time
        func startProjectileMotion() {
            timeElapsed = 0 // Reset time
            
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                if timeElapsed > 2 * timeOfFlight {
                    timer.invalidate() // Stop timer after projectile lands
                } else {
                    timeElapsed += 0.05
                }
            }
        }
        
        // Time of flight (total time until the projectile hits the ground)
        var timeOfFlight: Double {
            (2 * initialVelocity * sin(angleInRadians)) / gravity
        }
    func parseValue(_ input: String) -> Double? {
        let regex = try! NSRegularExpression(pattern: #"\d+\.?\d*"#, options: [])
        if let match = regex.firstMatch(in: input, options: [], range: NSRange(input.startIndex..., in: input)) {
            let valueRange = Range(match.range, in: input)!
            return Double(input[valueRange])
        }
        return nil
    }

    func solveProblem(variables: [(variable: String, value: String)], target: String, problemType: String) -> Double? {
        // Parse variables into a dictionary for easy access
        var variableValues: [String: Double] = [:]
        for (key, value) in variables {
            if let parsedValue = parseValue(value) {
                variableValues[key] = parsedValue
            }
        }
        
        // Constants
        let g = 9.8 // Acceleration due to gravity (m/s²)
        
        // Solve based on problem type and target
        switch problemType {
        case "acceleration":
            switch target {
            case "acceleration":
                if let v = variableValues["final velocity"],
                   let v0 = variableValues["initial velocity"],
                   let t = variableValues["time"] {
                    return (v - v0) / t
                }
            case "distance":
                if let v0 = variableValues["initial velocity"],
                   let a = variableValues["acceleration"],
                   let t = variableValues["time"] {
                    return v0 * t + 0.5 * a * t * t
                }
            case "final velocity":
                if let v0 = variableValues["initial velocity"],
                   let a = variableValues["acceleration"],
                   let t = variableValues["time"] {
                    return v0 + a * t
                }
            default:
                return nil
            }
            
        case "uniform motion":
            if target == "distance",
               let v = variableValues["speed (uniform)"],
               let t = variableValues["time"] {
                return v * t
            }
            
        case "free fall":
            switch target {
            case "free fall velocity":
                if let t = variableValues["time (free fall)"] {
                    return g * t
                }
            case "distance":
                if let t = variableValues["time (free fall)"] {
                    return 0.5 * g * t * t
                }
            case "time":
                if let h = variableValues["distance (free fall)"] {
                    return sqrt(2 * h / g)
                }
            default:
                return nil
            }
            
        case "projectile motion":
            switch target {
            case "time of flight":
                if let v0 = variableValues["initial velocity (projectile)"],
                   let angle = variableValues["angle of projection"] {
                    return 2 * v0 * sin(angle * .pi / 180) / g
                }
            case "range":
                if let v0 = variableValues["initial velocity (projectile)"],
                   let angle = variableValues["angle of projection"] {
                    return pow(v0, 2) * sin(2 * angle * .pi / 180) / g
                }
            case "maximum height":
                if let v0 = variableValues["initial velocity (projectile)"],
                   let angle = variableValues["angle of projection"] {
                    return pow(v0 * sin(angle * .pi / 180), 2) / (2 * g)
                }
            default:
                return nil
            }
            
        default:
            return nil
        }
        
        return nil // Return nil if no solution was found
    }


    }


