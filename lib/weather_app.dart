import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const AgenticWeatherApp());
}

// ==========================================
// 1. APPLICATION ENTRY POINT & THEME
// ==========================================
class AgenticWeatherApp extends StatelessWidget {
  const AgenticWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agentic Weather AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1117), // Premium dark theme background
      ),
      home: const WeatherDashboard(),
    );
  }
}

// ==========================================
// 2. WEATHER API SERVICE
// ==========================================
class WeatherService {
  final String apiKey = '2fc5c1c28400167fbde535a434dd0402';

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}

// ==========================================
// 3. MAIN DASHBOARD SCREEN (With FAB Trigger)
// ==========================================
class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  final _cityController = TextEditingController();
  final _weatherService = WeatherService();

  // API Key for Gemini SDK integration
  final String _geminiKey = "AIzaSyBfLWp8Vt73iMj773HD2unhvB0NPdNZyq8";

  String cityName = "";
  String temperature = "";
  String condition = "";
  double rawTemp = 0.0;
  bool isLoading = false;

  void getWeatherData() async {
    if (_cityController.text.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final weatherData = await _weatherService.fetchWeather(_cityController.text);

      setState(() {
        cityName = weatherData['name'];
        rawTemp = weatherData['main']['temp'].toDouble();
        temperature = "${rawTemp.toStringAsFixed(1)}°C";
        condition = weatherData['weather'][0]['description'].toUpperCase();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        cityName = "Error";
        temperature = "--";
        condition = "City data not found.";
      });
    }
  }

  // Opens the stateful, context-aware bottom sheet panel
  void _openWeatherChat() {
    if (cityName.isEmpty || cityName == "Error") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please search for a valid city first!")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22), // Matching the dashboard surface color
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => WeatherChatWidget(
          apiKey: _geminiKey,
          city: cityName,
          temp: temperature,
          condition: condition.toLowerCase()
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agentic Weather AI'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Floating Action Button only appears when weather metrics exist
      floatingActionButton: cityName.isNotEmpty && cityName != "Error"
          ? FloatingActionButton.extended(
        onPressed: _openWeatherChat,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text("Ask AI Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Field
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Search city (e.g., Lahore, London)...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.blueAccent),
                  onPressed: getWeatherData,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
              onSubmitted: (_) => getWeatherData(),
            ),
            const SizedBox(height: 40),

            // Loading Animation State
            if (isLoading)
              const Center(
                child: SpinKitThreeBounce(
                  color: Colors.blueAccent,
                  size: 40.0,
                ),
              )
            else if (cityName.isNotEmpty) ...[

              // Live Weather Metric View Card
              Card(
                elevation: 0,
                color: Colors.white.withOpacity(0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                          cityName,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                      ),
                      const SizedBox(height: 12),
                      Text(
                          temperature,
                          style: const TextStyle(fontSize: 76, fontWeight: FontWeight.w100, color: Colors.blueAccent)
                      ),
                      const SizedBox(height: 8),
                      Text(
                          condition,
                          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 2)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. CONTEXT-AWARE WEATHER CHAT WIDGET
// ==========================================
class WeatherChatWidget extends StatefulWidget {
  final String apiKey;
  final String city;
  final String temp;
  final String condition;

  const WeatherChatWidget({
    super.key,
    required this.apiKey,
    required this.city,
    required this.temp,
    required this.condition
  });

  @override
  State<WeatherChatWidget> createState() => _WeatherChatWidgetState();
}

class _WeatherChatWidgetState extends State<WeatherChatWidget> {
  late GenerativeModel model;
  final TextEditingController _chatController = TextEditingController();
  List<Map<String, String>> messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Native SDK initialization using stable gemini-2.5-flash
    model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: widget.apiKey);

    // Inject introductory greeting based completely on dynamic weather state
    messages.add({
      "role": "AI",
      "text": "Hello! I see it is currently ${widget.temp} with '${widget.condition}' in ${widget.city}. How can I help you prepare for your day out, plan local activities, or decide what to wear?"
    });
  }

  Future<void> _sendMessage() async {
    final userText = _chatController.text;
    if (userText.isEmpty) return;

    setState(() {
      messages.add({"role": "You", "text": userText});
      _chatController.clear();
      _isTyping = true;
    });

    try {
      // System instructions prepended directly into request data pipeline
      final contextPrompt = "System Context: The user is asking about the weather/lifestyle adjustments in ${widget.city}, where it is currently ${widget.temp} with '${widget.condition}'. Act as an expert, friendly AI travel and clothing assistant. User Query: $userText";
      final content = [Content.text(contextPrompt)];
      final response = await model.generateContent(content);

      setState(() {
        messages.add({"role": "AI", "text": response.text ?? "I couldn't generate a response."});
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        messages.add({"role": "AI", "text": "Error: $e"});
        _isTyping = false;
      });
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text("${widget.city} AI Consultant", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ],
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, i) {
                bool isUser = messages[i]['role'] == "You";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    // Constrained sizing ensures text wrap bounds safely over Chrome viewports
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      messages[i]['text']!,
                      // FIXED ERROR: Replaced invalid .white90 property with correct runtime opacity mapping
                      style: TextStyle(color: isUser ? Colors.white : Colors.white.withOpacity(0.9), fontSize: 14.5, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("AI is calculating options...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12))
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask about wardrobe or plans in ${widget.city}...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.blueAccent, width: 1)),
                suffixIcon: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.blueAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}